local CCSize = require("CCSize")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local CCDirector = require("CCDirector")
local oSettingItem = require("oSettingItem")
local oSelectionPanel = require("oSelectionPanel")
local CCLabelTTF = require("CCLabelTTF")
local ccColor3 = require("ccColor3")
local CCDictionary = require("CCDictionary")
local oEvent = require("oEvent")
local oListener = require("oListener")
local oEditor = require("oEditor")
local tolua = require("tolua")
local oBodyDef = require("oBodyDef")
local CCTextAlign = require("CCTextAlign")
local CCUserDefault = require("CCUserDefault")
local ccBlendFunc = require("ccBlendFunc")
local CCRect = require("CCRect")
local CCArray = require("CCArray")

local function oSettingPanel()
	local winSize = CCDirector.winSize
	local borderSize = CCSize(240,winSize.height-20)
	local self = oSelectionPanel(borderSize,false,true,true)
	self.touchPriority = oEditor.touchPrioritySettingPanel
	local menu = self.menu
	menu.touchPriority = oEditor.touchPrioritySettingPanel+1
	local border = self.border
	local halfBW = borderSize.width*0.5
	local halfBH = borderSize.height*0.5
	local itemWidth = borderSize.width
	local itemHeight = 30
	local background = CCDrawNode()
	background:drawPolygon(
	{
		oVec2(-halfBW,-halfBH),
		oVec2(halfBW,-halfBH),
		oVec2(halfBW,halfBH),
		oVec2(-halfBW,halfBH)
	},ccColor4(0xe5100000),0.5,ccColor4(0x88ffafaf))
	border:addChild(background,-1)
	self.position = oVec2(winSize.width*0.5-halfBW-10,0)

	local label = CCLabelTTF("","Arial",16)
	label.position = oVec2(halfBW,borderSize.height-18)
	label.color = ccColor3(0x00ffff)
	menu:addChild(label)

	local function genPosY()
		local index = 0
		return function()
			local v = index
			index = index + 1
			return borderSize.height-30-itemHeight*v
		end
	end

	local itemNames =
	{
		"name",
		"maxParticles",
		"angle",
		"angleVar",
		"duration",
		"blendAdditive",
		"blendFuncSrc",
		"blendFuncDst",
		"startColor",
		"startRedVar",
		"startGreenVar",
		"startBlueVar",
		"startAlphaVar",
		"finishColor",
		"finishRedVar",
		"finishGreenVar",
		"finishBlueVar",
		"finishAlphaVar",
		"startSize",
		"startSizeVar",
		"finishSize",
		"finishSizeVar",
		"sourcePosition",
		"sourcePosXVar",
		"sourcePosYVar",
		"rotationStart",
		"rotationStartVar",
		"rotationEnd",
		"rotationEndVar",
		"lifeTime",
		"lifeTimeVar",
		"emissionRate",
		"textureFileName",
		"textureRect",
		"emitterType",
		"gravityX",
		"gravityY",
		"speed",
		"speedVar",
		"radialAccel",
		"radialAccelVar",
		"tangentAccel",
		"tangentAccelVar",
		"rotationIsDir",
		"startRadius",
		"startRadiusVar",
		"endRadius",
		"endRadiusVar",
		"angularSpeed",
		"angularSpeedVar",
		"interval",
	}

	local currentItem = nil
	local function editCallback(settingItem)
		if currentItem and settingItem.selected then
			currentItem.selected = false
		end
		currentItem = settingItem.selected and settingItem or nil
		oEvent:send("settingPanel.edit",settingItem)
	end
	local items = {}
	local getPosY = genPosY()
	for i = 1,#itemNames do
		local itemName = itemNames[i]
		local item = oSettingItem(itemName.." :",itemWidth,itemHeight,0,getPosY(),i == 1,editCallback)
		item.name = itemName
		items[itemName] = item
	end

	local function listen(itemName,name,getter,multi)
		if not getter and type(name) == "function" then
			getter = name
			name = itemName
		end
		local item = items[itemName]
		local listener = oListener(name,function(var)
			item.value = getter and getter(var) or var
		end)
		if multi then
			if tolua.type(item.data) ~= "CCArray" then item.data = CCArray() end
			item.data:add(listener)
		else
			item.data = listener
		end
	end

	local finishColorA = 0
	local finishColorR = 0
	local finishColorG = 0
	local finishColorB = 0
	local function shiftColor(v,bit)
		return math.floor(v*255+0.5)*math.pow(2,bit)
	end
	local function getFinishColorStr()
		return string.format("0x%.8X",finishColorA+finishColorR+finishColorG+finishColorB)
	end
	listen("finishColor","finishColorAlpha",function(a) finishColorA = shiftColor(a,24);return getFinishColorStr() end,true)
	listen("finishColor","finishColorRed",function(r) finishColorR = shiftColor(r,16);return getFinishColorStr() end,true)
	listen("finishColor","finishColorGreen",function(g) finishColorG = shiftColor(g,8);return getFinishColorStr() end,true)
	listen("finishColor","finishColorBlue",function(b) finishColorB = shiftColor(b,0);return getFinishColorStr() end,true)

	local startColorA = 0
	local startColorR = 0
	local startColorG = 0
	local startColorB = 0
	local function getStartColorStr()
		return string.format("0x%.8X",startColorA+startColorR+startColorG+startColorB)
	end
	listen("startColor","startColorAlpha",function(a) startColorA = shiftColor(a,24);return getStartColorStr() end,true)
	listen("startColor","startColorRed",function(r) startColorR = shiftColor(r,16);return getStartColorStr() end,true)
	listen("startColor","startColorGreen",function(g) startColorG = shiftColor(g,8);return getStartColorStr() end,true)
	listen("startColor","startColorBlue",function(b) startColorB = shiftColor(b,0);return getStartColorStr() end,true)

	local srcPosX = 0
	local srcPosY = 0
	local function getPosStr()
		return string.format("%.2f,%.2f",srcPosX,srcPosY)
	end
	listen("sourcePosition","sourcePositionx",function(posX) srcPosX = posX;return getPosStr() end,true)
	listen("sourcePosition","sourcePositiony",function(posY) srcPosY = posY;return getPosStr() end,true)

	local function getBlend(value)
		if value == ccBlendFunc.Dst then
			return "Dst"
		elseif value == ccBlendFunc.One then
			return "One"
		elseif value == ccBlendFunc.OneMinDst then
			return "OneMinDst"
		elseif value == ccBlendFunc.OneMinSrc then
			return "OneMinSrc"
		elseif value == ccBlendFunc.Src then
			return "Src"
		elseif value == ccBlendFunc.Zero then
			return "Zero"
		end
		return ""
	end
	listen("blendAdditive",function(var) return var == 0 and "No" or "Yes" end)
	listen("blendFuncSrc","blendFuncSource",function(var) return getBlend(var) end)
	listen("blendFuncDst","blendFuncDestination",function(var) return getBlend(var) end)
	listen("duration",function(var) return var < 0 and "Infinite" or var end)
	listen("angleVar","angleVariance")
	listen("startSize","startParticleSize")
	listen("startSizeVar","startParticleSizeVariance")
	listen("finishSize","finishParticleSize")
	listen("finishSizeVar","finishParticleSizeVariance")
	listen("sourcePosXVar","sourcePositionVariancex")
	listen("sourcePosYVar","sourcePositionVariancey")
	listen("rotationStartVar","rotationStartVariance")
	listen("rotationEndVar","rotationEndVariance")
	listen("lifeTime","particleLifespan")
	listen("lifeTimeVar","particleLifespanVariance")
	listen("startRadius","maxRadius")
	listen("startRadiusVar","maxRadiusVariance")
	listen("endRadius","minRadius")
	listen("endRadiusVar","minRadiusVariance")
	listen("angularSpeed","rotatePerSecond")
	listen("angularSpeedVar","rotatePerSecondVariance")
	listen("speedVar","speedVariance")
	listen("radialAccel","radialAcceleration")
	listen("radialAccelVar","radialAccelVariance")
	local rc = CCRect()
	local function getRectStr()
		return rc == CCRect.zero and "Full" or string.format("%d,%d,%d,%d",rc.origin.x,rc.origin.y,rc.size.width,rc.size.height)
	end
	listen("textureRect","textureRectx",function(x) rc.origin = oVec2(x,rc.origin.y);return getRectStr() end,true)
	listen("textureRect","textureRecty",function(y) rc.origin = oVec2(rc.origin.x,y);return getRectStr() end,true)
	listen("textureRect","textureRectw",function(w) rc.size = CCSize(w,rc.size.height);return getRectStr() end,true)
	listen("textureRect","textureRecth",function(h) rc.size = CCSize(rc.size.width,h);return getRectStr() end,true)

	local modeGravity =
	{
		items.name,
		items.maxParticles,
		items.angle,
		items.angleVar,
		items.duration,
		items.blendAdditive,
		items.blendFuncSrc,
		items.blendFuncDst,
		items.startColor,
		items.startColorRVar,
		items.startColorGVar,
		items.startColorBVar,
		items.startColorAVar,
		items.finishColor,
		items.finishColorRVar,
		items.finishColorGVar,
		items.finishColorBVar,
		items.finishColorAVar,
		items.startSize,
		items.startSizeVar,
		items.finishSize,
		items.finishSizeVar,
		items.sourcePosition,
		items.sourcePosXVar,
		items.sourcePosYVar,
		items.rotationStart,
		items.rotationStartVar,
		items.rotationEnd,
		items.rotationEndVar,
		items.lifeTime,
		items.lifeTimeVar,
		items.emissionRate,
		items.textureFileName,
		items.textureRect,
		items.emitterType,
		items.gravityx,
		items.gravityy,
		items.speed,
		items.speedVar,
		items.radialAccel,
		items.radialAccelVar,
		items.tangentialAccel,
		items.tangentialAccelVar,
	}

	local modeRadius =
	{
		items.name,
		items.maxParticles,
		items.angle,
		items.angleVar,
		items.duration,
		items.blendAdditive,
		items.blendFuncSrc,
		items.blendFuncDst,
		items.startColor,
		items.startColorRVar,
		items.startColorGVar,
		items.startColorBVar,
		items.startColorAVar,
		items.finishColor,
		items.finishColorRVar,
		items.finishColorGVar,
		items.finishColorBVar,
		items.finishColorAVar,
		items.startSize,
		items.startSizeVar,
		items.finishSize,
		items.finishSizeVar,
		items.sourcePosition,
		items.sourcePosXVar,
		items.sourcePosYVar,
		items.rotationStart,
		items.rotationStartVar,
		items.rotationEnd,
		items.rotationEndVar,
		items.lifeTime,
		items.lifeTimeVar,
		items.emissionRate,
		items.textureFileName,
		items.textureRect,
		items.emitterType,
		items.startRadius,
		items.startRadiusVar,
		items.endRadius,
		items.endRadiusVar,
		items.angularSpeed,
		items.angularSpeedVar,
	}

	local modeFrame =
	{
		items.name,
		items.interval
	}

	for _,item in pairs(items) do
		item.visible = false
		menu:addChild(item)
	end

	local currentGroup = nil
	local function setGroup(group)
		if group == currentGroup then return end
		currentGroup = group
		for _,item in pairs(items) do
			item.visible = false
		end
		local contentHeight = 40
		local getPosY = genPosY()
		for _,item in pairs(group) do
			item.positionY = getPosY()
			item.visible = true
			contentHeight = contentHeight + itemHeight
		end
		if group == modeFrame then
			label.text = "Frame"
			label.texture.antiAlias = false
		else
			label.text = "Particle"
			label.texture.antiAlias = false
		end
		self:reset(borderSize.width,contentHeight,0,50)
	end
	
	listen("emitterType",function(var)
		if var == oEditor.EmitterGravity then
			setGroup(modeGravity)
			return "Gravity"
		elseif var == oEditor.EmitterRadius then
			setGroup(modeRadius)
			return "Radius"
		end
	end)

	listen("interval",function(var)
		setGroup(modeFrame)
		return var
	end)

	for itemName,item in pairs(items) do
		if not item.data then
			item.data = oListener(itemName,function(value)
				item.value = value
			end)
		end
	end

	return self
end

return oSettingPanel
