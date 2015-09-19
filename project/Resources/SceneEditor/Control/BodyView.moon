Dorothy!
Class,property = unpack require "class"
SpriteViewView = require "View.Control.SpriteView"
MessageBox = require "Control.MessageBox"
oBody = require "oBodyEx"
oStar = require "EffectEditor.Script.oStar"
-- [signals]
-- "Selected",(viewItem)->
-- [params]
-- x, y, width, height, file
Class
	__partial: (args)=> SpriteViewView args
	__init: (args)=>
		{:width,:height,:file} = args
		@_loaded = false
		@_checked = false
		@file = file
		@star = with oStar 12,0x66ff0088,0.5,0xffff0088
			.visible = false
			.position = oVec2 width-20,20
		@face\addChild @star

		@\slots "Tapped",->
			@\emit "Selected",@

		@\slots "Cleanup",->
			oCache.Texture\unload @_prevFile if @_prevFile

		thread ->
			@_loaded = true
			if not @_loaded
				name = file\match "([^\\/]*)%.[^%.\\/]*$"
				@face\addChild with CCLabelTTF "Broken\nBody\n"..name,"Arial",16
					.position = oVec2 width/2,height/2
					.texture.antiAlias = false
					.color = ccColor3 0x00ffff
					\perform oOpacity 0.3,1
				@face\removeChild @sprite
				@sprite = nil
				return
			world = with oWorld!
				.visible = false
			@\addChild world
			body = oBody file,world
			world\addChild body
			sleep!
			minX = nil
			minY = nil
			maxX = nil
			maxY = nil
			body\each (_,child)->
				return unless tolua.type(child) == "oBody"
				rc = child.boundingBox
				vs = {
					oVec2 rc.left,rc.bottom
					oVec2 rc.left,rc.up
					oVec2 rc.right,rc.up
					oVec2 rc.right,rc.bottom
				}
				for i,v in ipairs vs
					v = child\convertToWorldSpace v
					minX = v.x if not minX
					maxX = v.x if not maxX
					minY = v.y if not minY
					maxY = v.y if not maxY
					minX = v.x if v.x < minX
					maxX = v.x if v.x > maxX
					minY = v.y if v.y < minY
					maxY = v.y if v.y > maxY
			sizeW = maxX-minX
			sizeH = maxY-minY
			if sizeW == 0 and sizeH == 0
				name = file\match "([^\\/]*)%.[^%.\\/]*$"
				@face\addChild with CCLabelTTF "Empty\nBody\n"..name,"Arial",16
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
			world.scaleX = scale
			world.scaleY = scale
			world.position = oVec2 width/2,height/2
			renderTarget = CCRenderTarget width,height
			world.visible = true
			world.showDebug = true
			renderTarget\beginDraw!
			renderTarget\draw world
			renderTarget\endDraw!
			@\removeChild world
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
