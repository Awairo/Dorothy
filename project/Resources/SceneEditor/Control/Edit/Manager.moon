Dorothy!
Class = unpack require "class"
Button = require "Control.Basic.Button"
SelectionPanel = require "Control.Basic.SelectionPanel"
GroupChooser = require "Control.Edit.GroupChooser"
GroupPanel = require "Control.Edit.GroupPanel"
ContactPanel = require "Control.Edit.ContactPanel"
import Simulation from require "Data.Model"

Class => CCNode!,
	__init:=>
		{:width,:height} = CCDirector.winSize
		_stopEditing = nil
		stopEditing = -> _stopEditing! if _stopEditing
		cancelEditing = -> emit "Scene.SettingPanel.Edit",nil

		@schedule once ->
			sleep 0.1
			Ruler = require "Control.Edit.Ruler"
			@ruler = Ruler {
				x:(width-330)/2+70
				y:100
				width:width-340
				height:60
			}
			@addChild @ruler
		showRuler = (...)->
			@ruler\show ...
			_stopEditing = ->
				_stopEditing = nil
				@ruler\hide!

		@boolSwitcher = with CCMenu!
			.visible = false
			.position = oVec2 width-225,95
			.contentSize = CCSize 50,50
			.touchPriority = editor.levelEditMenu
			switcher = with Button {
					text:"True"
					x:25
					y:25
					width:50
					height:50
					fontSize:18
				}
				.value = true
				\slots "Tapped",-> @boolSwitcher\setValue not .value
			\addChild switcher
			.setValue = (value)=>
				switcher.value = value
				switcher.text = value and "True" or "False"
				switcher.color = ccColor3 value and 0x00ffff or 0xff0088
				\emit "Changed",value
		@addChild @boolSwitcher
		showSwitcher = (default,callback)->
			with @boolSwitcher
				\setValue default
				\slots("Changed")\set callback
				.visible = true
				.scaleX = 0
				.scaleY = 0
				\perform oScale 0.3,1,1,oEase.OutBack
			_stopEditing = ->
				_stopEditing = nil
				with @boolSwitcher
					\slots "Changed",nil
					\perform CCSequence {
						oScale 0.3,0,0,oEase.InBack
						CCHide!
					}

		round = (value)-> value > 0 and math.floor(value+0.5) or math.ceil(value-0.5)
		deltaPos = oVec2.zero
		posChanged = nil
		posVisual = with CCNode!
			\addChild oLine {
					oVec2 0,150
					oVec2 -20,150
					oVec2 0,190
					oVec2 20,150
					oVec2 0,150
					oVec2.zero
				},ccColor4!
			\addChild oLine {
					oVec2.zero
					oVec2 150,0
					oVec2 150,20
					oVec2 190,0
					oVec2 150,-20
					oVec2 150,0
				},ccColor4!
			\gslot "Scene.FixChange",->
				posVisual.children[1].visible = not editor.yFix
				posVisual.children[2].visible = not editor.xFix
		posEditor = with CCLayer!
			.visible = false
			.swallowTouches = true
			.touchPriority = editor.levelEditControl
			\addChild posVisual
			\slots "TouchMoved",(touch)->
				delta = touch.delta
				delta.x = 0 if editor.xFix
				delta.y = 0 if editor.yFix
				if editor.isFixed
					deltaPos += delta/editor.scale
					if 1 < math.abs deltaPos.x
						posVisual.positionX = round posVisual.positionX + deltaPos.x
						deltaPos.x = 0
					if 1 < math.abs deltaPos.y
						posVisual.positionY = round posVisual.positionY + deltaPos.y
						deltaPos.y = 0
				else
					posVisual.position += delta/editor.scale
				if posChanged
					posChanged posVisual.position
		@addChild posEditor
		showPosEditor = (pos,target,callback)->
			emit "Scene.ShowFix",true
			posChanged = callback
			with posEditor
				.visible = true
				.touchEnabled = true
			with posVisual
				.transformTarget = target
				.scaleX = 1/target.scaleX
				.scaleY = 1/target.scaleY
				.position = pos
			deltaPos = oVec2.zero
			_stopEditing = ->
				return unless posEditor.visible
				emit "Scene.ShowFix",false
				posEditor.touchEnabled = false
				posEditor.visible = false

		rotVisual = with CCNode!
			newP = (i)->
				a = 2*math.pi*i/40
				oVec2 200*math.cos(a),200*math.sin(a)
			\addChild oLine [newP i for i = 0,40],ccColor4!
			\addChild oLine {oVec2(-200,0),oVec2(200,0)},ccColor4!
			\addChild oLine {oVec2(0,-200),oVec2(0,200)},ccColor4!
		totalRot = 0
		rotChanged = nil
		rotEditor = with CCLayer!
			.visible = false
			.swallowTouches = true
			.touchPriority = editor.levelEditControl
			\addChild rotVisual
			\slots "TouchMoved",(touch)->
				oldPos = rotVisual\convertToNodeSpace touch.preLocation
				newPos = rotVisual\convertToNodeSpace touch.location
				v1 = oVec2.zero-oldPos
				v2 = oVec2.zero-newPos
				len1 = v1.length
				len2 = v2.length
				if len1 ~= 0 and len2 ~= 0
					res = (v1.x*v2.x+v1.y*v2.y)/(len1*len2)
					res = math.min res,1
					res = math.max res,-1
					s = oldPos.x*newPos.y-oldPos.y*newPos.x
					delta = (s > 0 and -1 or 1)*math.acos(res)*180/math.pi/editor.scale
					if editor.isFixed
						totalRot = totalRot + delta
						if totalRot < 1 and totalRot > -1
							delta = 0
						else
							delta = totalRot > 0 and math.floor(totalRot) or math.ceil(totalRot)
							totalRot = 0
							angle = rotVisual.angle + delta
							angle = angle > 0 and math.floor(angle) or math.ceil(angle)
							rotVisual.angle = angle
					else
						rotVisual.angle = rotVisual.angle + delta
					if rotChanged
						rotChanged rotVisual.angle
		@addChild rotEditor
		showRotEditor = (pos,angle,target,callback)->
			rotChanged = callback
			totalRot = 0
			rotEditor.visible = true
			rotEditor.touchEnabled = true
			with rotVisual
				.transformTarget = target
				.scaleX = 1/target.scaleX
				.scaleY = 1/target.scaleY
				.position = pos
				.angle = angle
			_stopEditing = ->
				return unless rotEditor.visible
				rotEditor.touchEnabled = false
				rotEditor.visible = false

		scaleVisual = with CCNode!
			.visible = false
			\addChild oLine {
					oVec2 0,150
					oVec2 -20,150
					oVec2 -20,190
					oVec2 20,190
					oVec2 20,150
					oVec2 0,150
					oVec2.zero
				},ccColor4!
			\addChild oLine {
					oVec2.zero
					oVec2 150,0
					oVec2 150,20
					oVec2 190,20
					oVec2 190,-20
					oVec2 150,-20
					oVec2 150,0
				},ccColor4!
			\gslot "Scene.FixChange",->
				scaleVisual.children[1].visible = not editor.yFix
				scaleVisual.children[2].visible = not editor.xFix
		deltaScaleX = 0
		deltaScaleY = 0
		totalScale = oVec2.zero
		scaleChanged = nil
		scaleEditor = with CCLayer!
			.visible = false
			.touchPriority = editor.levelEditControl
			.swallowTouches = true
			\addChild scaleVisual
			\slots "TouchMoved",(touch)->
				delta = scaleVisual\convertToNodeSpace(touch.location) - 
					scaleVisual\convertToNodeSpace(touch.preLocation)
				if delta ~= oVec2.zero
					delta = delta*editor.scale
					delta.x = 0 if editor.xFix
					delta.y = 0 if editor.yFix
					if editor.isFixed
						deltaScaleX += delta.x
						deltaScaleY += delta.y
						if deltaScaleX > 1 or deltaScaleX < -1
							totalScale.x = round totalScale.x+deltaScaleX
							deltaScaleX = 0
						if deltaScaleY > 1 or deltaScaleY < -1
							totalScale.y = round totalScale.y+deltaScaleY
							deltaScaleY = 0
					else
						totalScale.x += delta.x
						totalScale.y += delta.y
					if scaleChanged
						scaleChanged totalScale/100
		@addChild scaleEditor
		showScaleEditor = (pos,angle,scale,target,callback)->
			emit "Scene.ShowFix",true
			totalScale = scale*100
			scaleChanged = callback
			scaleEditor.visible = true
			scaleEditor.touchEnabled = true
			with scaleVisual
				.visible = true
				.transformTarget = target
				.scaleX = 1/target.scaleX
				.scaleY = 1/target.scaleY
				.position = pos
				.angle = angle
			deltaScaleX = 0
			deltaScaleY = 0
			_stopEditing = ->
				return unless scaleEditor.visible
				emit "Scene.ShowFix",false
				scaleVisual.visible = false
				scaleEditor.touchEnabled = false
				scaleEditor.visible = false

		skewVisual = with CCNode!
			.visible = false
			\addChild oLine {
					oVec2 -20,100
					oVec2 0,140
					oVec2 20,100
					oVec2 0,140
					oVec2 0,-140
					oVec2 -20,-100
					oVec2 0,-140
					oVec2 20,-100
				},ccColor4!
			\addChild oLine {
					oVec2 100,20
					oVec2 140,0
					oVec2 100,-20
					oVec2 140,0
					oVec2 -140,0
					oVec2 -100,20
					oVec2 -140,0
					oVec2 -100,-20
				},ccColor4!
			\gslot "Scene.FixChange",->
				skewVisual.children[1].visible = not editor.yFix
				skewVisual.children[2].visible = not editor.xFix
		scaleEditor\addChild skewVisual
		showSkewEditor = (pos,angle,scale,target,callback)->
			showScaleEditor pos,angle,scale,target,callback
			scaleVisual.visible = false
			with skewVisual
				.visible = true
				.transformTarget = target
				.scaleX = 1/target.scaleX
				.scaleY = 1/target.scaleY
				.position = pos
				.angle = angle
			stopHandler = _stopEditing
			_stopEditing = ->
				stopHandler!
				skewVisual.visible = false

		@gslot "Scene.ViewPanel.Select",cancelEditing

		@gslot "Scene.SettingPanel.Edit",(menuItem)->
			if menuItem and menuItem.selected and editor.currentData
				data = editor.currentData
				item = editor\getItem data
				switch menuItem.name
					when "name"
						menuItem\slots("TextChanged")\set (value)->
							menuItem\slots "TextChanged",nil
							value = editor\renameData data,value
							return unless value
							menuItem.value = value
							emit "Scene.ViewPanel.NameChange",data
					when "file"
						emit "Editor.ItemChooser",{data.typeName,(itemChooser)->
							if not itemChooser
								cancelEditing!
								return
							editor\addChild itemChooser,editor.topMost
							itemChooser\show!
							itemChooser\slots("Selected")\set (filename)->
								data.file = filename
								editor\resetData data
								menuItem.value = filename\match "[^\\/]*$"
							itemChooser\slots "Hide",cancelEditing
						}
					when "outline","loop","visible","faceRight","play"
						showSwitcher data[menuItem.name],(value)->
							data[menuItem.name] = value
							menuItem.value = value
							switch menuItem.name
								when "outline"
									item.showDebug = value
								when "loop"
									item.loop = value
									item\play data.animation
								when "visible"
									item.visible = value and data.display
								when "faceRight"
									item.faceRight = value
								when "play"
									if value
										item\start!
									else
										item\stop!
					when "ratioX","ratioY"
						default = data[menuItem.name]
						valueChanged = (value)->
							data[menuItem.name] = value
							menuItem.value = value
						start,stop,interval = if data.typeName == "Camera"
							0,1,0.1
						else
							-10,10,1
						showRuler default,start,stop,interval,valueChanged
					when "speed"
						showRuler data[menuItem.name],0,10,1,(value)->
							data[menuItem.name] = value
							menuItem.value = value
							item.speed = value
					when "look"
						file = data.file
						looks = oCache.Model\getLookNames file
						table.insert looks,1,"None"
						with SelectionPanel items:looks
							\slots "Selected",(value)->
								data[menuItem.name] = (value == "None" and "" or value)
								menuItem.value = value
								item.look = value
								cancelEditing!
					when "animation"
						file = data.file
						looks = oCache.Model\getAnimationNames file
						table.insert looks,1,"None"
						with SelectionPanel items:looks
							\slots "Selected",(value)->
								data[menuItem.name] = (value == "None" and "" or value)
								menuItem.value = value
								item\play value
								cancelEditing!
					when "group"
						groupChooser = with GroupChooser!
							\slots "Hide",cancelEditing
							\slots "Selected",(group)->
								data[menuItem.name] = group
								menuItem.value = editor.sceneData.groups[group]
								groupChooser\hide!
					when "effect"
						emit "Editor.ItemChooser",{"Effect",(itemChooser)->
							if not itemChooser
								cancelEditing!
								return
							editor\addChild itemChooser,editor.topMost
							itemChooser\show!
							itemChooser\slots("Selected")\set (effectName)->
								data.effect = effectName
								editor\resetData data
								menuItem.value = effectName
							itemChooser\slots "Hide",cancelEditing
						}
					when "offset"
						startPos = editor.origin
						showPosEditor startPos,editor.viewArea,(value)->
							delta = value-startPos
							startPos = value
							data[menuItem.name] += delta
							offset = data[menuItem.name]
							menuItem.value = offset
							switch data.typeName
								when "Layer"
									item.parent.parent\setLayerOffset item.zOrder,offset
								when "World"
									item.parent.parent.parent\setLayerOffset item.parent.zOrder,offset
					when "position"
						showPosEditor data.position,item.parent,(value)->
							menuItem.value = value
							switch data.typeName
								when "Effect"
									item\setOffset value
								when "Body"
									delta = value - data.position
									item\eachChild (child)-> child.position += delta
								else
									item.position = value
							data.position = value
					when "simulation"
						with SelectionPanel items:{"Low","Medium","High"}
							\slots "Selected",(value,index)->
								data.simulation = index
								menuItem.value = value
								item\setIterations Simulation index
								cancelEditing!
					when "zoom"
						showRuler data.zoom,0.5,10,1,(value)->
							data.zoom = value
							menuItem.value = value
							item.scaleX = value
							item.scaleY = value
					when"scale"
						showScaleEditor data.position,
							data.angle,
							data.scale,
							item.parent,(value)->
								menuItem.value = value
								item.scaleX = value.x
								item.scaleY = value.y
								data.scale = value
					when "angle"
						showRotEditor data.position,data.angle,item.parent,(value)->
							menuItem.value = value
							item.angle = value
							data.angle = value
					when "skew"
						showSkewEditor data.position,
							data.angle,
							data.skew/10,
							item.parent,(value)->
								value *= 10
								menuItem.value = value
								item.skewX = value.x
								item.skewY = value.y
								data.skew = value
					when "groups"
						with GroupPanel!
							\slots "Hide",-> cancelEditing!
					when "contacts"
						groupChooser = with GroupChooser!
							\slots "Hide",-> cancelEditing!
							\slots "Selected",(group)->
								groupChooser\slots "Hide",nil
								groupChooser\hide!
								with ContactPanel group:group
									\slots "Hide",-> cancelEditing!
					when "gravity"
						showRuler data.gravity,-50,50,10,(value)->
							data.gravity = value
							menuItem.value = value
							item.gravity = oVec2 0,value
					when "opacity"
						print 1
			else
				stopEditing!
