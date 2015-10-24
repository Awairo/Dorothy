CCDirector = require "CCDirector"
oLine = require "oLine"
oVec2 = require "oVec2"
ccColor4 = require "ccColor4"
CCLayerColor = require "CCLayerColor"
oScale = require "oScale"
oEase = require "oEase"
oOpacity = require "oOpacity"
CCRect = require "CCRect"
CCLabelTTF = require "CCLabelTTF"
oPos = require "oPos"
CCSequence = require "CCSequence"
CCCall = require "CCCall"
once = require "once"
oRoutine = require "oRoutine"
cycle = require "cycle"

->
	winSize = CCDirector.winSize
	center = oVec2 winSize.width*0.5,winSize.height*0.5
	rulerWidth = 30
	rulerHeight = winSize.height
	halfW = rulerWidth*0.5
	halfH = rulerHeight*0.5
	origin = editor.origin
	@ = with CCLayerColor ccColor4(0),rulerWidth,rulerHeight
		.cascadeOpacity = true
		.opacity = 0.3
		.position = oVec2 winSize.width-200-halfW,halfH
		.touchPriority = editor.levelVRuler
		.swallowTouches = true
		.touchEnabled = true
		\addChild oLine {
			oVec2 rulerWidth,rulerHeight
			oVec2 rulerWidth,0
		},ccColor4!

	-- init interval --
	intervalNode = with oLine!
		.position = oVec2 halfW,origin.y
	@addChild intervalNode

	nPart = 0
	nCurrentPart = 0
	pPart = 0
	pCurrentPart = 0
	vs = {}
	updatePart = (nLength,pLength)->
		nLength += 10
		pLength += 10
		if nLength <= nPart and pLength <= pPart
			return
		if nLength > nPart
			nPart = math.ceil(nLength/10)*10
		if pLength > pPart then
			pPart = math.ceil(pLength/10)*10

	rightOffset = (rulerHeight-origin.y)+100
	leftOffset = -origin.y-100

	labels = {}
	labelList = {}
	setupLabels = ->
		right = math.floor rightOffset/100
		left = math.ceil leftOffset/100
		for i = left,right
			pos = i*100
			label = with CCLabelTTF tostring(pos),"Arial",10
				.texture.antiAlias = false
				.scaleX = 1/@scaleY
				.angle = -90
				.position = oVec2 -halfW+18,pos
			intervalNode\addChild label
			labels[pos] = label
			table.insert labelList,label

	moveLabel = (label,pos)->
		labels[tonumber(label.text)] = nil
		labels[pos] = with label
			.text = tostring pos
			.texture.antiAlias = false
			.scaleX = 1/@scaleY
			.angle = -90
			.position = oVec2 -halfW+18,pos

	updateLabels = ->
		right = math.floor (rightOffset-(intervalNode.positionY-origin.y))/100
		left = math.ceil (leftOffset-(intervalNode.positionY-origin.y))/100
		insertPos = 1
		for i = left,right
			pos = i*100
			if labels[pos]
				break
			else
				label = table.remove labelList
				table.insert labelList,insertPos,label
				insertPos += 1
				moveLabel label,pos
		for i = right,left,-1
			pos = i*100
			if labels[pos]
				break
			else
				label = table.remove labelList,1
				table.insert labelList,label
				moveLabel label,pos
		if nCurrentPart < nPart or pCurrentPart < pPart
			start = math.floor nCurrentPart/10
			count = math.floor nPart/10
			length = #vs
			if start < count
				for i = start,count
					posY = i*10
					table.insert vs,oVec2(-halfW,posY)
					table.insert vs,oVec2(-halfW+(i%10 == 0 and 8 or 4),posY)
					table.insert vs,oVec2(-halfW,posY)
					nCurrentPart += 10
			start = math.floor pCurrentPart/10
			count = math.floor pPart/10
			if start < count
				for i = start,count
					if i ~= 0
						posY = -i*10
						table.insert vs,1,oVec2(-halfW,posY)
						table.insert vs,1,oVec2(-halfW+(i%10 == 0 and 8 or 4),posY)
						table.insert vs,1,oVec2(-halfW,posY)
					pCurrentPart += 10
			if #vs ~= length
				intervalNode\set vs

	-- set default interval negtive & positive part length --
	setupLabels!
	updatePart origin.y, winSize.height-origin.y
	updateLabels!

	-- listen view move event --
	@gslot "Scene.ViewArea.Move",(delta)->
		intervalNode.positionY += delta.y/@scaleY
		updatePart delta.y < 0 and winSize.height-intervalNode.positionY or 0,
			delta.y > 0 and intervalNode.positionY or 0
		updateLabels!

	@gslot "Scene.ViewArea.MoveTo",(pos)->
		pos += center
		intervalNode\runAction oPos 0.5,halfW,pos.y,oEase.OutQuad
		oRoutine once -> cycle 0.5,-> updateLabels!
		updatePart winSize.height-pos.y,pos.y

	-- listen view scale event --
	updateIntervalTextScale = (scale)->
		intervalNode\eachChild (child)->
			child.scaleX = scale

	fadeOut = CCSequence {
		oOpacity 0.3,0
		CCCall ->
			@scaleY = 1
			updateIntervalTextScale 1
	}
	fadeIn = oOpacity 0.3,0.3
	@gslot "Scene.ViewArea.Scale",(scale)->
		if scale < 1.0 and @opacity > 0 and fadeOut.done
			@touchEnabled = false
			@perform fadeOut
		elseif scale >= 1.0
			if @opacity == 0 and fadeIn.done
				@touchEnabled = true
				@perform fadeIn
			@scaleY = scale
			-- unscale interval text --
			updateIntervalTextScale 1/scale

	@gslot "Scene.ViewArea.ScaleTo",(scale)->
		if scale < 1.0 and self.opacity > 0 and fadeOut.done
			@touchEnabled = false
			@perform fadeOut
		elseif scale >= 1.0 and @opacity == 0 and fadeIn.done
			@touchEnabled = true
			@perform fadeIn
		if scale >= 1.0
			@runAction oScale 0.5,1,scale,oEase.OutQuad
			-- manually update and unscale interval text --
			time = 0
			intervalNode\schedule (deltaTime)->
				updateIntervalTextScale 1/@scaleY
				time = time + deltaTime
				if 1 == math.min time/0.5,1
					intervalNode\unschedule!

	-- handle touch event --
	@slots "TouchBegan",(touch)->
		loc = @convertToNodeSpace touch.location
		CCRect(-halfW,-halfH,rulerWidth,rulerHeight)\containsPoint loc

	@slots "TouchMoved",(touch)->
		@positionX += touch.delta.x
		if @positionX > winSize.width-190-halfW-10
			@positionX = winSize.width-190-halfW-10
		elseif @positionX < halfW+10
			@positionX = halfW+10

	@
