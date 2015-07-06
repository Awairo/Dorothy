local CCSize = require("CCSize")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local CCDirector = require("CCDirector")
local oSelectionPanel = require("oSelectionPanel")
local oViewItem = require("oViewItem")
local emit = require("emit")
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
		crossA.transformTarget = oEditor.world
		crossB.transformTarget = oEditor.world
		if data.resetListener then
			if data:has("BodyA") and data:has("BodyB") then
				local bodyA = oEditor:getItem(data:get("BodyA"))
				local bodyB = oEditor:getItem(data:get("BodyB"))
				if bodyA then
					crossA.transformTarget = bodyA
					crossA.position = oVec2.zero
					crossA:fadeOut()
				end
				if bodyB then
					crossB.transformTarget = bodyB
					crossB.position = oVec2.zero
					crossB:fadeOut()
				end
				if bodyA then
					emit("viewArea.toPos",oEditor.origin-bodyA.position)
				elseif bodyB then
					emit("viewArea.toPos",oEditor.origin-bodyB.position)
				end
			end
			return
		end
		if not data.parent then
			if data:has("Center") then
				local worldNode = oEditor.worldNode
				local item = oEditor:getItem(data)
				if item then
					worldNode.position = item.position
					worldNode.angle = item.angle
					crossA.transformTarget = item
					crossA.position = data:get("Center")
				else
					worldNode.position = data:get("Position")
					worldNode.angle = data:has("Angle") and data:get("Angle") or 0	
				end
				local pos = worldNode:convertToWorldSpace(data:get("Center"))
				pos = oEditor.world:convertToNodeSpace(pos)
				if not item then crossA.position = pos end
				emit("viewArea.toPos",oEditor.origin-pos)
			elseif data:has("Position") then
				local item = oEditor:getItem(data)
				local pos
				if item then
					crossA.transformTarget = item
					crossA.position = oVec2.zero
					pos = item.position
				else
					pos = data:get("Position")
					crossA.position = pos
				end
				emit("viewArea.toPos",oEditor.origin-pos)
			end
		elseif not data:has("Center") then
			local parent = data.parent
			local item = oEditor:getItem(parent)
			local pos
			if item then
				pos = item.position
				crossA.transformTarget = item
				crossA.position = oVec2.zero
			else
				pos = parent:get("Position")
				crossA.position = pos
			end
			emit("viewArea.toPos",oEditor.origin-pos)
		else
			local parent = data.parent
			local item = oEditor:getItem(parent)
			local worldNode = oEditor.worldNode
			if item then
				worldNode.position = item.position
				worldNode.angle = item.angle
				crossA.transformTarget = item
				crossA.position = data:get("Center")
			else
				worldNode.position = parent:get("Position")
				worldNode.angle = parent:has("Angle") and parent:get("Angle") or 0
			end
			local pos = worldNode:convertToWorldSpace(data:get("Center"))
			pos = oEditor.world:convertToNodeSpace(pos)
			if not item then crossA.position = pos end
			emit("viewArea.toPos",oEditor.origin-pos)
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

	local baseJointName = nil
	menu:gslot("viewPanel.selectJoint",function(joint)
		baseJointName = joint
	end)

	local function selectCallback(item)
		if baseJointName then
			if item.dataItem.resetListener then
				local data = item.dataItem
				local name = data:get("Name")
				if name ~= baseJointName then
					emit("editControl.joint",name)
					item.selected = false
				else
					item.selected = true
				end
			else -- not joint
				item.selected = false
			end
			return
		end
		emit("editControl.hide")
		emit("settingPanel.edit",nil)
		emit("viewPanel.choose",item)
		if item.selected then
			emit("settingPanel.toState",item.dataItem:get("ItemType"))
			moveViewToData(item.dataItem)
		else
			emit("settingPanel.toState",nil)
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

	local currentItem = nil
	self:gslot("viewPanel.choose",function(arg)
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
					emit("settingPanel.toState",item.dataItem[1])
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
	self:gslot("editor.bodyData",function(bodyData)
		updateViewItems(bodyData)
	end)
	self:gslot("editor.rename",function(args)
		local newName = args.newName
		for _,item in ipairs(self.items) do
			if item.dataItem[2] == newName then
				item.name = newName
				break
			end
		end
	end)
	self:gslot("viewArea.moveToData",function(data)
		moveViewToData(data)
	end)
	return self
end

return oViewPanel
