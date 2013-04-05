package BaseAssets.status
{
	import com.adobe.serialization.json.JSON;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	import BaseAssets.status.Base64;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class SaveAPI 
	{
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var _completed:Boolean;
		private var scorm:SCORM;
		private var _scormExercise:int = 0;
		private var connected:Boolean;
		private var _score:int = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		private var available:Boolean = false;
		private var _iniciada:Boolean = false;
		private var status:String;
		
		public function SaveAPI() {
			if (ExternalInterface.available) {
				available = true;
				initLMSConnection();
			}
		}
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection():void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			connected = scorm.connect();
			
			if (connected) {
				
				//if (scorm.get("cmi.mode") != "normal") return;
				
				scorm.set("cmi.exit", "suspend");
				// Verifica se a AI já foi concluída.
				status = scorm.get("cmi.completion_status");	
				mementoSerialized = scorm.get("cmi.suspend_data");
				var stringScore:String = scorm.get("cmi.score.raw");
				
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
						_iniciada = true;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						_iniciada = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				
				scormExercise = int(scorm.get("cmi.location"));
				score = Number(stringScore.replace(",", "."));
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					//pingTimer.start();
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
				mementoSerialized = ExternalInterface.call("getLocalStorageString");
				if(mementoSerialized != null){
					var descompressed:String = uncompress(mementoSerialized);
					var status = JSON.decode(descompressed);
					completed = status.completed;
					score = status.score;
				}
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				//if (scorm.get("cmi.mode") != "normal") return;
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());
				success = scorm.set("cmi.score.scaled", score.toString());
				
				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));
				
				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				//mementoSerialized = marshalObjects();
				success = scorm.set("cmi.suspend_data", mementoSerialized.toString());
				
				if (score > 80) success = scorm.set("cmi.success_status", "passed");
				else success = scorm.set("cmi.success_status", "failed");
				
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
			}else { //LocalStorage
				ExternalInterface.call("save2LS", mementoSerialized);
			}
		}
		
		public function automaticSave(time:Number = PING_INTERVAL):void
		{
			pingTimer = new Timer(time);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			pingTimer.start();
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
		
		public function saveStatus(memento:Object):void
		{
			//var stringMemento:String = JSON.stringify(memento);
			var status:Object = new Object();
			status.memento = memento;
			status.completed = completed;
			status.score = score;
			
			//var stringMemento:String = JSON.encode(memento);
			var stringMemento:String = JSON.encode(status);
			mementoSerialized = compress(stringMemento);
			//trace("compactado: " + mementoSerialized);
			
			if (available) {
				if (connected) {
					scorm.set("cmi.suspend_data", mementoSerialized);
					commit();
				}else {//LocalStorage
					ExternalInterface.call("save2LS", mementoSerialized);
				}
			}
		}
		
		public function recoverStatus():Object
		{
			var obj:Object;
			
			if (mementoSerialized) {
				try{
					var descompressed:String = uncompress(mementoSerialized);
					mementoSerialized = descompressed;
					//trace("descompactado: " + mementoSerialized);
					//obj = JSON.parse(mementoSerialized);
					var status = JSON.decode(mementoSerialized);
					obj = status.memento;
					//obj = JSON.decode(mementoSerialized);
					
				}catch (error:Error){
					
				}
			}
			return obj;
		}
		
		public static function compress( str:String ) :String
		{
		   var b:ByteArray = new ByteArray();
		   b.writeObject( str );
		   b.compress();
		   return Base64.Encode( b );
		}

		public static function uncompress( str:String ) :String
		{
		   var b:ByteArray = Base64.Decode( str );
		   b.uncompress();
		   var strB:String = b.toString();
		   var index:int = strB.indexOf("{");
		   return strB.substring(index);
		}
		
		public function get score():int 
		{
			return _score;
		}
		
		public function set score(value:int):void 
		{
			_score = value;
		}
		
		public function get scormExercise():int 
		{
			return _scormExercise;
		}
		
		public function set scormExercise(value:int):void 
		{
			_scormExercise = value;
		}
		
		public function get iniciada():Boolean 
		{
			return _iniciada;
		}
		
		public function get completed():Boolean 
		{
			return _completed;
		}
		
		public function set completed(value:Boolean):void 
		{
			_completed = value;
		}
		
		public function save():void
		{
			commit();
		}
	}
	
}