Dorothy!
Class,property = unpack require "class"
MainSceneView = require "View.Scene.MainScene"
SpriteView = require "Control.SpriteView"

Class
	__partial: => MainSceneView!
	__init: =>
		@scrollArea\slots "Scrolled",(delta)->
			@menu\eachChild (child)->
				child.position += delta

		@scrollArea\slots "ScrollStart",->
			@menu.enabled = false

		@scrollArea\slots "ScrollEnd",->
			@menu.enabled = true

		--@btn\slots "Tapped", ->
		--	@viewItem.isCheckMode = not @viewItem.isCheckMode

		images = {}
		clips = {}
		models = {}
		bodies = {}
		frames = {}
		particles = {}

		visitResource = (path)->
			return unless oContent\exist path
			files = oContent\getEntries path,false
			for file in *files
				extension = file\match "%.([^%.\\/]*)$"
				extension = extension\lower! if extension
				filename = path.."/"..file
				switch extension
					when "png","jpg","jpeg"
						clipFile = filename\match("(.*)%.[^%.\\/]*$")..".clip"
						table.insert images,filename unless oContent\exist clipFile
					when "model"
						table.insert models,filename
					when "body"
						table.insert bodies,filename
					when "clip"
						table.insert clips,filename
					when "frame"
						table.insert frames,filename
					when "par"
						table.insert particles,filename
			folders = oContent\getEntries path,true
			for folder in *folders
				if folder ~= "." and folder ~= ".."
					visitResource path.."/"..folder

		visitResource "ActionEditor/Model/Input"
		visitResource oContent.writablePath.."Model"
		visitResource oContent.writablePath.."Body"
		visitResource oContent.writablePath.."Effect"

		{:width,:height} = @scrollArea
		y = 0
		for i,image in ipairs images
			i -= 1
			x = 60+(i%4)*110
			y = height-60-math.floor(i/4)*110
			viewItem = SpriteView file:image,x:x,y:y,width:100,height:100
			@menu\addChild viewItem
		y -= 50

		startY = y
		TabButton = require "View.Control.TabButton"
		for i,clip in ipairs clips
			i -= 1
			y = startY-25-i*40
			clipItem = TabButton x:225,y:y,text:clip
			@menu\addChild clipItem
		y -= 25

		@scrollArea.viewSize = CCSize 450,10+math.floor((#images-1)/4+1)*110+40
