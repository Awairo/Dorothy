local CCDirector = require("CCDirector")
local oLine = require("oLine")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local CCLayerColor = require("CCLayerColor")
local CCDictionary = require("CCDictionary")
local oScale = require("oScale")
local oEase = require("oEase")
local oOpacity = require("oOpacity")
local CCTouch = require("CCTouch")
local CCRect = require("CCRect")
local CCLabelTTF = require("CCLabelTTF")
local oPos = require("oPos")
local CCSequence = require("CCSequence")
local CCCall = require("CCCall")
local once = require("once")
local oEditor = require("oEditor")

local function oVRuler()
	local winSize = CCDirector.winSize
	local center = oVec2(winSize.width*0.5,winSize.height*0.5)
	local rulerWidth = 30
	local rulerHeight = winSize.height
	local self = CCLayerColor(ccColor4(0),rulerWidth,rulerHeight)
	local halfW = rulerWidth*0.5
	local halfH = rulerHeight*0.5
	local origin = oEditor.origin+center

	self.cascadeOpacity = true
	self.opacity = 0.3
	self.position = oVec2(winSize.width-200-halfW,halfH)

	-- borders --
	local border = oLine(
	{
		oVec2(rulerWidth,rulerHeight),
		oVec2(rulerWidth,0)
	},ccColor4())
	self:addChild(border)

	-- init interval --
	local intervalNode = oLine()
	local nPart = 0
	local nCurrentPart = 0
	local pPart = 0
	local pCurrentPart = 0
	local vs = {}
	local function updatePart(nLength,pLength)
		if nLength <= nPart and pLength <= pPart then
			return
		end
		if nLength > nPart then
			nPart = math.ceil(nLength/10)*10
		end
		if pLength > pPart then
			pPart = math.ceil(pLength/10)*10
		end
	end

	-- worker thread for intervals creation --
	self:schedule(once(function()
		repeat
			if nCurrentPart < nPart or pCurrentPart < pPart then
				local start = math.floor(nCurrentPart/10)
				local count = math.floor(nPart/10)
				local length = #vs
				if start < count then
					for i = start,count do
						local posY = i*10
						table.insert(vs,oVec2(-halfW,posY))
						table.insert(vs,oVec2(-halfW+(i%10 == 0 and 8 or 4),posY))
						table.insert(vs,oVec2(-halfW,posY))
						if i%10 == 0 then
							local label = CCLabelTTF(tostring(i*10),"Arial",10)
							label.texture.antiAlias = false
							label.scaleX = 1/self.scaleY
							label.angle = -90
							label.position = oVec2(-halfW+18,posY)
							intervalNode:addChild(label)
							coroutine.yield()
						end
						nCurrentPart = nCurrentPart + 10
					end
				end
				start = math.floor(pCurrentPart/10)
				count = math.floor(pPart/10)
				if start < count then
					for i = start,count do
						if i ~= 0 then
							local posY = -i*10
							table.insert(vs,1,oVec2(-halfW,posY))
							table.insert(vs,1,oVec2(-halfW+(i%10 == 0 and 8 or 4),posY))
							table.insert(vs,1,oVec2(-halfW,posY))
							if i%10 == 0 then
								local label = CCLabelTTF(tostring(-i*10),"Arial",10)
								label.texture.antiAlias = false
								label.scaleX = 1/self.scaleY
								label.angle = -90
								label.position = oVec2(-halfW+18,posY)
								intervalNode:addChild(label)
								coroutine.yield()
							end
						end
						pCurrentPart = pCurrentPart + 10
					end
				end
				if #vs ~= length then
					intervalNode:set(vs)
				end
			end
			coroutine.yield()
		until false
	end))

	-- set default interval negtive & positive part length --
	updatePart(origin.y, winSize.height-origin.y)
	intervalNode.position = oVec2(halfW,origin.y)
	self:addChild(intervalNode)

	-- listen view move event --
	intervalNode:slot("viewArea.move",function(delta)
		intervalNode.positionY = intervalNode.positionY + delta.y/self.scaleY
		updatePart(delta.y < 0 and winSize.height-intervalNode.positionY or 0,
			delta.y > 0 and intervalNode.positionY or 0)
	end)
	intervalNode:slot("viewArea.toPos",function(pos)
		pos = pos + center
		intervalNode:runAction(oPos(0.5,halfW,pos.y,oEase.OutQuad))
		updatePart(winSize.height-pos.y,pos.y)
	end)

	-- listen view scale event --
	local function updateIntervalTextScale(scale)
		local children = intervalNode.children
		for i = 1, children.count do
			children[i].scaleX = scale
		end
	end
	local fadeOut = CCSequence({oOpacity(0.3,0),CCCall(function()
		self.scaleY = 1
		updateIntervalTextScale(1)
	end)})
	local fadeIn = oOpacity(0.3,0.3)
	self:slot("viewArea.scale",function(scale)
		if scale < 1.0 and self.opacity > 0 and fadeOut.done then
			self.touchEnabled = false
			self:stopAllActions()
			self:runAction(fadeOut)
		elseif scale >= 1.0 then
			if self.opacity == 0 and fadeIn.done then
				self.touchEnabled = true
				self:stopAllActions()
				self:runAction(fadeIn)
			end
			self.scaleY = scale
			-- unscale interval text --
			updateIntervalTextScale(1/scale)
		end
	end)
	self:slot("viewArea.toScale",function(scale)
		if scale < 1.0 and self.opacity > 0 and fadeOut.done then
			self.touchEnabled = false
			self:stopAllActions()
			self:runAction(fadeOut)
		elseif scale >= 1.0 and self.opacity == 0 and fadeIn.done then
			self.touchEnabled = true
			self:stopAllActions()
			self:runAction(fadeIn)
		end
		if scale >= 1.0 then
			self:runAction(oScale(0.5,1,scale,oEase.OutQuad))
			-- manually update and unscale interval text --
			local time = 0
			intervalNode:schedule(function(deltaTime)
				updateIntervalTextScale(1/self.scaleY)
				time = time + deltaTime
				if math.min(time/0.5,1) == 1 then
					intervalNode:unschedule()
				end
			end)
		end
	end)

	-- handle touch event --
	self.touchPriority = oEditor.touchPriorityVRuler
	self.swallowTouches = true
	self.touchEnabled = true
	self.touchHandler = function(eventType,touch)
		if eventType == CCTouch.Began then -- check touch area
			local loc = self:convertToNodeSpace(touch.location)
			return CCRect(-halfW,-halfH,rulerWidth,rulerHeight):containsPoint(loc)
		elseif eventType == CCTouch.Moved then -- move up and down
			self.positionX = self.positionX + touch.delta.x
			if self.positionX > winSize.width-190-halfW then
				self.positionX = winSize.width-190-halfW
			elseif self.positionX < halfW then
				self.positionX = halfW
			end
		end
		return true
	end

	return self
end

return oVRuler