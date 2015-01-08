local CCDirector = require("CCDirector")
local CCSize = require("CCSize")
local oSelectionPanel = require("oSelectionPanel")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local oContent = require("oContent")
local oEditor = require("oEditor")
local CCLabelTTF = require("CCLabelTTF")
local ccColor3 = require("ccColor3")
local oOpacity = require("oOpacity")
local oButton = require("oButton")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local CCCall = require("CCCall")
local CCMenu = require("CCMenu")

local function oFileChooser()
	local winSize = CCDirector.winSize
	local itemWidth = 120
	local itemNum = 3
	local borderSize = CCSize((itemWidth+10)*itemNum+10,winSize.height-200)
	local panel = oSelectionPanel(borderSize)
	local menu = panel.menu
	local border = panel.border
	local halfBW = borderSize.width*0.5
	local halfBH = borderSize.height*0.5
	local background= CCDrawNode()
	background:drawPolygon(
	{
		oVec2(-halfBW,-halfBH),
		oVec2(halfBW,-halfBH),
		oVec2(halfBW,halfBH),
		oVec2(-halfBW,halfBH)
	},ccColor4(0xe5100000),0.5,ccColor4(0x88ffafaf))
	border:addChild(background,-1)

	local entries = oContent:getEntries(oEditor.output,false)
	local files = {}
	for i = 1,#entries do
		local name = nil
		if entries[i]:sub(-4,-1) == ".lua" then
			name = entries[i]:sub(1,-5)
		end
		if name then
			table.insert(files,name)
		end
	end
	local n = 0
	local y = 0
	local xStart = 0 -- left
	local yStart = borderSize.height -- top

	local title = CCLabelTTF("Choose  Body","Arial",24)
	title.texture.antiAlias = false
	title.color = ccColor3(0x00ffff)
	title.anchor = oVec2(0.5,1)
	y = yStart-20
	title.position = oVec2(halfBW,y)
	menu:addChild(title)
	title.opacity = 0
	title:runAction(oOpacity(0.3,0.5))
	yStart = y-title.contentSize.height-20

	for i = 1,#files do
		n = n+1
		y = yStart-35-math.floor((n-1)/itemNum)*60
		local name = #files[i] > 10 and files[i]:sub(1,7).."..." or files[i]
		local button = oButton(
			name,
			17,
			itemWidth,50,
			xStart+itemWidth*0.5+10+((n-1)%itemNum)*(itemWidth+10), y,
			function(item)
				panel.ended = function()
					panel.parent:removeChild(panel)
				end
				oEditor.currentFile = item.file
				oEditor:loadData(item.file)
				panel:hide()
			end)
		button.file = files[i]..".lua"
		--button.color = ccColor3(0xffffff)
		button.enabled = false
		button.opacity = 0
		button:runAction(
			CCSequence(
			{
				CCDelay(n*0.05),
				oOpacity(0.2,1),
				CCCall(
					function()
						button.enabled = true
					end)
			}))
		menu:addChild(button)
	end

	local yTo = winSize.height*0.5+halfBH-y+35
	local viewHeight = yTo < borderSize.height and borderSize.height or yTo
	local viewWidth = borderSize.width
	local paddingX = 0
	local paddingY = 100
	panel:reset(viewWidth,viewHeight,paddingX,paddingY)
	
	local opMenu = CCMenu()
	opMenu.contentSize = CCSize(60,60)
	opMenu.anchor = oVec2(1,0.5)
	opMenu.touchPriority = CCMenu.DefaultHandlerPriority-3
	opMenu.position = oVec2(winSize.width*0.5+borderSize.width*0.5+35,winSize.height*0.5+borderSize.height*0.5)
	panel:addChild(opMenu)

	local cancelButton = oButton("Cancel",17,60,false,
		0,0,
		function(item)
			opMenu.enabled = false
			panel:hide()
			item:unregisterTapHandler()
		end)
	cancelButton.anchor = oVec2.zero
	local btnBk = CCDrawNode()
	btnBk:drawDot(oVec2.zero,30,ccColor4(0x22ffffff))
	btnBk.position = oVec2(30,30)
	cancelButton:addChild(btnBk,-1)
	opMenu:addChild(cancelButton)

	panel:show()
	return panel
end

return oFileChooser
