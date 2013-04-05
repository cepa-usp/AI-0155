package 
{
	import BaseAssets.BaseMain;
	import BaseAssets.status.SaveAPI;
	import BaseAssets.tutorial.CaixaTextoNova;
	import BaseAssets.tutorial.Tutorial;
	import BaseAssets.tutorial.TutorialEvent;
	import cepa.utils.ToolTip;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends Sprite
	{
		private var tweenX:Tween;
		private var tweenY:Tween;
		
		private var tweenX2:Tween;
		private var tweenY2:Tween;
		
		private var tweenTime:Number = 0.2;
		private var saveAPI:SaveAPI;
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			this.scrollRect = new Rectangle(0, 0, 700, 600);
			
			conectaImagens();
			adicionaListeners();
			addListeners();
			criaTutorial();
			
			createAnswer();
			
			//debugMessage("criando save api");
			saveAPI = new SaveAPI();
			
			var status:Object = saveAPI.recoverStatus();
			//debugMessage("recuperou status");
			if (status != null) {
				recoverStatus(status);
			}
			
			verificaFinaliza();
			
			if (saveAPI.completed) travaPecas();
			
			if(!tutorialCompleted) iniciaTutorial();
		}
		
		private function conectaImagens():void 
		{
			Fundo(fundo1).imagem = imagem1;
			Fundo(fundo2).imagem = imagem2;
			Fundo(fundo3).imagem = imagem3;
			Fundo(fundo4).imagem = imagem4;
			Fundo(fundo5).imagem = imagem5;
			Fundo(fundo6).imagem = imagem6;
			Fundo(fundo7).imagem = imagem7;
			Fundo(fundo8).imagem = imagem8;
		}
		
		/**
		 * Adiciona os eventListeners nos botões.
		 */
		private function adicionaListeners():void 
		{
			makeButton(botoes.tutorialBtn);
			makeButton(botoes.orientacoesBtn);
			makeButton(botoes.creditos);
			makeButton(botoes.resetButton);
			
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, openOrientacoes);
			botoes.creditos.addEventListener(MouseEvent.CLICK, openCreditos);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reset);
			
			createToolTips();
		}
		
		private function makeButton(btn:MovieClip):void
		{
			btn.gotoAndStop(1);
			btn.buttonMode = true;
			btn.mouseChildren = false;
			btn.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):void {MovieClip(e.target).gotoAndStop(2) } );
			btn.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):void {MovieClip(e.target).gotoAndStop(1) } );
		}
		
		/**
		 * Cria os tooltips nos botões
		 */
		private function createToolTips():void 
		{
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			
			addChild(intTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(infoTT);
			
		}
		
		/**
		 * Abrea a tela de orientações.
		 */
		private function openOrientacoes(e:MouseEvent):void 
		{
			orientacoesScreen.openScreen();
			setChildIndex(orientacoesScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		/**
		 * Abre a tela de créditos.
		 */
		private function openCreditos(e:MouseEvent):void 
		{
			creditosScreen.openScreen();
			setChildIndex(creditosScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function addListeners():void 
		{
			finaliza.addEventListener(MouseEvent.CLICK, finalizaExec);
			finaliza.buttonMode = true;
		}

		
		private var wrongFilter:GlowFilter = new GlowFilter(0xFF0000);
		private var rightFilter:GlowFilter = new GlowFilter(0x00DD00);
		private function finalizaExec(e:MouseEvent):void 
		{
			var nCertas:int = 0;
			var nPecas:int = 0;
			
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					nPecas++;
					if(Peca(child).fundo.indexOf(Peca(child).currentFundo) != -1){
						nCertas++;
						//trace(Peca(child).nome);
						Peca(child).currentFundo.filters = [rightFilter];
					}else {
						Peca(child).currentFundo.filters = [wrongFilter];
					}
				}
			}
			
			var currentScore:Number = int((nCertas / nPecas) * 100);
			
			if (currentScore < 100) {
				feedbackScreen.setText("Ops! Reveja sua resposta. Os erros foram destacados em vermelho.");
			}
			else {
				feedbackScreen.setText("Parabéns!\nA classificação está correta!");
			}
			
			setChildIndex(feedbackScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
			
			if (!saveAPI.completed) {
				//debugMessage("nao completo");
				travaPecas();
				//debugMessage("travou peças");
				saveAPI.completed = true;
				tutorialCompleted = true;
				//debugMessage("completo");
				saveAPI.score = currentScore;
				saveStatus();
			}
		}
		
		private function debugMessage(txt:String):void
		{
			//debug.text += txt + "\n";
		}
		
		private function travaPecas():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					Peca(child).mouseEnabled = false;
				}
			}
			
			//finaliza.mouseEnabled = false;
			//finaliza.alpha = 0.5;
			
			botoes.resetButton.mouseEnabled = false;
			botoes.resetButton.alpha = 0.5;
		}
		
		private function verificaFinaliza():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if(Peca(child).currentFundo == null){
						finaliza.mouseEnabled = false;
						finaliza.alpha = 0.5;
						return;
					}
				}
			}
			
			finaliza.mouseEnabled = true;
			finaliza.alpha = 1;
		}
		
		private function checkForFinish():Boolean
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				
				if (child is Peca) {
					if (Peca(child).currentFundo == null) return false;
				}
			}
			
			return true;
		}
		
		private function createAnswer():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					setAnswerForPeca(Peca(child));
					var objClass:Class = Class(getDefinitionByName(getQualifiedClassName(child)));
					var ghostObj:* = new objClass();
					MovieClip(ghostObj).gotoAndStop(1);
					Peca(child).ghost = ghostObj;
					Peca(child).addListeners();
					Peca(child).inicialPosition = new Point(child.x, child.y);
					child.addEventListener("paraArraste", verifyPosition);
					child.addEventListener("iniciaArraste", verifyForFilter);
					Peca(child).buttonMode = true;
					Peca(child).gotoAndStop(1);
				}
				
			}
		}
		
		private function saveStatus():void
		{
			//debugMessage("inicio salvando status");
			var status:Object = new Object();
			
			status.pecas = new Object();
			status.tutoComp = tutorialCompleted;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (Peca(child).currentFundo != null) status.pecas[child.name] = Peca(child).currentFundo.name;
					else status.pecas[child.name] = "null";
				}
			}
			//debugMessage("mandando pra api");
			try {
				saveAPI.saveStatus(status);
			}catch (err:Error){
				//debugMessage(err.message);
			}
			//debugMessage("final salvando status");
			//mementoSerialized = JSON.stringify(status);
		}
		
		private function recoverStatus(status:Object):void
		{
			//var status:Object = JSON.parse(memento);
			
			tutorialCompleted = status.tutoComp;
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (status.pecas[child.name] != "null") {
						Peca(child).currentFundo = getFundoByName(status.pecas[child.name]);
						Fundo(Peca(child).currentFundo).currentPeca = Peca(child);
						Peca(child).x = Peca(child).currentFundo.x;
						Peca(child).y = Peca(child).currentFundo.y;
						Peca(child).gotoAndStop(2);
					}
				}
			}
			
		}
		
		private var pecaDragging:Peca;
		//private var fundoFilter:GlowFilter = new GlowFilter(0xFF0000, 1, 20, 20, 1, 2, true, true);
		private var fundoFilter:GlowFilter = new GlowFilter(0x0000FF);
		private var fundoWGlow:MovieClip;
		private function verifyForFilter(e:Event):void 
		{
			pecaDragging = Peca(e.target);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, verifying);
		}
		
		private function verifying(e:MouseEvent):void 
		{
			var fundoUnder:Fundo = getFundo(new Point(pecaDragging.ghost.x, pecaDragging.ghost.y));
			
			if (fundoUnder != null) {
				/*if (fundoUnder.currentPeca != null) {
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}
				}else{*/
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}
				//}
			}else {
				if (fundoWGlow != null) {
					if(fundoWGlow is Fundo){
						Fundo(fundoWGlow).borda.filters = [];
					}else {
						fundoWGlow.gotoAndStop(1);
					}
					fundoWGlow = null;
				}
			}
		}
		
		private function verifyPosition(e:Event):void 
		{
			//debugMessage("soltou peça");
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, verifying);
			pecaDragging = null;
			if (fundoWGlow != null) {
				if (fundoWGlow is Fundo) fundoWGlow.borda.filters = [];
				else fundoWGlow.gotoAndStop(1);
				fundoWGlow = null;
			}
			
			var peca:Peca = e.target as Peca;
			var fundoDrop:Fundo = getFundo(peca.position);
			
			if (fundoDrop != null) {
				if (fundoDrop.currentPeca == null) {
					if (peca.currentFundo != null) {
						Fundo(peca.currentFundo).currentPeca = null;
					}
					fundoDrop.currentPeca = peca;
					peca.currentFundo = fundoDrop;
					//tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, 0.5, true);
					//tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, 0.5, true);
					peca.x = fundoDrop.x;
					peca.y = fundoDrop.y;
					peca.gotoAndStop(2);
				}else {
					if(peca.currentFundo != null){
						var pecaFundo:Peca = Peca(fundoDrop.currentPeca);
						var fundoPeca:Fundo = Fundo(peca.currentFundo);
						
						tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, tweenTime, true);
						tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, tweenTime, true);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, fundoPeca.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, fundoPeca.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = fundoPeca;
						fundoPeca.currentPeca = pecaFundo;
					}else {
						pecaFundo = Peca(fundoDrop.currentPeca);
						
						//tweenX = new Tween(peca, "x", None.easeNone, peca.position.x, fundoDrop.x, tweenTime, true);
						//tweenY = new Tween(peca, "y", None.easeNone, peca.position.y, fundoDrop.y, tweenTime, true);
						peca.x = fundoDrop.x;
						peca.y = fundoDrop.y;
						peca.gotoAndStop(2);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, pecaFundo.inicialPosition.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, pecaFundo.inicialPosition.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = null;
						pecaFundo.gotoAndStop(1);
					}
				}
			}else {
				if (peca.currentFundo != null) {
					Fundo(peca.currentFundo).currentPeca = null;
					peca.currentFundo = null;
				}
				tweenX = new Tween(peca, "x", None.easeNone, peca.x, peca.inicialPosition.x, tweenTime, true);
				tweenY = new Tween(peca, "y", None.easeNone, peca.y, peca.inicialPosition.y, tweenTime, true);
				peca.gotoAndStop(1);
			}
			
			verificaFinaliza();
			
			//debugMessage("setando timeout");
			setTimeout(saveStatus, (tweenTime + 0.1) * 1000);
		}
		
		private function getFundo(position:Point):Fundo 
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.hitTestPoint(position.x, position.y) || Fundo(child).imagem.hitTestPoint(position.x, position.y)) return Fundo(child);
				}
			}
			return null;
		}
		
		private function getFundoByName(name:String):Fundo 
		{
			if (name == "") return null;
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.name == name) return Fundo(child);
				}
			}
			return null;
		}
		
		private function setAnswerForPeca(child:Peca):void 
		{
			if (child is Peca1) {
				child.fundo = [fundo1];
				child.nome = "peca1";
			}else if (child is Peca2) {
				child.fundo = [fundo2];
				child.nome = "peca2";
			}else if (child is Peca3) {
				child.fundo = [fundo3];
				child.nome = "peca3";
			}else if (child is Peca4) {
				child.fundo = [fundo4];
				child.nome = "peca4";
			}else if (child is Peca5) {
				child.fundo = [fundo5];
				child.nome = "peca5";
			}else if (child is Peca6) {
				child.fundo = [fundo6];
				child.nome = "peca6";
			}else if (child is Peca7) {
				child.fundo = [fundo7];
				child.nome = "peca7";
			}else if (child is Peca8) {
				child.fundo = [fundo8];
				child.nome = "peca8";
			}
		}
		
		public function reset(e:MouseEvent = null):void
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					child.x = Peca(child).inicialPosition.x;
					child.y = Peca(child).inicialPosition.y;
					Peca(child).currentFundo = null;
					Peca(child).gotoAndStop(1);
				}
				if (child is Fundo) {
					Fundo(child).currentPeca = null;
					Fundo(child).filters = [];
				}
			}
			
			verificaFinaliza();
			saveStatus();
		}
		
		
		//---------------- Tutorial -----------------------
		
		private var tutorial:Tutorial;
		private var tutorialCompleted:Boolean = false;
		
		private function criaTutorial():void
		{
			tutorial = new Tutorial();
			tutorial.adicionarBalao("Arraste os filos...", new Point(365, 510), CaixaTextoNova.BOTTOM, CaixaTextoNova.CENTER);
			tutorial.adicionarBalao("... para as caixas corretas...", new Point(350 , 177), CaixaTextoNova.TOP, CaixaTextoNova.CENTER);
			tutorial.adicionarBalao("... conforme descrito nas orientações.", new Point(650 , 500), CaixaTextoNova.RIGHT, CaixaTextoNova.FIRST);
			tutorial.adicionarBalao("Quando você tiver concluído, pressione \"terminei\".", new Point(finaliza.x, finaliza.y + finaliza.height / 2), CaixaTextoNova.TOP, CaixaTextoNova.LAST);
		}
		
		public function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutorial.removeEventListener(TutorialEvent.FIM_TUTORIAL, tutorialFinalizado);
			tutorial.iniciar(stage, true);
			tutorial.addEventListener(TutorialEvent.FIM_TUTORIAL, tutorialFinalizado);
		}
		
		private function tutorialFinalizado(e:TutorialEvent):void 
		{
			tutorial.removeEventListener(TutorialEvent.FIM_TUTORIAL, tutorialFinalizado);
			if (e.last) tutorialCompleted = true;
			//if (ExternalInterface.available) ExternalInterface.call("save2LS", tutorialCompleted.toString());
			saveStatus();
		}
		
	}

}