Dorothy!
Class,property = unpack require "class"
SpriteViewView = require "View.Control.SpriteView"

Class
	__partial: (args)=> SpriteViewView args
	__init: (args)=>
		{:width,:height,:file} = args
		@_isCheckMode = false
		@_checked = false
		@boxFill.visible = false
		@\slots "TapBegan",->
			@\_setBoxChecked not @_checked if @isCheckMode
		@\slots "Tapped", ->
			@\emit "Selected",@ if not @isCheckMode
		@\updateImage file
		@isCheckMode = true

	updateImage: (file)=>
		go ->
			oCache.Texture\unload @_file if @_file
			oCache\loadAsync file
			sprite = CCSprite file
			{:width,:height} = @
			scale = math.min width/sprite.width,height/sprite.height
			sprite.scaleX = scale
			sprite.scaleY = scale
			sprite.position = oVec2 width/2,height/2
			renderTarget = CCRenderTarget width,height
			renderTarget\beginDraw!
			renderTarget\draw sprite
			renderTarget\endDraw!
			oCache.Texture\unload file
			sleep 0.1
			@_file = file\match("(.*)%.[^%.\\/]*$").."Small."..file\match("%.([^%.\\/]*)$")
			tex = oCache.Texture\add renderTarget,@_file
			@sprite.texture = tex
			@sprite.textureRect = CCRect 0,0,width,height
			@sprite.opacity = 0
			@sprite\perform oOpacity 0.3,1

	_setBoxChecked: (checked)=>
		@_checked = checked
		@boxFill.visible = checked
		@\emit "Checked",checked

	checked: property => @_checked

	isCheckMode: property => @_isCheckMode,
		(value)=>
			@_isCheckMode = value
			@boxFace.visible = value
			if not value
				@\_setBoxChecked false if @_checked
