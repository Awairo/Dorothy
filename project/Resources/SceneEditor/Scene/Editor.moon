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
		@game = "Test"
		_G["editor"] = @
		builtin["editor"] = @
		@\slots "Cleanup",->
			_G["editor"] = nil
			builtin["editor"] = nil
			oCache\clear!
			CCScene\remove "actionEditor"
		--@spritePanel\show!
		--@spritePanel\slots "Selected",(spriteStr)->
			--@addChild with CCSprite spriteStr
				--.position = oVec2 @width/2,@height/2
		@\updateModels!
		CCScene\add "sceneEditor",@
		CCScene\add "actionEditor",@actionEditor
		CCScene\transition "rollIn",{"zoomFlip",0.5,CCOrientation.Down}
		CCScene\transition "rollOut",{"zoomFlip",0.5,CCOrientation.Up}

	updateSprites: =>
		emit "Editor.LoadSprite", { @graphicFolder }

	updateModels: =>
		emit "Editor.LoadModel", { @graphicFolder }

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

	gameFullPath: property => @_gameFullPath
	graphicFolder: property => "Graphic/"
	graphicFullPath: property => @_gameFullPath.."Graphic/"
	physicsFolder: property => "Physics/"
	physicsFullPath: property => @_gameFullPath.."Physics/"
	logicFolder: property => "Logic/"
	logicFullPath: property => @_gameFullPath.."Logic/"

	actionEditor: property =>
		if not @_actionEditor
			actionEditor = require("ActionEditor.Script.oEditor")
			actionEditor.standAlone = false
			actionEditor.quitable = true
			actionEditor.input = @gameFullPath
			actionEditor.output = @gameFullPath
			actionEditor\slots "Activated",->
				actionEditor\edit actionEditor.model
			actionEditor\slots "Quit",->
				CCScene\run "sceneEditor","rollIn"
				@\updateModels!
			@_actionEditor = actionEditor
		return @_actionEditor
