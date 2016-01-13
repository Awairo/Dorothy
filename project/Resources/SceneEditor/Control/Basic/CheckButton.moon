Dorothy!
Button = require "Control.Basic.Button"

-- [signals]
-- "Tapped",(button)->
-- [params]
-- x, y, width, height, fontSize, text
Class Button,
	__init: =>
		@_checked = false
		@slot("TapEnded")\set ->
			@_checked = not @_checked
			if not @_checked
				if not @fade.done
					@face\stopAction @fade
				@face\runAction @fade
			@emit "Checked",@_checked

	checked: property => @_checked,
		(value)=>
			return if @_checked == value
			@_checked = value
			if value
				@face\perform @scale
			else
				@face\perform @scale
				if not @fade.done
					@face\stopAction @fade
				@face\runAction @fade
			@emit "Checked",value
