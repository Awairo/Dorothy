local CCSize = require("CCSize")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local CCDirector = require("CCDirector")
local oSelectionPanel = require("oSelectionPanel")
local oViewItem = require("oViewItem")
local oEvent = require("oEvent")
local CCDictionary = require("CCDictionary")
local oListener = require("oListener")
local oEditor = require("oEditor")
local oLine = require("oLine")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local oOpacity = require("oOpacity")

local function oViewPanel()
	local winSize = CCDirector.winSize
	local borderSize = CCSize(180,310*(winSize.height-30)/(600-30))
	local self = oSelectionPanel(borderSize,false,true,true)
	self.touchPriority = oEditor.touchPriorityViewPanel
	local menu = self.menu
	menu.touchPriority = oEditor.touchPriorityViewPanel+1
	local border = self.border
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
	self.position = oVec2(winSize.width*0.5-100,winSize.height*0.5-halfBH-10)

	local function createCross()
		local cross = oLine(
		{
			oVec2(-10,0),
			oVec2(0,10),
			oVec2(10,0),
			oVec2(0,-10),
			oVec2(-10,0),
			oVec2(10,0),
		},ccColor4(0xff00ffff))
		cross:addChild(oLine({oVec2(0,10),oVec2(0,-10)},ccColor4(0xff00ffff)))
		cross.opacity = 0
		cross.transformTarget = oEditor.world
		oEditor:addChild(cross,2)
		local fadeOut = CCSequence({CCDelay(0.7),oOpacity(0.3,0)})
		cross.fadeOut = function(self)
			cross.opacity = 1
			cross:stopAllActions()
			cross:runAction(fadeOut)
		end
		return cross
	end

	local crossA = createCross()
	local crossB = createCross()
	
	local function moveViewToData(data)
		if oEditor.isPlaying then return end
		if data.resetListener then
			if data:has("BodyA") and data:has("BodyB") then
				local bodyA = oEditor:getItem(data:get("BodyA"))
				local bodyB = oEditor:getItem(data:get("BodyB"))
				if bodyA then
					crossA.position = bodyA.position
					crossA:fadeOut()
				end
				if bodyB then
					crossB.position = bodyB.position
					crossB:fadeOut()
				end
			end
			return
		end
		if not data.parent then
			if data:has("Center") then
				local worldNode = oEditor.worldNode
				worldNode.position = data:get("Position")
				worldNode.rotation = data:has("Angle") and data:get("Angle") or 0
				local pos = worldNode:convertToWorldSpace(data:get("Center"))
				pos = oEditor.world:convertToNodeSpace(pos)
				crossA.position = pos
				oEvent:send("viewArea.toPos",oEditor.origin-pos*oEditor.scale)
			elseif data:has("Position") then
				local pos = data:get("Position")
				crossA.position = pos
				oEvent:send("viewArea.toPos",oEditor.origin-pos*oEditor.scale)
			end
		elseif not data:has("Center") then
			local parent = data.parent
			local pos = parent:get("Position")
			crossA.position = pos
			oEvent:send("viewArea.toPos",oEditor.origin-pos*oEditor.scale)
		else
			local parent = data.parent
			local worldNode = oEditor.worldNode
			worldNode.position = parent:get("Position")
			worldNode.rotation = parent:has("Angle") and parent:get("Angle") or 0
			local pos = worldNode:convertToWorldSpace(data:get("Center"))
			pos = oEditor.world:convertToNodeSpace(pos)
			crossA.position = pos
			oEvent:send("viewArea.toPos",oEditor.origin-pos*oEditor.scale)
		end
		crossA:fadeOut()
	end

	local function genPosY()
		local index = 0
		return function()
			local v = index
			index = index + 1
			return borderSize.height-30-50*v
		end
	end

	local function selectCallback(item)
		oEvent:send("editControl.hide")
		oEvent:send("settingPanel.edit",nil)
		oEvent:send("viewPanel.choose",item)
		if item.selected then
			oEvent:send("settingPanel.toState",item.dataItem:get("ItemType"))
			moveViewToData(item.dataItem)
		else
			oEvent:send("settingPanel.toState",nil)
		end
	end

	local function updateViewItems(bodyData)
		local items = {}
		local getPosY = genPosY()
		for _,data in ipairs(bodyData) do
			local item = oViewItem(data[1],data[2],90,getPosY(),selectCallback)
			item.dataItem = data
			table.insert(items,item)
			local subShapeIndex = oEditor[data[1]].SubShapes
			if subShapeIndex and data[subShapeIndex] then
				for index,subShape in ipairs(data[subShapeIndex]) do
					local item = oViewItem(subShape[1],index,90,getPosY(),selectCallback)
					item.dataItem = subShape
					item.parentData = data
					table.insert(items,item)
				end
			end
		end
		local contentHeight = 10
		menu:removeAllChildrenWithCleanup()
		for _,item in ipairs(items) do
			contentHeight = contentHeight + 50
			menu:addChild(item)
		end
		self.items = items
		self:reset(borderSize.width,contentHeight,0,50)
	end
	updateViewItems(oEditor.bodyData)

	self.data = CCDictionary()
	local currentItem = nil
	self.data.chooseListener = oListener("viewPanel.choose",function(arg)
		local item
		if type(arg) == "table" then
			for _,v in ipairs(self.items) do
				if arg == v.dataItem then
					if currentItem == v then
						moveViewToData(v.dataItem)
						return
					end
					item = v
					item.selected = true
					oEditor.currentData = item.dataItem
					oEvent:send("settingPanel.toState",item.dataItem[1])
					self:setPos(oVec2(0,borderSize.height*0.5+30-item.positionY))
					moveViewToData(item.dataItem)
					break
				end
			end
		else
			item = arg
		end
		if item == nil then
			if currentItem then
				currentItem.selected = false
			end
			currentItem = nil
			oEditor.currentData = nil
		elseif item.selected then
			if currentItem then
				currentItem.selected = false
			end
			currentItem = item
			oEditor.currentData = item.dataItem
		else
			currentItem = nil
			oEditor.currentData = nil
		end
	end)
	self.data.bodyDataListener = oListener("editor.bodyData",function(bodyData)
		updateViewItems(bodyData)
	end)
	self.data.renameListener = oListener("editor.rename",function(args)
		local newName = args.newName
		for _,item in ipairs(self.items) do
			if item.dataItem[2] == newName then
				item.name = newName
				break
			end
		end
	end)
	self.data.moveViewListener = oListener("viewArea.moveToData",function(data)
		moveViewToData(data)
	end)
	return self
end

return oViewPanel
