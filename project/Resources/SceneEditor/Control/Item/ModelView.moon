Dorothy!
SpriteViewView = require "View.Control.Item.SpriteView"
oStar = require "EffectEditor.Script.oStar"

-- [signals]
-- "Selected",(viewItem)->
-- [params]
-- x, y, width, height, file
Class SpriteViewView,
	__init: (args)=>
		{:width,:height,:file} = args
		@_loaded = false
		@_checked = false
		@file = file
		@star = with CCDrawNode!
			\drawPolygon oStar(12),ccColor4(0x66ff0088),0.5,ccColor4(0xffff0088)
			.visible = false
			.position = oVec2 width-20,20
		@face\addChild @star

		@slot "Tapped",->
			@emit "Selected",@

		@slot "Cleanup",->
			oCache.Texture\unload @_prevFile if @_prevFile

		thread ->
			@_loaded = false
			oCache\loadAsync file,-> @_loaded = true
			if not @_loaded
				name = file\match "([^\\/]*)%.[^%.\\/]*$"
				@face\addChild with CCLabelTTF "Broken\nModel\n"..name,"Arial",16
					.position = oVec2 width/2,height/2
					.texture.antiAlias = false
					.color = ccColor3 0x00ffff
					\perform oOpacity 0.3,1
				@face\removeChild @sprite
				@sprite = nil
				return
			model = oModel file
			looks = oCache.Model\getLookNames file
			model.look = looks[1] if #looks > 0
			box = model.boundingBox
			sizeW = box.width
			sizeH = box.height
			offset = oVec2 box.centerX,box.centerY
			if sizeW == 0 and sizeH == 0
				name = file\match "([^\\/]*)%.[^%.\\/]*$"
				@face\addChild with CCLabelTTF "Empty\nModel\n"..name,"Arial",16
					.position = oVec2 width/2,height/2
					.texture.antiAlias = false
					.color = ccColor3 0x00ffff
					\perform oOpacity 0.3,1
				@face\removeChild @sprite
				@sprite = nil
				return
			scale = 1
			if width < sizeW or height < sizeH
				scale = math.min width/sizeW,height/sizeH
			scale *= 0.9
			model.scaleX = scale
			model.scaleY = scale
			model.position = oVec2(width/2,height/2)-offset*scale
			renderTarget = CCRenderTarget width,height
			renderTarget\beginDraw!
			renderTarget\draw model
			renderTarget\endDraw!
			@_prevFile = file\match("(.*)%.[^%.\\/]*$").."Small."..file\match("%.([^%.\\/]*)$")
			tex = oCache.Texture\add renderTarget,@_prevFile
			if @sprite
					@sprite.texture = tex
					@sprite.textureRect = CCRect 0,0,width,height
					@sprite.opacity = 0
					@sprite\perform oOpacity 0.3,1
					thread ->
						sleep 0.1
						oCache.Texture\removeUnused!

	isLoaded: property => @_loaded

	checked: property => @_checked,
		(value)=>
			@_checked = value
			if value
				@star.visible = true
				@star.scaleX = 0
				@star.scaleY = 0
				@star\perform oScale 0.3,1,1,oEase.OutBack
			else
				@star\perform CCSequence {
					oScale 0.3,0,0,oEase.InBack
					CCHide!
				}
