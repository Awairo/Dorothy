local CCMenuItem = require("CCMenuItem")
local CCSize = require("CCSize")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local CCMenu = require("CCMenu")
local CCDirector = require("CCDirector")
local CCLayer = require("CCLayer")
local oEditor = require("oEditor")
local CCTouch = require("CCTouch")
local oButton = require("oButton")
local ccColor3 = require("ccColor3")
local oScale = require("oScale")
local oEase = require("oEase")

local function oVertexControl()
	local winSize = CCDirector.winSize
	local vertSize = 40
	local halfSize = vertSize*0.5
	local vertices = nil
	local vertChanged = nil
	local selectedVert = nil
	local function itemTapped(eventType,item)
		if eventType == CCMenuItem.TapBegan then
			if selectedVert and item ~= selectedVert then
				selectedVert.opacity = 0.2
				selectedVert.selected = false
			end
			selectedVert = item
			if item.opacity == 0.5 then
				item.selected = true
			else
				item.opacity = 0.5
			end
		elseif eventType == CCMenuItem.Tapped then
			item.selected = not item.selected
			selectedVert = item.selected and item or nil
			item.opacity = item.selected and 0.5 or 0.2
		end
	end
	local function oVertex(pos,index)
		local menuItem = CCMenuItem()
		menuItem:registerTapHandler(itemTapped)
		menuItem.contentSize = CCSize(vertSize,vertSize)
		local circle = CCDrawNode()
		circle:drawDot(oVec2.zero,halfSize,ccColor4(0xff00ffff))
		circle.position = oVec2(halfSize,halfSize)
		menuItem:addChild(circle)
		menuItem.position = pos
		menuItem.opacity = 0.2
		menuItem.index = index
		return menuItem
	end

	local layer = CCLayer()
	layer.contentSize = CCSize.zero
	layer.visible = false

	local menu = CCMenu(false)
	menu.items = nil
	menu.vs = nil
	menu.touchPriority = oEditor.touchPriorityEditControl+1
	menu.contentSize = CCSize.zero
	menu.transformTarget = oEditor.world
	menu.touchEnabled = false
	menu:addChild(oVertex(oVec2(-100,100)))
	menu:addChild(oVertex(oVec2(100,100)))
	menu:addChild(oVertex(oVec2(-100,-100)))
	menu:addChild(oVertex(oVec2(100,-100)))
	layer:addChild(menu)
	layer.menu = menu

	local function setVertices(vs)
		menu:removeAllChildrenWithCleanup()
		menu.vs = vs
		menu.items = {}
		for i = 1,#vs do
			local item = oVertex(vs[i],i)
			table.insert(menu.items,item)
			menu:addChild(item)
		end
	end
	
	local function addVertex(v)
		local item = oVertex(v,#(menu.items)+1)
		table.insert(menu.items,item)
		menu:addChild(item)
		table.insert(menu.vs,v)
		if vertChanged then
			vertChanged(menu.vs)
		end
	end
	
	local function removeVertex()
		if selectedVert then
			local index = selectedVert.index
			menu:removeChild(menu.children[index])
			table.remove(menu.items,index)
			for i = 1,#menu.items do
				menu.items[i].index = i
			end
			table.remove(menu.vs,index)
			selectedVert = nil
			if vertChanged then
				vertChanged(menu.vs)
			end
		end
	end

	local vertexToAdd = false
	local addButton = nil
	layer:registerTouchHandler(function(eventType, touch)
		if eventType == CCTouch.Began then
			if vertexToAdd then
				vertexToAdd = false
				addButton.color = ccColor3(0x00ffff)
				addVertex(menu:convertToNodeSpace(touch.location))
				return false
			end
		elseif eventType == CCTouch.Moved then
			if selectedVert then
				selectedVert.selected = false
				selectedVert.position = selectedVert.position + menu:convertToNodeSpace(touch.location) - menu:convertToNodeSpace(touch.preLocation)
				menu.vs[selectedVert.index] = selectedVert.position
				if vertChanged then
					vertChanged(menu.vs)
				end
			end
		end
		return true
	end,false,oEditor.touchPriorityEditControl,false)
	
	local mask = CCLayer()
	mask.contentSize = CCSize.zero
	mask:registerTouchHandler(function() return selectedVert ~= nil end,false,oEditor.touchPriorityEditControl+2,true)
	layer:addChild(mask)
	
	local editMenu = CCMenu(false)
	editMenu.anchor = oVec2.zero
	editMenu.touchPriority = oEditor.touchPriorityEditControl
	editMenu.touchEnabled = false
	layer:addChild(editMenu)
	local removeButton = oButton("-",20,50,50,winSize.width-405,winSize.height-35,function()
		removeVertex()
	end)
	editMenu:addChild(removeButton)
	addButton = oButton("+",20,50,50,winSize.width-345,winSize.height-35,function(button)
		button.color = ccColor3(0xff0080)
		vertexToAdd = true
	end)
	editMenu:addChild(addButton)

	layer.show = function(self,vs,pos,angle,callback)
		layer.touchEnabled = true
		mask.touchEnabled = true
		menu.touchEnabled = true
		editMenu.touchEnabled = true
		layer.visible = true
		menu.position = pos
		menu.rotation = angle
		vs = vs or {}
		selectedVert = nil
		vertexToAdd = false
		addButton.color = ccColor3(0x00ffff)
		setVertices(vs)
		vertChanged = callback
		addButton:stopAllActions()
		addButton.scaleX = 0
		addButton.scaleY = 0
		addButton:runAction(oScale(0.5,1,1,oEase.OutBack))
		removeButton:stopAllActions()
		removeButton.scaleX = 0
		removeButton.scaleY = 0
		removeButton:runAction(oScale(0.5,1,1,oEase.OutBack))
	end
	layer.hide = function(self)
		if not layer.visible then return end
		vertChanged = nil
		selectedVert = nil
		menu.items = {}
		menu.vs = {}
		menu:removeAllChildrenWithCleanup()
		layer.touchEnabled = false
		mask.touchEnabled = false
		menu.touchEnabled = false
		editMenu.touchEnabled = false
		layer.visible = false
	end

	return layer
end

return oVertexControl
