local require = using("EffectEditor.Script")
local CCDirector = require("CCDirector")
local ccColor4 = require("ccColor4")
local oVec2 = require("oVec2")
local CCDrawNode = require("CCDrawNode")
local CCSize = require("CCSize")
local oSelectionPanel = require("oSelectionPanel")
local oEditor = require("oEditor")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local oPos = require("oPos")
local oEase = require("oEase")
local CCHide = require("CCHide")
local CCSprite = require("CCSprite")
local oLine = require("oLine")

local function oClipViewer(file,rect)
	local width = 130
	local sprite = CCSprite(file)
	sprite.textureRect = rect
	local contentSize = sprite.contentSize
	if contentSize.width > width or contentSize.height > width then
		local scale = contentSize.width > contentSize.height and (width-2)/contentSize.width or (width-2)/contentSize.height
		sprite.scaleX = scale
		sprite.scaleY = scale
	end
	local frame = oLine(
	{
		oVec2.zero,
		oVec2(width,0),
		oVec2(width,width),
		oVec2(0,width),
		oVec2.zero,
	},ccColor4(0xff00ffff))
	frame.cascadeColor = false
	frame.contentSize = CCSize(width,width)
	frame.anchor = oVec2.zero
	sprite.position = oVec2(width*0.5,width*0.5)
	frame:addChild(sprite)
	return frame
end

local function oFrameViewer()
	local winSize = CCDirector.winSize
	local halfW = winSize.width*0.5
	local halfH = winSize.height*0.5
	local borderW = halfW*2 - 240 - 30
	local borderH = 150

	local borderSize = CCSize(borderW,borderH)
	local panel = oSelectionPanel(borderSize,false,true,true)
	panel.touchPriority = oEditor.touchPrioritySettingPanel
	local menu = panel.menu
	menu.touchPriority = oEditor.touchPrioritySettingPanel+1
	local border = panel.border
	local halfBW = borderSize.width*0.5
	local halfBH = borderSize.height*0.5
	local endPos = oVec2(10-halfW+borderW*0.5,10-halfH+borderH*0.5)
	local startPos = oVec2(endPos.x,endPos.y-borderH-10)
	local background = CCDrawNode()
	background:drawPolygon(
	{
		oVec2(-halfBW,-halfBH),
		oVec2(halfBW,-halfBH),
		oVec2(halfBW,halfBH),
		oVec2(-halfBW,halfBH)
	},ccColor4(0xe5100000),0.5,ccColor4(0x88ffafaf))
	border:addChild(background,-1)
	panel.position = startPos
	panel.visible = false

	panel:gslot("Effect.editor.particle",function()
		if panel.visible then
			panel:stopAllActions()
			panel:runAction(CCSequence({CCDelay(0.3),oPos(0.5,startPos.x,startPos.y,oEase.InBack),CCHide()}))
		end
	end)
	panel:gslot("Effect.editor.frame",function()
		panel:stopAllActions()
		panel.position = startPos
		panel.visible = true
		panel:runAction(oPos(0.5,endPos.x,endPos.y,oEase.OutBack))
	end)
	panel:gslot("Effect.frameViewer.data",function(data)
		menu:removeAllChildrenWithCleanup()
		local width = 0
		for i,item in ipairs(data) do
			width = 10+140*(i-1)
			local clip = oClipViewer(data.file,item.rect)
			clip.position = oVec2(width,10)
			menu:addChild(clip)
		end
		width = width + 140
		panel:reset(width,borderSize.height,50,0)
	end)

	return panel
end

return oFrameViewer
