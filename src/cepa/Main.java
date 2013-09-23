package cepa;

import cepa.edu.util.Cronometer;
import cepa.edu.util.DynamicAverage;
import cepa.edu.util.LanguageObservable;
import cepa.edu.util.LogoPanel;
import cepa.edu.util.Util;
import cepa.edu.util.svg.SVGViewBox;
import java.awt.BorderLayout;

import java.awt.Dimension;
import java.awt.Point;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Locale;
import java.util.Observable;
import java.util.Observer;
import java.util.Properties;
import java.util.ResourceBundle;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.swing.ButtonGroup;
import javax.swing.JMenu;
import javax.swing.JPanel;
import javax.swing.JRadioButtonMenuItem;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import org.apache.batik.dom.svg.SAXSVGDocumentFactory;
import org.apache.batik.swing.JSVGCanvas;
import org.apache.batik.swing.svg.SVGLoadEventDispatcherAdapter;
import org.apache.batik.swing.svg.SVGLoadEventDispatcherEvent;
import org.apache.batik.util.XMLResourceDescriptor;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.events.Event;
import org.w3c.dom.events.EventListener;
import org.w3c.dom.events.EventTarget;
import org.w3c.dom.svg.SVGDocument;
import org.w3c.dom.svg.SVGElement;
import org.apache.batik.script.Window;

/**
 *
 * @author irpagnossin
 */
public class Main extends javax.swing.JFrame implements Observer {

    // Atualiza os elementos sensíveis ao locale.
    @SuppressWarnings("static-access")
    public void update(Observable o, Object arg) {

        aboutMenu.setText(idiom.getString("about.menu.label")); // NOI18N
        aboutOption.setText(idiom.getString("about.option.label")); // NOI18N;
        instructionField.setText(idiom.getString("push.the.bike")); // NOI18N;
        answerField.setText(idiom.getString("answer.field.text")); // NOI18N;
        
        numberFormat = new DecimalFormat("###,##0.0").getInstance(idiom.getLocale()); // NOI18N
        numberFormat.setMaximumFractionDigits(1);
        numberFormat.setMinimumFractionDigits(0);

        canvas.getUpdateManager().getUpdateRunnableQueue().invokeLater(new Runnable(){

            public void run() {
                flagPosLabel[START].setTextContent(numberFormat.format((flagPos[START]-meanX)/4) + " m");
                flagPosLabel[FINISH].setTextContent(numberFormat.format((flagPos[FINISH]-meanX)/4) + " m");
            }
        });
    }

    // Construtor
    public Main() {

        InputStream stream = getClass().getClassLoader().getResourceAsStream("app.properties"); // NOI18N
        Properties properties = new Properties();
        try {
            properties.load(stream);
        } catch (IOException ex) {
            Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex); System.exit(-1);
        }

        numberFormat = new DecimalFormat("###,##0.0"); // NOI18N
        numberFormat.setMaximumFractionDigits(1);
        numberFormat.setMinimumFractionDigits(0);

        averageBikeSpeed = new DynamicAverage(N);

