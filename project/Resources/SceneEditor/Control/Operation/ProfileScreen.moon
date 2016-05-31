Dorothy!
ProfileScreenView = require "View.Control.Operation.ProfileScreen"
Button = require "Control.Basic.Button"

Class ProfileScreenView,
	__init:=>
		if CCDirector.notificationNode
			if CCDirector.notificationNode.name == "ProfileScreen"
				return
			children = CCDirector.notificationNode.children
			if children
				for child in *children
					if child.name == "ProfileScreen"
						return
			CCDirector.notificationNode\addChild @
		else
			CCDirector.notificationNode = @

		{:width,:height} = CCDirector.winSize
		wordColor = ccColor3 0x00ffff
		numColor = ccColor3 0xff0080

		@name = "ProfileScreen"

		@profileLabel.texture.antiAlias = false
		totalUpdate = 0
		totalDraw = 0
		totalTime = 0
		totalFrame = 0
		totalDrawcall = 0
		loopWork = loop ->
			luaMem = collectgarbage "count"
			poolSize = oCache.Pool.size
			text = table.concat {
				"Draw Call:    #{ math.floor totalDrawcall/totalFrame }."
				"CC Object:    #{ CCObject.count }(#{ CCObject.maxCount })."
				"Lua Object:    #{ CCObject.luaRefCount }(#{ CCObject.maxLuaRefCount })."
				"Callback:    #{ CCObject.callRefCount }(#{ CCObject.maxCallRefCount })."
				"Lua Memory:    #{ string.format '%.2f MB', luaMem/1024 }."
				"Dorothy Pool:    #{ string.format '%.2f MB', poolSize/1024/1024 }."
				"Update Interval:    #{ string.format '%d ms', totalUpdate*1000/totalFrame }."
				"Draw Interval:    #{ string.format '%d ms', totalDraw*1000/totalFrame }."
				"DeltaTime:    #{ string.format '%d ms', totalTime*1000/totalFrame }."
				""
			}, "\n\n"
			@profileLabel.text = text
			for start,mid,stop in text\gmatch "()[^:\n]+():[^\n]+()%.\n"
				@profileLabel\colorText start,mid,wordColor
				@profileLabel\colorText mid+2,stop,numColor
			sleep 1
			totalUpdate = 0
			totalDraw = 0
			totalTime = 0
			totalFrame = 0
			totalDrawcall = 0
			if @editorData
				if @quitBtn
					if not @quitBtn.face.visible
						@quitBtn.enabled = true
						@quitBtn.face.visible = true
						@quitBtn.face\perform oScale 0.3,1,1,oEase.OutBack
				else
					@quitBtn = with Button {
							text:"Quit Game"
							width:150
							height:40
							fontSize:18
						}
						.position = oVec2 .width/2,.height/2
						.scaleX,.scaleY = 0,0
						\perform oScale 0.3,1,1,oEase.OutBack
						\slot "Tapped",->
							@quitBtn.enabled = false
							@quitBtn.face\perform CCSequence {
								oScale 0.3,0,0,oEase.OutQuad
								CCHide!
							}
							APIs = require "Lib.Game.APIs"
							APIs.Unload()
							Game = require "Lib.Game.Game"
							Game.instance\stopAllTriggers!

							Editor = require "Scene.Editor"
							CCScene\add "sceneEditor",with Editor!
								.firstLaunch = false
								.startupData = @editorData
								.lastScene = @editorData.lastScene
								@editorData.lastScene = nil
							CCScene\run "sceneEditor"
							@editorData = nil
					@screen\addChild with CCMenu!
						.touchPriority = @profileBtn.touchPriority-1
						.contentSize = CCSize 150,40
						.position = @profileLabel.position+
							oVec2(@profileLabel.width/2,-@profileLabel.height-30)
						\addChild @quitBtn

		with @screen
			.visible = false
			.opacity = 0

		startPos = nil
		with @profileBtn
			.screenOpened = false
			.opacity = 0.1

			\slot "TouchBegan",(touch)->
				loc = \convertToNodeSpace touch.location
				startPos = oVec2.zero
				hit = CCRect(-.width/2,-.height/2,.width,.height)\containsPoint loc
				\perform CCSpawn {
					oOpacity 0.3,0.8,oEase.OutQuad
					oScale 0.3,1.2,1.2,oEase.OutBack
				} if hit
				hit

			\slot "TouchMoved",(touch)->
				if startPos.length > 10
					pos = .position + touch.delta
					pos\clamp oVec2(35,35),oVec2(width-35,height-35)
					.position = pos
				else
					startPos += touch.delta

			touchEnded = ->
				\perform CCSpawn {
					oOpacity 0.3,0.1,oEase.OutQuad
					oScale 0.3,1,1,oEase.OutQuad
				}
				if startPos.length <= 10
					.screenOpened = not .screenOpened
					if .screenOpened
						@screen\perform CCSequence {
							CCShow!
							oOpacity 0.3,1,oEase.OutQuad
						}
						@schedule (deltaTime)->
							totalFrame += 1
							totalTime += deltaTime
							totalDraw += CCDirector.drawInterval
							totalUpdate += CCDirector.updateInterval
							totalDrawcall += CCDirector.numberOfDraws
							loopWork!
					else
						@screen\perform CCSequence {
							oOpacity 0.3,0,oEase.OutQuad
							CCHide!
						}
						@unschedule!
			\slot "TouchCancelled",touchEnded
			\slot "TouchEnded",touchEnded

		@gslot "Scene.EditorData",(editorData)-> @editorData = editorData

		--editor\slot "Cleanup",->
		--	if CCDirector.notificationNode == @
		--		CCDirector.notificationNode = nil
		--	else
		--		@parent\removeChild @
