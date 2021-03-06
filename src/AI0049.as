﻿package  
{
	import cepa.utils.Cronometer;
	import cepa.utils.ToolTip;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	import flash.display.SimpleButton;
	import cepa.utils.MouseMotionData;
	import flash.utils.clearInterval;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Luciano
	 */
	public class AI0049 extends MovieClip
	{
		private var CentToPix = 25;
		private var rulerSide;
		private var lastRuler;
		private var bigTickCm:Array = new Array();
		private var m,c,d,p,pe,razao1,razao2,unidades1,unidades2,arrow1XPos,arrow2XPos;
		private var casas1 = 1;
		private var seta1,seta2:MovieClip;
		private var dragging = null;
		private var justStarted:Boolean = true;
		private var seta1X:Number;
		private var mouseMotion:MouseMotionData; // Dados de movimento do mouse
		private var speed:Point = new Point(); // A velocidade do mouse
		private var intervalId;
		private var nMilliseconds:Number = 0;
		private var nSeconds:uint = 0;
		private var nStart:Number = 0;
		private var x0:Number = 0;
		private var v0:Number = 0;
		private var t:Number = 0;
		private var a:Number = 0;
		private var ms:Number = 0;
		private var lastX:Number = 275;
		private var timerStart:Number = 0;
		private var timeElapsed:Number = 0;
		private var timerPaused:Boolean = true;
		private var avisoA,avisoB:Boolean;
		private var dropX:Number;
		private var start, finish:Number;
		private var lastText:String;
		private var velocidade:Number;
		private var cronometer:Cronometer;
		
		// Margem de erro da resposta (em % para + e para -)
		private const MARGEM_ERRO:Number = 1/10;
		// Relação pixels/metros
		private const REL_PIX_METROS:int = 25;
		private var onTick:Boolean = true;
		
		public function AI0049() 
		{
			if (stage) init(null);
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			this.scrollRect = new Rectangle(0, 0, 700, 500);
			
			// Provê a velocidade do mouse
			mouseMotion = MouseMotionData.instance;
			
			bigTickCm[1] = new Array();
			
			seta1 = new Seta1();
			seta1.name = "seta1";
			addChild(seta1);
			
			seta2 = new Seta2();
			seta2.name = "seta2";
			addChild(seta2);
			
			rulerSide = 1;
			doTheTicks();
			
			TextField(resposta).restrict = "0123456789,.\\-";
			
			cronometer = new Cronometer();
			
			boxResultado.gotoAndStop(10);
			//aboutScreen.visible = false;
			instructionScreen.visible = false;
			//aboutScreen.addEventListener(MouseEvent.CLICK, function () { aboutScreen.openScreen() } );
			botoes.creditos.addEventListener(MouseEvent.CLICK, function () { aboutScreen.openScreen(); setChildIndex(aboutScreen, numChildren - 1); setChildIndex(bordaAtividade, numChildren - 1);} );
			instructionScreen.addEventListener(MouseEvent.CLICK, function () { instructionScreen.visible = false; } );
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, function () { instructionScreen.visible = true; setChildIndex(instructionScreen, numChildren - 1); setChildIndex(bordaAtividade, numChildren - 1); } );
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			
			cronometro.reset.buttonMode = true;
			cronometro.start.buttonMode = true;
			veiculo.buttonMode = true;
			seta1.buttonMode = true;
			seta2.buttonMode = true;
			
			cronometro.start.addEventListener(MouseEvent.CLICK, startCronometro);
			cronometro.reset.addEventListener(MouseEvent.CLICK, resetaCronometro);
			seta1.addEventListener(MouseEvent.MOUSE_DOWN, pickUp);
			seta2.addEventListener(MouseEvent.MOUSE_DOWN, pickUp);
			ruler.addEventListener(MouseEvent.MOUSE_UP, dropIt);
			stage.addEventListener(MouseEvent.MOUSE_UP, dropIt);
			veiculo.addEventListener(MouseEvent.MOUSE_DOWN, drag);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reseta);
			ok.addEventListener(MouseEvent.CLICK, mostraResultado);
			resposta.addEventListener(KeyboardEvent.KEY_DOWN, mostraResultado);
			
			
			//showArrow(null);
			
			setChildIndex(veiculo, numChildren - 1);
			
			createToolTips();
			createTutorial();
			iniciaTutorial();
			
			initLMSConnection();
		}
		
		private function createToolTips():void 
		{
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			
			addChild(infoTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(intTT);
		}
		
		private function reseta(e:MouseEvent):void {
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame2);
			resetaCronometro(null);
			iniciaTutorial();
			justStarted = true;
			showArrow(null);
			resposta.text = "";
			veiculo.x = 345;
			veiculo.y = 400;;
			veiculo.scaleX = 0.5;
			avisoA = avisoB = false;
			boxResultado.visible = false;
			timeElapsed = 0;
			cronometro.time.text = "0";
			timerPaused = true;
			
			seta1.addEventListener(MouseEvent.MOUSE_DOWN, pickUp);
			seta2.addEventListener(MouseEvent.MOUSE_DOWN, pickUp);
			ruler.addEventListener(MouseEvent.MOUSE_UP, dropIt);
			stage.addEventListener(MouseEvent.MOUSE_UP, dropIt);
			veiculo.addEventListener(MouseEvent.MOUSE_DOWN, drag);
			//veiculo.addEventListener(MouseEvent.MOUSE_UP, drop);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reseta);
		}
		
		private function startCronometro(e:MouseEvent):void {
			if (cronometer.isRunning()) {
				cronometer.pause();
				removeEventListener(Event.ENTER_FRAME, onEnterFrame3);
			} else {
				cronometer.start();
				addEventListener(Event.ENTER_FRAME, onEnterFrame3);
			}
		}
		
		private function resetaCronometro(e:MouseEvent):void {
			cronometro.time.text = "0";
			cronometer.stop();
			cronometer.reset();
			removeEventListener(Event.ENTER_FRAME, onEnterFrame3);
		}
		
		private function onEnterFrame3(e:Event):void {
			cronometro.time.text = (cronometer.read() / 1000).toFixed(1).replace(".",",");
		}
		
	private function drag(e:MouseEvent):void {
		//trace("drag", e.target.name);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame2);
		addEventListener(Event.ENTER_FRAME, keepHorizontal);
		dragging = e.target;
		veiculo.startDrag();
	}
	
	private function onEnterFrame2(e:Event):void {
		if (veiculo.x > 760) {
			veiculo.x = x0 = -60;
			nStart = getTimer();
		}
		else if (veiculo.x < -60) {
			veiculo.x = x0 = 760;
			nStart = getTimer();
		}
		
		nMilliseconds = getTimer() - nStart;
		t = (nMilliseconds / 1000);
		veiculo.x = x0 + v0 * t + ((a * (t * t)) / 2) * 500 / 20; // Espaço no M.R.U.V.
		//ms = (Math.abs(v0 + a * t * stage.stageWidth / STAGEWIDTH) / REL_PIX_METROS);
		
		if (veiculo.x < seta1.x && velocidade > 0) {
			dropX = 0;
			avisoA = false;
			avisoB = false;
		}
		if (veiculo.x > seta2.x && velocidade < 0) {
			dropX = 700;
			avisoA = false;
			avisoB = false;
		}
		
		/*if (velocidade > 0) {
			if (veiculo.x >= seta1.x && dropX < seta1.x &&!avisoA) {
				trace("Passou por A a " + ms.toFixed(1) + " m/s");
				avisoA = true;
				start = nMilliseconds;
			}
			if (veiculo.x >= seta2.x && dropX < seta1.x && !avisoB) {
				trace("Passou por B a " + ms.toFixed(1) + " m/s");
				avisoB = true;
				mostraResultado();
			}
		} else {
			if (veiculo.x <= seta2.x && dropX > seta2.x && !avisoB) {
				trace("Passou por B a " + ms.toFixed(1) + " m/s");
				avisoB = true;
				start = nMilliseconds;
			}
			if (veiculo.x <= seta1.x && dropX > seta2.x && !avisoA) {
				trace("Passou por A a " + ms.toFixed(1) + " m/s");
				avisoA = true;
				mostraResultado();
			}
		}*/
	}
	
	private function mostraResultado(event):void {
		if (!(event is MouseEvent)) if (event.keyCode != 13) return;
		
		boxResultado.gotoAndStop(1);
		setChildIndex(boxResultado, numChildren - 1);
		boxResultado.closeButton.addEventListener(MouseEvent.CLICK, function () { boxResultado.play(); } );
		
		var respostaAluno:Number = Number(resposta.text.replace(",", "."));
		
		if (isNaN(respostaAluno)) {
			boxResultado.resultado.text = "Você precisa digitar um número para ser avaliado.\nVerifique se existem caracteres inválidos ou duplicados no campo de resposta.";
			return;
		}
		
		var respostaEsperada:Number = velocidade / REL_PIX_METROS;
		
		if (respostaEsperada == 0) {
			boxResultado.resultado.text = "Você precisa jogar a bicicleta para ser avaliado.";
			return;
		}
		
		trace(respostaEsperada, Math.abs(respostaAluno - respostaEsperada),  Math.abs(respostaEsperada) * MARGEM_ERRO);
		
		if (Math.abs(Number(respostaAluno) - respostaEsperada) < Math.abs(respostaEsperada) * MARGEM_ERRO) {
			boxResultado.resultado.text = "Parabéns! Você sabe como medir a velocidade de um objeto em movimento.\nQue tal experimentar em outras situações? Jogue a bicicleta de novo, desta vez mais rápido ou mais lentamente, mude a posição das bandeiras e meça novamente a velocidade. Você pode repetir esse processo quantas vezes quiser.";
			currentScore = 100;
		}else {
			if (Math.abs( -Number(respostaAluno) - respostaEsperada) < Math.abs(respostaEsperada) * MARGEM_ERRO) {
				boxResultado.resultado.text = "Ops! Você mediu a velocidade corretamente, mas esqueceu de levar em conta o sentido do movimento: o sinal da sua resposta está invertido! Jogue novamente a bicicleta e tome este cuidado na próxima tentativa. Lembre-se: você pode realizar o exercício quantas vezes quiser.";
			}else if (Math.abs(Math.abs(respostaAluno) - Math.abs(respostaEsperada)) < 2 * Math.abs(respostaEsperada) * MARGEM_ERRO) {
				boxResultado.resultado.text = "Quase! Talvez a medida do tempo possa ser melhorada. Experimente refazê-la. Lembre-se de considerar também o sinal da velocidade.";
			}else {
				boxResultado.resultado.text = "Não é esta a velocidade da bicicleta! :( Confira a medida do tempo, a distância entre as bandeiras, o sentido do movimento (positivo para a direita e negativo para a esquerda) e a sua conta. Lembre-se: você pode refazer o exercício quantas vezes quiser.";
			}
			
			currentScore = 0;
		}
		
		nTentativas++;
		score = (score * (nTentativas - 1) + currentScore) / nTentativas;
		
		if (score >= 50) completed = true;
		commit();
	}
	
	private function keepHorizontal(e:Event):void {
		// Verifica se o veículo está se deslocando para a direita ou para a esquerda
		speed = mouseMotion.speed;
		if (speed.x > 0) veiculo.scaleX = 0.5;
		else if (speed.x < 0) veiculo.scaleX = -0.5;
		
		veiculo.y = 400;
	}
	
	private var diffClick:Point;
	private function pickUp(event:MouseEvent):void {
		//trace("pickUp");
		//veiculo.removeEventListener(MouseEvent.MOUSE_DOWN, drag);
		dragging = event.currentTarget as Sprite;
		//dragging.startDrag();
		setChildIndex(dragging, numChildren - 1);
		setChildIndex(veiculo, numChildren - 1);
		diffClick = new Point(dragging.mouseX, dragging.mouseY);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	private function dropIt(event:MouseEvent):void {
		//trace("dropIt", event.target.name);
		//trace(event.target.name, dragging);
		if (event.target.name == "botoes") return;
		if (event.target.name == "block") return;
		if (event.target.name == "background") return;
		
		veiculo.y = 400;
		
		velocidade = speed.x;
		//trace(velocidade);
		if (velocidade < -1000) velocidade = -1000;
		if (velocidade > 1000) velocidade = 1000;
		
		if ((event.target is Stage || event.target is Base || event.target.name == "unit") && (dragging is Seta1 || dragging is Seta2)) {
			veiculo.addEventListener(MouseEvent.MOUSE_DOWN, drag);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			dragging.y = ruler.y;
			
			if (event.target is Base) {
				event.target.stopDrag();
				return;
			}
			
			if (dragging.x < ruler.x + ruler.left.width) {
				dragging.x = ruler.x + ruler.left.width;
				dragging.pos.text = "-13m";
			}
			
			if (dragging.x > ruler.x + ruler.left.width + ruler.base.width) {
				dragging.x = ruler.x + ruler.left.width + ruler.base.width;
				dragging.pos.text = (ruler.base.width / razao1).toFixed(casas1).replace(".",",") + " m";
				if ((ruler.base.width / razao1) - Math.floor(ruler.base.width / razao1) == 0) dragging.pos.text = (ruler.base.width / razao1).toFixed(0) + " m";
			}
			
			// Limita a posicao da seta1 até a posição da seta2 e vice-versa
			if (dragging is Seta1 && dragging.x > seta2.x) {
				dragging.pos.text = seta2.pos.text;
				dragging.x = seta2.x;
				trace(dragging.name);
			}
			if (dragging is Seta2 && dragging.x < seta1.x) {
				dragging.pos.text = seta1.pos.text;
				dragging.x = seta1.x;
				trace(dragging.name);
			}
			
			if(dragging != null) {
				dragging.stopDrag();
				dragging = null;
			}		
			
			dragging = null;
		}
		
		if ((event.target is Stage || event.target is Base) && dragging is Taxi) {
			removeEventListener(Event.ENTER_FRAME, onEnterFrame2);
			removeEventListener(Event.ENTER_FRAME, keepHorizontal);
			ruler.removeEventListener(MouseEvent.MOUSE_UP, dropIt);
			
			dropX = event.target.x;
			
			speed = mouseMotion.speed;
			veiculo.stopDrag();
			v0 = velocidade;
			nStart = getTimer();
			clearInterval(intervalId);
			nMilliseconds = getTimer() - nStart;
			x0 = veiculo.x;
			addEventListener(Event.ENTER_FRAME, onEnterFrame2);
			dragging = null;
			return;
		}
		
		//trace(getQualifiedClassName(event.target.parent));
		
		if (/*event.target.parent is CaixaTexto || */event.target.parent is FeedBackScreen || event.target.name ==  "orientacoesBtn" || event.target.name == "instance23" || event.target.name == "instance31" || event.target.name == "instance35" || event.target.name == "creditos" || event.target.name == "tutorialBtn" || event.target.name == "resetButton" || event.target.name == "resposta" || event.target.name == "ok" || event.target.name == "base" || event.target.name == null || event.target.name == "reset" || event.target.name == "start" || event.target.name == "time" || event.target.name == "boxResultado" || event.target.name == "resultado" || event.target.name == "unit" || event.target.name == "left" || event.target.name == "right" || event.target.name == "instructionScreen" || event.target.name == "aboutScreen" || event.target.name == "instructionButton" || event.target.name == "aboutButton" || event.target.name == "instance13") return;
		
		if (dragging.name == "veiculo") {
			removeEventListener(Event.ENTER_FRAME, onEnterFrame2);
			removeEventListener(Event.ENTER_FRAME, keepHorizontal);
			ruler.removeEventListener(MouseEvent.MOUSE_UP, dropIt);
			
			dropX = event.target.x;
			
			speed = mouseMotion.speed;
			veiculo.stopDrag();
			v0 = velocidade;
			nStart = getTimer();
			clearInterval(intervalId);
			nMilliseconds = getTimer() - nStart;
			x0 = veiculo.x;
			addEventListener(Event.ENTER_FRAME, onEnterFrame2);
			dragging = null;
			return;
		}
		
		veiculo.addEventListener(MouseEvent.MOUSE_DOWN, drag);
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		dragging.y = ruler.y;
		
		if (event.target is Base) {
			event.target.stopDrag();
			return;
		}
		
		if (dragging.x < ruler.x + ruler.left.width) {
			dragging.x = ruler.x + ruler.left.width;
			dragging.pos.text = "-10m";
		}
		
		if (dragging.x > ruler.x + ruler.left.width + ruler.base.width) {
			dragging.x = ruler.x + ruler.left.width + ruler.base.width;
			dragging.pos.text = (ruler.base.width / razao1).toFixed(casas1).replace(".",",") + " m";
			if ((ruler.base.width / razao1) - Math.floor(ruler.base.width / razao1) == 0) dragging.pos.text = (ruler.base.width / razao1).toFixed(0) + " m";
		}
		
		if(dragging != null) {
			dragging.stopDrag();
			dragging = null;
		}		
		
		dragging = null;
	}
	
	private function showArrow(event:MouseEvent):void {
		if (justStarted) {
			seta1.pos.text = "-5,0 m";
			seta1.y = ruler.y;
			seta1.x = ruler.x + 218;
			seta2.pos.text = "5,0 m";
			seta2.y = ruler.y;
			seta2.x = ruler.x + 468;
			justStarted = false;
			return;
		}
		
		if (ruler.base.mouseX - diffClick.x >= 0 && ruler.base.mouseX - diffClick.x <= 652 && (ruler.mouseY < 30 || ruler.mouseY > 120) || dragging != null) {
			razao1 = CentToPix;
			dragging.y = ruler.y;
			if (!onTick) arrow1XPos = (ruler.base.mouseX - diffClick.x) / razao1 - 3;
			else arrow1XPos = Math.round((ruler.base.mouseX - diffClick.x) / razao1 - 3);
			dragging.x = mouseX - diffClick.x;
			dragging.pos.text = (Number((arrow1XPos +1).toFixed(casas1)) - 11).toFixed(casas1).replace(".", ",") + " m";
		}
		
		var tickProximity;
		var tick;
		var razao;
		var unit;

		if (dragging != null) {
			razao = razao1;
			
			tickProximity = (ruler.base.mouseX - diffClick.x)/ razao - Math.floor((ruler.base.mouseX - diffClick.x) / razao);  // Define a proximidade da seta em relação ao tick da unidade
			
			tick = Math.floor((ruler.base.mouseX - diffClick.x) / razao);  // Define o inteiro da medida onde se encontra a seta
			
			if (tickProximity < 0.15) {  // Aproximação da seta ao tick
				dragging.x = tick * razao + ruler.left.width;
				onTick = true;
			} else if (tickProximity > 0.85)  {  // Aproximação da seta ao tick
				dragging.x = (tick + 1) * razao + ruler.left.width;
				onTick = true;
			} else onTick = false;
			
			// Posiciona seta1 e seta2 sobre o tick da unidade e face escolhida
			//dragging.pos.text = ((dragging.x - (STAGEWIDTH - ruler.width - ruler.x + ruler.left.width)) / razao1).toFixed(casas1).replace(".",",") + " m";
		}
	}
	
	private function onEnterFrame(event:Event):void {
		showArrow(null);
		
		// Guarda na variavel lastText o ultimo conteudo do Textfield da seta
		if (dragging is Seta1 && dragging.x <= seta2.x) lastText = dragging.pos.text;
		else if (dragging is Seta2 && dragging.x >= seta1.x) lastText = dragging.pos.text;
		
		// Limita a posicao da seta1 até a posição da seta2 e vice-versa
		if (dragging is Seta1 && dragging.x > seta2.x) {
			dragging.pos.text = seta2.pos.text;
			dragging.x = seta2.x;
		}
		if (dragging is Seta2 && dragging.x < seta1.x) {
			dragging.pos.text = seta1.pos.text;
			dragging.x = seta1.x;
		}
		
		if (ruler.base.mouseX - diffClick.x < 0 && seta2.x > seta1.x && seta1.x < seta2.x) {  // "Zera" o marcador quando no início da régua
			dragging.x = ruler.x + ruler.left.width;
			dragging.pos.text = "-13 m";
			return;
		}
		if (ruler.base.mouseX - diffClick.x >= 650 && seta2.x > seta1.x && seta1.x < seta2.x) {  // Define o marcador ao seu máximo, de acordo com a escala, quando no fim da régua
			dragging.x = 669;
			dragging.pos.text = "13 m";
			return;
		}
	}
	
	private function doTheTicks():void{
		for (c = -13; c <= 13; c++) {  // Desenha os ticks dos centímetros
			bigTickCm[rulerSide][c] = new Cent();
			bigTickCm[rulerSide][c].unit.text = c;
			//if ((c / 5) - (Math.floor(c / 5)) != 0) bigTickCm[rulerSide][c].unit.visible = false;  // Define como invisível os valores não-múltiplos de 5
			bigTickCm[rulerSide][c].x = 325 + ruler.x + ruler.left.width + (c * CentToPix);
			//trace(ruler.x + ruler.left.width + (c * CentToPix));
			bigTickCm[rulerSide][c].y = ruler.y;
			addChild(bigTickCm[rulerSide][c]);
		}
		
		showArrow(null);
//		setChildIndex(selectBox, numChildren - 1);
	}
	
	
		private var tutorial:Tutorial;
	private function createTutorial():void
	{
		tutorial = new Tutorial();
		
		tutorial.adicionarBalao("Veja aqui as orientações.", new Point(578, 445), CaixaTextoNova.BOTTOM, CaixaTextoNova.LAST);
		tutorial.adicionarBalao("Use o mouse para jogar a bicicleta para a direita ou para a esquerda.", new Point(360, 310), CaixaTextoNova.BOTTOM, CaixaTextoNova.CENTER);
		tutorial.adicionarBalao("Use o mouse para posicionar as bandeiras conforme a sua necessidade (ou deixe-as como está).", new Point(485,265), CaixaTextoNova.BOTTOM, CaixaTextoNova.LAST);
		tutorial.adicionarBalao("Com a ajuda deste cronômetro, meça o tempo que a bicicleta leva para ir de uma bandeira até a outra.", new Point(530,100), CaixaTextoNova.RIGHT, CaixaTextoNova.CENTER);
		tutorial.adicionarBalao("Calcule a velocidade da bicicleta e digite-a aqui. Pressione \"OK\" para verificar.\n<b>Atenção: o sentido do movimento, para a direita ou para a esquerda, influi no sinal da velocidade</b>.", new Point(120,45), CaixaTextoNova.LEFT, CaixaTextoNova.FIRST);
	}
	
	
		//Tutorial
		private function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutorial.iniciar(stage, true);
		}
		
	
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:Number = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		private var caixas:Array;
		private var nTentativas;
		private var currentScore;
		private var stringTentativas:String;
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				//mementoSerialized = String(scorm.get("cmi.suspend_data"));
				var stringScore:String = scorm.get("cmi.score.raw");
				
				stringTentativas = scorm.get("cmi.suspend_data");
				
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				scormExercise = 1;
				if (stringScore != "") score = Number(stringScore.replace(",", "."));
				else score = 0;
				//txNota.text = score.toFixed(1).replace(".", ",");
				
				if (stringTentativas != "") nTentativas = int(stringTentativas);
				else nTentativas = 0;
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit():void
		{
			if (connected)
			{
				scorm.set("cmi.exit", "suspend");
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				success = scorm.set("cmi.suspend_data", String(nTentativas));
				
				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent):void
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
	}

}