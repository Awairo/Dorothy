Dorothy!
Class,property,classfield = unpack require "class"
EditMenuView = require "View.Control.Operation.EditMenu"

Class
	__partial: => EditMenuView!
	__init: =>
		spriteSelected = false
		modelSelected = false
		bodySelected = false
		effectSelected = false
		clearSelection = ->
			if spriteSelected
				spriteSelected = false
				@spriteBtn.color = ccColor3 0x00ffff
				emit "Scene.SpriteSelected",nil
			if modelSelected
				modelSelected = false
				@modelBtn.color = ccColor3 0x00ffff
				emit "Scene.ModelSelected",nil
			if bodySelected
				bodySelected = false
				@bodyBtn.color = ccColor3 0x00ffff
				emit "Scene.BodySelected",nil
			if effectSelected
				effectSelected = false
				@effectBtn.color = ccColor3 0x00ffff
				emit "Scene.EffectSelected",nil

		@spriteBtn\slots "Tapped",->
			emit "Scene.ViewSprite" unless spriteSelected
			clearSelection!
		@modelBtn\slots "Tapped",->
			emit "Scene.ViewModel" unless modelSelected
			clearSelection!
		@bodyBtn\slots "Tapped",->
			emit "Scene.ViewBody" unless bodySelected
			clearSelection!
		@effectBtn\slots "Tapped",->
			emit "Scene.ViewEffect" unless effectSelected
			clearSelection!

		@gslot "Scene.SpriteSelected",(item)->
			if item
				spriteSelected = true
				@spriteBtn.color = ccColor3 0xff0088
		@gslot "Scene.ModelSelected",(item)->
			if item
				modelSelected = true
				@modelBtn.color = ccColor3 0xff0088
		@gslot "Scene.BodySelected",(item)->
			if item
				bodySelected = true
				@bodyBtn.color = ccColor3 0xff0088
		@gslot "Scene.EffectSelected",(item)->
			if item
				effectSelected = true
				@effectBtn.color = ccColor3 0xff0088
