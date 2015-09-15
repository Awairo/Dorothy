Dorothy!
CCScene = require "CCSceneEx"
Class,property,classfield = unpack require "class"
EditorView = require "View.Scene.Editor"

Class
	__partial: => EditorView!
	__init: =>
		@_gameName = ""
		@_gameFullPath = ""
		@_actionEditor = nil
		@_bodyEditor = nil
		@_effectEditor = nil
		@game = "Test"

		_G["editor"] = @
		builtin["editor"] = @

		@\slots "Cleanup",->
			_G["editor"] = nil
			builtin["editor"] = nil
			oCache\clear!
			CCScene\remove "actionEditor"
			CCScene\remove "bodyEditor"
			CCScene\remove "effectEditor"

		CCScene\add "sceneEditor",@
		CCScene\transition "rollIn",{"zoomFlip",0.5,CCOrientation.Down}
		CCScene\transition "rollOut",{"zoomFlip",0.5,CCOrientation.Up}

		for i = 1,10
			@["touchLevel"..tostring(i)] = CCMenu.DefaultHandlerPriority-i*10

		thread ->
			{:width,:height} = CCDirector.winSize
			panelWidth = 10+110*4
			panelHeight = height*0.6
			panelNames = {
				"SpritePanel"
				"ModelPanel"
				"BodyPanel"
				"EffectPanel"
			}
			sleep!
			for name in *panelNames
				Panel = require "Control."..name
				sleep!
				panel = Panel {
					x:width/2
					y:height/2
					width:panelWidth
					height:panelHeight
				}
				panel.visible = false
				@[name\sub(1,1)\lower!..name\sub(2,-1)] = panel
				@\addChild panel,1

			EditMenu = require "Control.EditMenu"
			sleep!
			@editMenu = EditMenu!
			@\addChild @editMenu

		@\gslot "Editor.SpriteChooser",(handler)->
			@spritePanel\slots "Selected",nil
			@spritePanel.parent\removeChild @spritePanel,false
			@spritePanel\slots("Hide")\set ->
				@spritePanel.parent\removeChild @spritePanel,false
				@\addChild @spritePanel,1
			handler @spritePanel

	updateSprites: =>
		emit "Scene.LoadSprite", @graphicFolder

	updateModels: =>
		emit "Scene.LoadModel", @graphicFolder

	updateBodies: =>
		emit "Scene.LoadBody", @physicsFolder

	updateEffects: =>
		emit "Scene.LoadEffect", @graphicFolder

	game: property => @_gameName,
		(name)=>
			oContent\removeSearchPath oContent.writablePath..@_gameName
			@_gameName = name
			@_gameFullPath = oContent.writablePath..name.."/"
			oContent\addSearchPath @_gameFullPath
			oContent\mkdir @_gameFullPath unless oContent\exist @_gameFullPath
			oContent\mkdir @graphicFullPath unless oContent\exist @graphicFullPath
			oContent\mkdir @physicsFullPath unless oContent\exist @physicsFullPath
			oContent\mkdir @logicFullPath unless oContent\exist @logicFullPath
			if @_actionEditor
				actionEditor.input = @gameFullPath
				actionEditor.output = @gameFullPath
			if @_bodyEditor
				bodyEditor.input = @gameFullPath
				bodyEditor.output = @gameFullPath

	gameFullPath: property => @_gameFullPath
	graphicFolder: property => "Graphic/"
	graphicFullPath: property => @_gameFullPath.."Graphic/"
	physicsFolder: property => "Physics/"
	physicsFullPath: property => @_gameFullPath.."Physics/"
	logicFolder: property => "Logic/"
	logicFullPath: property => @_gameFullPath.."Logic/"

	actionEditor: property =>
		if not @_actionEditor
			actionEditor = require "ActionEditor.Script.oEditor"
			actionEditor.standAlone = false
			actionEditor.quitable = true
			actionEditor.input = @gameFullPath
			actionEditor.output = @gameFullPath
			actionEditor.prefix = @graphicFolder
			actionEditor\slots "Edited",(model)->
				emit "Scene.ModelUpdated",model
			actionEditor\slots "Quit",->
				CCScene\run "sceneEditor","rollIn"
				@\updateModels!
			CCScene\add "actionEditor",actionEditor
			@_actionEditor = actionEditor
		return @_actionEditor

	bodyEditor: property =>
		if not @_bodyEditor
			bodyEditor = require "BodyEditor.Script.oEditor"
			bodyEditor.standAlone = false
			bodyEditor.quitable = true
			bodyEditor.input = @gameFullPath
			bodyEditor.output = @gameFullPath
			bodyEditor\slots "Edited",(body)->
				emit "Scene.BodyUpdated",body
			bodyEditor\slots "Quit",->
				CCScene\run "sceneEditor","rollIn"
				@\updateBodies!
			CCScene\add "bodyEditor",bodyEditor
			@_bodyEditor = bodyEditor
		return @_bodyEditor

	effectEditor: property =>
		if not @_effectEditor
			effectEditor = require "EffectEditor.Script.oEditor"
			effectEditor.standAlone = false
			effectEditor.quitable = true
			effectEditor.listFile = @graphicFolder.."list.effect"
			effectEditor.prefix = @graphicFolder
			effectEditor.input = @gameFullPath
			effectEditor.output = @gameFullPath
			effectEditor\slots "Edited",(effect)->
				emit "Scene.EffectUpdated",effect
			effectEditor\slots "Quit",->
				CCScene\run "sceneEditor","rollIn"
				@\updateEffects!
			CCScene\add "effectEditor",effectEditor
			@_effectEditor = effectEditor
		return @_effectEditor