        setupGUI(properties);
        setupSVGScene(properties);
        loadSVGElements();
        registerListeners();
    }

    private void setupGUI (final Properties properties) {

        // Define look & feel
        try{
        	UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        	SwingUtilities.updateComponentTreeUI(this);
        }
        catch( Exception e ){/*Nada*/}

        // Configura os componentes criados automaticamente pelo Matisse.
        initComponents();

        menuBar.add(new JPanel());
        menuBar.add(languageMenu);

        // ------------------------------------------------
        // ----- Início da configuração do menu de idiomas.
        languageObservable = new LanguageObservable();
        languageObservable.addObserver(this);

        idiom = ResourceBundle.getBundle(properties.getProperty("language.bundle"), new Locale("en", "US")); // NOI18N

        languageMenu.setIcon(Util.getIcon(properties.getProperty("language.menu.icon"))); // NOI18N
        availableLocales = Util.getLocales(properties.getProperty("available.locales")); // NOI18N

        radioButton = new JRadioButtonMenuItem[availableLocales.length];
        ButtonGroup group = new ButtonGroup();

        for (int i = 0; i < availableLocales.length; i++) {
            final int index = i;

            radioButton[i] = new JRadioButtonMenuItem();
            radioButton[i].setText(availableLocales[i].getDisplayLanguage(availableLocales[i]) + " (" + availableLocales[i].getCountry() + ")"); // NOI18N
            radioButton[i].addActionListener(new ActionListener() {

                public void actionPerformed(ActionEvent e) {
                    idiom = ResourceBundle.getBundle("LanguageBundle", availableLocales[index]); // NOI18N
                    Main.this.setLocale(idiom.getLocale());
                    languageObservable.notifyObservers();
                }
            });

            // Se o item (Locale) for igual ao padrão, utiliza-o.
            if (availableLocales[i].equals(Locale.getDefault())) {
                idiom = ResourceBundle.getBundle(properties.getProperty("language.bundle"), availableLocales[i]); // NOI18N
                radioButton[i].setSelected(true);
            }

            group.add(radioButton[i]);
            languageMenu.add(radioButton[i]);
        }

        setGlassPane(new LogoPanel(properties.getProperty("logo.file"))); // NOI18N

    }

    private void setupSVGScene (final Properties properties) {

        /***********************************************************************
         Carrega o arquivo SVG para o JPanel.
         **********************************************************************/
		try {

		    String parser = XMLResourceDescriptor.getXMLParserClassName();
		    SAXSVGDocumentFactory factory = new SAXSVGDocumentFactory(parser);

            ClassLoader classLoader = this.getClass().getClassLoader();
            URL url = classLoader.getResource(properties.getProperty("scene.file")); // NOI18N
            String uri = url.toURI().toString();

		    document = (SVGDocument) factory.createDocument(uri);
		}

		catch (IOException ex) { Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex); System.exit(-1); }        catch (URISyntaxException ex) { Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex); System.exit(-1);}

        canvas = new JSVGCanvas();
		canvas.setDocumentState (JSVGCanvas.ALWAYS_DYNAMIC); // Torna dinâmico o canvas.
		canvas.setDocument (document); // Associa a cena SVG (propriedade scene.file) ao canvas.
		canvas.setEnableImageZoomInteractor(false);
		canvas.setEnablePanInteractor(false); // Desabilita a opção de arrastar a cena SVG.
		canvas.setEnableRotateInteractor(false); // Desabilita a opção de rotacionar a cena SVG.
		canvas.setEnableZoomInteractor(false); // Desabilita a opção de ampliar/reduzir a cena SVG.

        svgPanel.setLayout(new BorderLayout());
        svgPanel.add(canvas,BorderLayout.CENTER);
    }

    // Lê os elementos relevantes da cena SVG e obtém as propriedades importantes.
    private void loadSVGElements () {

        // Lê do arquivo SVG os elementos da cena
        root = (SVGElement) ((SVGDocument)document).getRootElement(); // O elemento raiz da cena SVG.
        bike = document.getElementById("bike"); // NOI18N
        bikeGroup = document.getElementById("bike.group"); // NOI18N
        background = document.getElementById("background"); // NOI18N
        flag[START] = document.getElementById("start.flag"); // NOI18N
        flag[FINISH] = document.getElementById("finish.flag"); // NOI18N
        flagPosLabel[START] = document.getElementById("start.position"); // NOI18N
        flagPosLabel[FINISH] = document.getElementById("finish.position"); // NOI18N
        glassLayer = document.getElementById("glass.layer"); // NOI18N

        // Lê do arquivo SVG as coordenadas e dimensões da view-box.
        viewbox = new SVGViewBox(root.getAttribute("viewBox")); // NOI18N

        meanX = (viewbox.getX() + viewbox.getWidth())/2;

        bikePos = getTranslateCoordinates(bikeGroup.getAttribute("transform"));

        bikeWidth = Double.parseDouble(document.getElementById("bike.def").getAttribute("width"));
        startFlagWidth = Double.parseDouble(document.getElementById("start.flag.def").getAttribute("width"));

        flagPos[START] = Double.parseDouble(flag[START].getAttribute("x"));
        flagPos[FINISH] = Double.parseDouble(flag[FINISH].getAttribute("x"));

        flagPosLabel[START].setTextContent(numberFormat.format((flagPos[START]-meanX)/4) + " m");
        flagPosLabel[FINISH].setTextContent(numberFormat.format((flagPos[FINISH]-meanX)/4) + " m");
    }

    // Registra os observadores (ou "ouvidores") de eventos.
    private void registerListeners () {

        mouseUpListener = new MouseUpListener();

        ((EventTarget) glassLayer).addEventListener("mouseup", mouseUpListener, false);

        // Observadores de eventos da bicicleta.
        // ---------------------------------------------------------------------
        ((EventTarget) bikeGroup).addEventListener("mousedown", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                bikeSelected = true;
                
                try {
                    dx = getMousePos(X) - bikePos[X];
                } catch (Exception ex) { dx = 0; }

                animationThread.stop();
                averageBikeSpeed.reset();
            }
        }, false);
        ((EventTarget) bikeGroup).addEventListener("mouseup", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                deselectAll();

                try {
                    animationThread.setStartingX(getMousePos(X)-dx);
                } catch (Exception ex) {/* Nada */}
                
                animationThread.setSpeed(averageBikeSpeed.getMean());
                animationThread.start();

                if (averageBikeSpeed.getMean() < 0) bike.setAttribute("transform", "scale(-1,1)");
                else bike.setAttribute("transform", "scale(1,1)");
            }
        }, false);
        ((EventTarget) bikeGroup).addEventListener("mousemove", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                onMouseMove();
            }
        }, false);

        // Observadores de eventos da bandeira de largada.
        // ---------------------------------------------------------------------
        ((EventTarget) flag[START]).addEventListener("mousedown", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                deselectAll();
                flagSelected[START] = true;

                try {
                    dx = getMousePos(X) - flagPos[START];
                } catch (Exception ex) {
                    deselectAll();
                }
            }
        }, false);
        ((EventTarget) flag[START]).addEventListener("mouseup", mouseUpListener, false);
        ((EventTarget) flag[START]).addEventListener("mousemove", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                onMouseMove();
            }
        }, false);

        // Observadores de eventos da bandeira de chegada.
        // ---------------------------------------------------------------------
        ((EventTarget) flag[FINISH]).addEventListener("mousedown", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                deselectAll();
                flagSelected[FINISH] = true;

                try {
                    dx = getMousePos(X) - flagPos[FINISH];
                } catch (Exception ex) {
                    deselectAll();
                }
            }
        }, false);
        ((EventTarget) flag[FINISH]).addEventListener("mouseup", mouseUpListener, false);
        ((EventTarget) flag[FINISH]).addEventListener("mousemove", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                onMouseMove();
            }
        }, false);

        // Observadores de eventos da camada transparente.
        // ---------------------------------------------------------------------
        ((EventTarget) glassLayer).addEventListener("mousemove", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                onMouseMove();
            }
        }, false);

        //((EventTarget) glassLayer).addEventListener("mouseout", mouseUpListener, false);

        // Registra a thread responsável pela animação.
        // ---------------------------------------------------------------------
		canvas.addSVGLoadEventDispatcherListener (
			new SVGLoadEventDispatcherAdapter () {
                @Override
		        public void svgLoadEventDispatchStarted (SVGLoadEventDispatcherEvent e) {
                    window = canvas.getUpdateManager().getScriptingEnvironment().createWindow ();
		       }
		    }
		);

        animationThread = new AnimationThread(bikeGroup);
        animationThread.setSpeed(4);
        animationThread.setLimits(viewbox.getX()-bikeWidth/2,viewbox.getX()+viewbox.getWidth()+bikeWidth/2);

        ((EventTarget) root).addEventListener("SVGLoad", new EventListener(){ // NOI18N

            public void handleEvent(Event evt) {
                window.setInterval(animationThread,dt);
            }
        }, false);

        animationThread.start();
    }

    // Atualiza a posição da bicicleta
    private void onMouseMove () {

        try {
            mousePos = getMousePos(X);
        } catch (Exception ex) {
            deselectAll();
            return;
        }

        if (bikeSelected) {
            bikePos[X] = mousePos - dx;
            // Atualiza a posição da bola durante o arraste do mouse.
            bikeGroup.setAttribute("transform", "translate(" + bikePos[X] + "," + bikePos[Y] + ")");
        }
        else if (flagSelected[START]) {

            flagPos[START] = Math.min(mousePos-dx,flagPos[FINISH]-startFlagWidth);

            flag[START].setAttribute("x", String.valueOf(flagPos[START]));
            flagPosLabel[START].setAttribute("x", String.valueOf(flagPos[START]));
            flagPosLabel[START].setTextContent(numberFormat.format((flagPos[START]-meanX)/4) + " m");

        }
        else if (flagSelected[FINISH]) {

            flagPos[FINISH] = Math.max(mousePos-dx,flagPos[START]+startFlagWidth);

            flag[FINISH].setAttribute("x", String.valueOf(flagPos[FINISH]));
            flagPosLabel[FINISH].setAttribute("x", String.valueOf(flagPos[FINISH]));
            flagPosLabel[FINISH].setTextContent(numberFormat.format((flagPos[FINISH]-meanX)/4) + " m");            
        }
    }

    // Desseleciona todos os elementos.
    private void deselectAll () {
        bikeSelected = false;
        flagSelected[START] = false;
        flagSelected[FINISH] = false;
    }

    private class MouseUpListener implements EventListener {

        public void handleEvent(Event evt) {
            deselectAll();
        }
    }


    // Mapeia a posição do mouse na tela para a cena SVG.
    private double getMousePos ( final short axis ) throws Exception {
        // A razão entre as dimensões do JPanel e do view-box, necessário para mapear a posição do mouse na tela para g cena SVG.
        double ratio = Math.min(canvas.getHeight()/viewbox.getHeight(),canvas.getWidth()/viewbox.getWidth());

        Point pt = canvas.getMousePosition();
        if (pt == null) throw new Exception("Mouse is outside canvas.");

        double ans = 0;
        if (axis == X) ans = viewbox.getX() + pt.getX()/ratio;
        else if (axis == Y) ans = viewbox.getY() + pt.getY()/ratio;

        return ans;
    }

    // Retorna as coordenadas SVG do elemento "translate" do atributo "transform" (passado como argumento).
    private double[] getTranslateCoordinates ( String transformation ) {

        String regex1 = "\\s*translate[(]\\s*\\d*\\s*,\\s*\\d*\\s*[)]\\s*"; // NOI18N
        String regex2 = "\\d*,\\d*"; // NOI18N

        Pattern pattern1 = Pattern.compile(regex1);
        Pattern pattern2 = Pattern.compile(regex2);
        Matcher matcher1 = pattern1.matcher(transformation);

        String[] translate = {"0","0"}; // NOI18N

        if (matcher1.find()) {
            Matcher matcher2 = pattern2.matcher(matcher1.group());

            if (matcher2.find()) {
                translate = Pattern.compile(",").split(matcher2.group()); // NOI18N
            }
        }

        return new double[]{Double.parseDouble(translate[0]),Double.parseDouble(translate[1])};
    }

    private class AnimationThread implements Runnable {

        private Cronometer cronometer;
        private Element element;
        private double startingX, speed;
        private double xMin = 0, x, xMax = 1, L = xMax - xMin;

        public AnimationThread (Element element) {
            this.element = element;
            cronometer = new Cronometer();
        }

        public void run() {

            if (cronometer.isRunning()) {

                x = startingX + speed * cronometer.read()/1000d;
                if (x < xMin) {
                    double r = Math.IEEEremainder(Math.abs(xMax-x),L);
                    x = xMax - r - (r > 0 ? 0 : L);
                } else if (x > xMax) {
                    double r = Math.IEEEremainder(Math.abs(xMin-x),L);
                    x = xMin + r + (r > 0 ? 0 : L);
                }

                bikePos[X] = x;

                element.setAttribute("transform", "translate(" + bikePos[X] + "," + bikePos[Y] + ")");
            }
            else if (bikeSelected) {
                // Calcula a velocidade média da bola com base na velocidade do mouse.
                averageBikeSpeed.put((bikePos[X]-lastBikePos)/(dt/1000d)*mouseSpeedToBikeSpeedFactor);
            }

            lastBikePos = bikePos[X];
        }

        public void start () {
            cronometer.start();
        }

        public void stop () {
            cronometer.stop();
        }

        public void pause () {
            cronometer.pause();
        }

        public void setSpeed (final double speed) {
            this.speed = speed;
        }

        public void setStartingX (final double x) {
            this.startingX = x;
        }

        public void setLimits (final double xMin, final double xMax) {
            if (xMax > xMin) {
                this.xMin = xMin;
                this.xMax = xMax;
            } else {
                this.xMin = xMax;
                this.xMax = xMin;
            }
            this.L = this.xMax - this.xMin;
        }

        public double getSpeed () {
            return speed;
        }


    }

    private JMenu languageMenu = new JMenu(); // Menu de idiomas
    private JRadioButtonMenuItem[] radioButton; // Opções do menu de idiomas
    private JSVGCanvas canvas; // O canvas SVG

    private Document document; // O documento SVG
    private Element bike,
                    bikeGroup, // O grupo de elementos da bicicleta (na cena SVG), composto pela própria bicicleta, pelo rótulo da coordenada e pelo cursor (bug).
                    coordinateLabel, // Rótulo da coordenada da bicicleta. Faz parte do grupo "bike", mas preciso de uma referência para poder modificar o conteúdo da tag.
                    background, // O fundo da cena, utilizado para melhorar a resposta aos eventos do mouse.
                    glassLayer; // A camada - transparente - sobre a qual estão a bicicleta e as bandeiras (usada para melhorar a resposta aos eventos do mouse).

    private final short X = 0, Y = 1; // Índices dos vetores ulc e viewBoxSize; apenas para torná-los mais inteligíveis.


    private double meanX = 0, // Ponto médio (em x) da cena SVG
                   currentX = 0; // Coordenada atual da bicicleta
    private boolean bikeSelected = false; // Indica se o grupo de bicicleta está selecionado ou não.

    private LanguageObservable languageObservable; // Objeto observável que representa a língua utilizada na interface gráfica
    private ResourceBundle idiom; // ResourceBundle que contém as configurações de língua
    private Locale[] availableLocales; // Locales para os quais existe tradução deste aplicativo
    private NumberFormat numberFormat; // Formato de exibição do rótulo da coordenada da bicicleta

    private boolean[] flagSelected = new boolean[2];
    private double[] flagPos = new double[2];
    private double startFlagWidth;
    private double[] bikePos;
    private double bikeWidth;

    private SVGViewBox viewbox;

    private Window window;
    private SVGElement root;

    private AnimationThread animationThread; // A thread responsável por animar a bicicleta.
    private final long dt = 30; // Intervalo entre quadros (frames), em mili-segundos.


    private final short START = 0, FINISH = 1;
    private Element[] flag = new Element[2], flagPosLabel = new Element[2];

    private double mousePos, dx;

    private DynamicAverage averageBikeSpeed;
    private double lastBikePos;
    private double mouseSpeedToBikeSpeedFactor = 0.4;

    private final int N = 5; // Quantidade de quadros (frames) utilizados para calcular a velocidade média de arraste da bola.
    private double yPos = 0; // Posição y da bicicleta e das bandeiras (invariável)

    private MouseUpListener mouseUpListener;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
    @SuppressWarnings("unchecked") // NOI18N
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        svgPanel = new javax.swing.JPanel();
        instructionField = new javax.swing.JTextField();
        answerField = new javax.swing.JTextField();
        checkButton = new javax.swing.JButton();
        menuBar = new javax.swing.JMenuBar();
        aboutMenu = new javax.swing.JMenu();
        aboutOption = new javax.swing.JMenuItem();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        java.util.ResourceBundle bundle = java.util.ResourceBundle.getBundle("LanguageBundle_pt_BR"); // NOI18N
        setTitle(bundle.getString("frame.title")); // NOI18N
        setName(""); // NOI18N
        setResizable(false);

        svgPanel.setBackground(new java.awt.Color(255, 255, 255));
        svgPanel.setBorder(javax.swing.BorderFactory.createEtchedBorder());
        svgPanel.setPreferredSize(new java.awt.Dimension(700, 200));

        javax.swing.GroupLayout svgPanelLayout = new javax.swing.GroupLayout(svgPanel);
        svgPanel.setLayout(svgPanelLayout);
        svgPanelLayout.setHorizontalGroup(
            svgPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 696, Short.MAX_VALUE)
        );
        svgPanelLayout.setVerticalGroup(
            svgPanelLayout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGap(0, 196, Short.MAX_VALUE)
        );

        instructionField.setEditable(false);
        instructionField.setText(bundle.getString("push.the.bike")); // NOI18N
        instructionField.setBorder(new javax.swing.border.SoftBevelBorder(javax.swing.border.BevelBorder.LOWERED));
        instructionField.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                instructionFieldActionPerformed(evt);
            }
        });

        answerField.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        answerField.setText(bundle.getString("answer.field.text")); // NOI18N
        answerField.setPreferredSize(new java.awt.Dimension(60, 20));

        checkButton.setText(bundle.getString("check.button.label")); // NOI18N

        menuBar.setName("teste"); // NOI18N

        aboutMenu.setText(bundle.getString("about.menu.label")); // NOI18N

        aboutOption.setText(bundle.getString("about.option.label")); // NOI18N
        aboutOption.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                aboutOptionActionPerformed(evt);
            }
        });
        aboutMenu.add(aboutOption);

        menuBar.add(aboutMenu);

        setJMenuBar(menuBar);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(instructionField, javax.swing.GroupLayout.PREFERRED_SIZE, 523, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addGap(18, 18, 18)
                        .addComponent(answerField, javax.swing.GroupLayout.PREFERRED_SIZE, 103, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(checkButton, javax.swing.GroupLayout.PREFERRED_SIZE, 50, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addComponent(svgPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(svgPanel, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(instructionField, javax.swing.GroupLayout.PREFERRED_SIZE, 29, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(checkButton)
                    .addComponent(answerField, javax.swing.GroupLayout.PREFERRED_SIZE, 29, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addContainerGap(16, Short.MAX_VALUE))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    // Habilita/desabilita a exibição do logotipo do CEPA
    private void aboutOptionActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_aboutOptionActionPerformed
        this.getGlassPane().setVisible(true);
    }//GEN-LAST:event_aboutOptionActionPerformed

    private void instructionFieldActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_instructionFieldActionPerformed
        // TODO add your handling code here:
}//GEN-LAST:event_instructionFieldActionPerformed

    /**
    * @param args the command line arguments
    */
    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new Main().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JMenu aboutMenu;
    private javax.swing.JMenuItem aboutOption;
    private javax.swing.JTextField answerField;
    private javax.swing.JButton checkButton;
    private javax.swing.JTextField instructionField;
    private javax.swing.JMenuBar menuBar;
    private javax.swing.JPanel svgPanel;
    // End of variables declaration//GEN-END:variables
}
