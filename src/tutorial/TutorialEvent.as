package  
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Arthur Tofani
	 */
	public class TutorialEvent extends Event 
	{
		static public const INICIO_TUTORIAL:String = "inicioTutorial";
		static public const BALAO_ABRIU:String = "balaoAbriu";
		static public const FIM_TUTORIAL:String = "fimTutorial";
		static public const PROXIMO:String = "proximo";
		private var _numBalao:int;
		public var last:Boolean = false;
		
		public function TutorialEvent(numbalao:int, type:String, bubbles:Boolean=false, cancelable:Boolean=false) 
		{ 
			_numBalao = numbalao;
			super(type, bubbles, cancelable);
			
		} 
		
		public override function clone():Event 
		{ 
			return new TutorialEvent(_numBalao, type, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("TutorialEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get numBalao():int 
		{
			return _numBalao;
		}
		
		public function set numBalao(value:int):void 
		{
			_numBalao = value;
		}
		
		

	}
	
}