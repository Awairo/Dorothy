local CCLayerColor = require("CCLayerColor")
local ccColor4 = require("ccColor4")
local CCDirector = require("CCDirector")
local oVec2 = require("oVec2")
local CCLabelTTF = require("CCLabelTTF")
local CCDrawNode = require("CCDrawNode")
local oEvent = require("oEvent")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local oOpacity = require("oOpacity")
local CCCall = require("CCCall")
local CCNode = require("CCNode")
local oCache = require("oCache")
local oScale = require("oScale")
local oEase = require("oEase")

collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

local _require = require
local loaded = {}
require = function(modulename)
	local result = package.loaded[modulename]
	if not result then
		local name = "ActionEditor/Script/"..modulename
		result = _require(name)
		if result then
			loaded[name] = true
		end
	end
	return result
end

local oEditor = require("oEditor").oEditor

local controls =
{
	-- Animation oEditor
	"oViewArea",
	"oEditMenu",
	"oViewPanel",
	"oControlBar",
	"oSettingPanel",
	--"oTip",
}

local controlNames =
{
	"viewArea",
	"editMenu",
	"viewPanel",
	"controlBar",
	"settingPanel",
	--"tip",
}

local thread = coroutine.create(
	function()
		for i = 1,#controls do
			controls[i] = require(controls[i])
			coroutine.yield()
			controls[i] = controls[i]()
			oEditor[controlNames[i]] = controls[i]
			coroutine.yield()
		end
		for i = 1,#controls do
			oEditor.scene:addChild(controls[i])
			coroutine.yield()
		end
	end)

local bk = CCLayerColor(ccColor4(0xff000000),CCDirector.winSize.width,CCDirector.winSize.height)
bk.anchor = oVec2.zero
local logo = CCLabelTTF("Luv & Fight","Arial",48)
logo.texture.antiAlias = false
logo.position = oVec2(CCDirector.winSize.width*0.5,CCDirector.winSize.height*0.5)
logo.scaleX = 0.3
logo.scaleY = 0.3
logo.opacity= 0
logo:runAction(oScale(0.3,1,1,oEase.OutBack))
logo:runAction(oOpacity(0.3,1,oEase.OutQuad))

bk:addChild(logo)
local flower = CCDrawNode()
flower:drawPolygon(
{
	oVec2(-1,10),
	oVec2(9,10),
	oVec2(9,20),
	oVec2(-1,20),
},ccColor4(0xff00ffff))
flower:drawPolygon(
{
	oVec2(10,-1),
	oVec2(20,-1),
	oVec2(20,9),
	oVec2(10,9),
},ccColor4(0xff00ffff))
flower:drawPolygon(
{
	oVec2(21,10),
	oVec2(31,10),
	oVec2(31,20),
	oVec2(21,20),
},ccColor4(0xff00ffff))
flower:drawPolygon(
{
	oVec2(10,21),
	oVec2(20,21),
	oVec2(20,31),
	oVec2(10,31),
},ccColor4(0xff00ffff))
flower.scaleX = 0.5
flower.scaleY = 0.5
flower.position = oVec2(logo.contentSize.width+2,logo.contentSize.height-2)
logo:addChild(flower)
oEditor.scene:addChild(bk,998)

local time = 0
oEditor.scene:schedule(
	function(self,deltaTime)
		time = time+deltaTime
		local result = coroutine.resume(thread)
		if not result then
			self:unschedule()
			oEvent:send("EditorLoaded")
			if time < 1 then
				logo:runAction(
					CCSequence
					{
						CCDelay(1-time),
						oOpacity(0.3,0),
						CCCall(
							function()
								bk.visible = false
								bk.parent:removeChild(bk)
								oEditor.scene.opacity = 0
								oEditor.scene:runAction(oOpacity(0.3,1))
							end)
					})
			else
				bk.visible = false
				bk.parent:removeChild(bk)
				oEditor.scene.opacity = 0
				oEditor.scene:runAction(oOpacity(0.3,1))
			end
		end
	end)

--[[
local names = oCache.Clip:getNames(oEditor.output.."nvjing.clip")
for i = 1,#names do
	local sp = CCSprite(oEditor.output.."nvjing.clip|"..names[i])
	sp.anchor = oVec2.zero
	local target = CCRenderTarget(sp.contentSize.width,sp.contentSize.height)
	target:beginPaint(ccColor4(0))
	target:draw(sp)
	target:endPaint()
	target:save(names[i]..".png",CCImage.PNG)
end
]]

--CCDirector.displayStats = true
oEditor.scene:registerEventHandler(function(eventType)
	if eventType == CCNode.Exited then
		require = _require
		for k,_ in pairs(loaded) do
			package.loaded[k] = nil
		end
		for k,_ in pairs(oEditor.settingPanel.items) do
			oEditor.settingPanel.items[k] = nil
		end
		for k,_ in pairs(oEditor) do
			oEditor[k] = nil
		end
		oCache:clear()
	end
end)

CCDirector:run(oEditor.scene)
