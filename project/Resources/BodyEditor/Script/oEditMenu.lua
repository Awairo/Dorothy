local require = using("BodyEditor.Script")
local oButton = require("oButton")
local CCDirector = require("CCDirector")
local CCMenu = require("CCMenu")
local oVec2 = require("oVec2")
local oLine = require("oLine")
local ccColor4 = require("ccColor4")
local ccColor3 = require("ccColor3")
local CCNode = require("CCNode")
local oEditor = require("oEditor")
local oPlayButton = require("oPlayButton")
local emit = require("emit")
local class,property = unpack(require("class"))
local oFileChooser = require("oFileChooser")
local oBox = require("oBox")
local oJointChooser = require("oJointChooser")
local tolua = require("tolua")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local oOpacity = require("oOpacity")
local oScale = require("oScale")
local oEase = require("oEase")
local CCHide = require("CCHide")

local function oEditMenu()
	local winSize = CCDirector.winSize

	local menu = CCMenu()
	menu.touchPriority = oEditor.touchPriorityEditMenu
	menu.anchor = oVec2.zero

	local lastSelected = nil
	local function clearSelectedShape()
		if lastSelected then
			lastSelected.scaleX = 0
			lastSelected.scaleY = 0
			lastSelected:perform(oScale(0.3,1,1,oEase.OutBack))
			lastSelected.selected = false
		end
	end
	local oShapeButton = class(oButton,
	{
		__partial = function(self)
			self._selected = false
			return oButton.__partial(self)
		end,
		__init = function(self,name,x,y)
			oButton.__init(self,"",0,50,50,x,y,self.onTapped)
			self._name = name
		end,
		onTapped = function(self)
			self.selected = not self.selected
		end,
		selected = property(
			function(self)
				return self._selected
			end,
			function(self,value)
				self._selected = value
				if value then
					emit("Body.editControl.hide")
					emit("Body.settingPanel.toState",nil)
					self.color = ccColor3(0xff0080)
					if lastSelected then
						if lastSelected ~= self then
							lastSelected.scaleX = 0
							lastSelected.scaleY = 0
							lastSelected:perform(oScale(0.3,1,1,oEase.OutBack))
						end
						lastSelected.selected = false
					end
					lastSelected = self
					emit("Body.viewArea.create",self._name)
					emit("Body.viewPanel.choose",nil)
				else
					self.color = ccColor3(0x00ffff)
					if lastSelected == self then
						emit("Body.viewArea.create",nil)
					end
					lastSelected = nil
				end
			end),
	})

	-- init menu items --
	local items
	items =
	{
		Edit = oButton("Menu",16,50,50,35,winSize.height-35,function(button)
			emit("Body.settingPanel.edit",nil)
			if not oEditor.dirty then
				oEditor:addChild(oFileChooser(),oEditor.topMost)
			else
				if oEditor.currentFile then
					oEditor.dirty = false
					button.text = "Menu"
					oEditor:dumpData(oEditor.currentFile)
					items.Undo:hide()
					oEditor:emit("Edited",oEditor.currentFile)
				else
					oEditor:addChild(oBox("New Name",function(name)
						if name == "" or name:match("[\\/|:*?<>\"%.]") then
							oEditor:addChild(oBox("Invalid Name"),oEditor.topMost)
						else
							oEditor.dirty = false
							button.text = "Menu"
							oEditor.currentFile = name..".body"
							oEditor:dumpData(oEditor.currentFile)
							items.Undo:hide()
						end
					end,true),oEditor.topMost)
				end
			end
			clearSelectedShape()
		end),
		Undo = oButton("Undo",16,50,50,95,winSize.height-35,function(button)
			clearSelectedShape()
			emit("Body.settingPanel.edit",nil)
			oEditor.dirty = false
			items.Edit.text = "Menu"
			oEditor:edit(oEditor.currentFile)
			button:hide()
		end),
		Rectangle = oShapeButton("Rectangle",35,winSize.height-95),
		Circle = oShapeButton("Circle",35,winSize.height-155),
		Polygon = oShapeButton("Polygon",35,winSize.height-215),
		Chain = oShapeButton("Chain",35,winSize.height-275),
		Loop = oShapeButton("Loop",35,winSize.height-335),
		Delete = oButton("Delete",16,50,50,35,winSize.height-395,function()
			clearSelectedShape()
			if oEditor.currentData then
				emit("Body.settingPanel.toState",nil)
				oEditor:removeData(oEditor.currentData)
				if not oEditor.currentData.parent and not oEditor.currentData.resetListener then
					oEditor:rename(oEditor.currentData:get("Name"),"")
					oEditor.currentData = nil
					emit("Body.editor.change")
				end
			end
		end),
		Joint = oButton("",0,50,50,35,35,function()
			clearSelectedShape()
			oEditor:addChild(oJointChooser(),oEditor.topMost)
		end),

		Origin = oButton("Origin",16,50,50,winSize.width-285,winSize.height-35,function()
			emit("Body.viewArea.toPos",oEditor.origin)
		end),

		Zoom = oButton("100%",16,50,50,winSize.width-225,winSize.height-35,function(button)
			local scale = 0
			if button.mode == 0 then
				scale = 2.0
			elseif button.mode == 1 then
				scale = 0.5
			elseif button.mode == 2 then
				scale = 1.0
			end
			button.mode = button.mode + 1
			button.mode = button.mode % 3
			button.text = tostring(scale*100).."%"
			emit("Body.viewArea.toScale",scale)
		end),

		Play = oPlayButton(50,winSize.width-225,35,function(button)
			if button.isPlaying then
				clearSelectedShape()
			end
			emit("Body.editControl.hide")
			emit("Body.settingPanel.edit",nil)
			emit("Body.settingPanel.enable",not button.isPlaying)
			emit("Body.editor.isPlaying",button.isPlaying)
		end),
	}

	items.Undo.visible = false
	items.Undo.show = function(self)
		self.visible = true
		self.enabled = true
		self.scaleX = 0
		self.scaleY = 0
		self:perform(oScale(0.3,1,1,oEase.OutBack))
	end
	items.Undo.hide = function(self)
		self.enabled = false
		self:perform(CCSequence({
			oScale(0.3,0,0,oEase.InBack),
			CCHide()
		}))
	end

	-- rectangle button --
	local paint = oLine(
	{
		oVec2(-15,15),
		oVec2(15,15),
		oVec2(15,-15),
		oVec2(-15,-15),
		oVec2(-15,15),
	},ccColor4(0xffff0080))
	local node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	node:addChild(paint)
	items.Rectangle.face:addChild(node)

	-- circle button --
	local vs = {}
	local num = 20
	for i = 0, num do
		local angle = 2*math.pi*i/num
		table.insert(vs,oVec2(18*math.cos(angle),18*math.sin(angle)))
	end
	paint = oLine(vs,ccColor4(0xffff0080))
	node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	node:addChild(paint)
	items.Circle.face:addChild(node)


	-- polygon button --
	paint = oLine(
	{
		oVec2(0,18),
		oVec2(18,-18),
		oVec2(-18,-18),
		oVec2(0,18),
	},ccColor4(0xffff0080))
	node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	node:addChild(paint)
	items.Polygon.face:addChild(node)

	-- chain button --
	paint = oLine(
	{
		oVec2(-15,15),
		oVec2(0,15),
		oVec2(0,-15),
		oVec2(15,-15),
	},ccColor4(0xffff0080))
	node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	node:addChild(paint)
	items.Chain.face:addChild(node)

	-- loop button --
	paint = oLine(
	{
		oVec2(-16,0),
		oVec2(-8,16),
		oVec2(4,8),
		oVec2(8,16),
		oVec2(16,0),
		oVec2(8,-16),
		oVec2(-8,-16),
		oVec2(-16,0),
	},ccColor4(0xffff0080))
	node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	node:addChild(paint)
	items.Loop.face:addChild(node)

	-- joint button --
	node = CCNode()
	node.cascadeColor = false
	node.position = oVec2(25,25)
	paint = oLine(
	{
		oVec2(-13,13),
		oVec2(13,-13),
	},ccColor4(0xffff0080))
	node:addChild(paint)
	paint = oLine(
	{
		oVec2(-16,16),
		oVec2(-10,16),
		oVec2(-10,10),
		oVec2(-16,10),
		oVec2(-16,16),
	},ccColor4(0xff80ff00))
	node:addChild(paint)
	paint = oLine(
	{
		oVec2(16,-16),
		oVec2(10,-16),
		oVec2(10,-10),
		oVec2(16,-10),
		oVec2(16,-16),
	},ccColor4(0xff80ff00))
	node:addChild(paint)
	items.Joint.face:addChild(node)

	-- update scale button --
	items.Zoom.mode = 0
	items.Zoom:gslot("Body.viewArea.scale",function(scale)
		if scale ~= 1 then items.Zoom.mode = 2 end
		items.Zoom.text = tostring(math.floor(scale*100)).."%"
	end)
	items.Play:gslot("Body.editor.isPlaying",function(isPlaying)
		oEditor.isPlaying = isPlaying
		oEditor.worldScheduler.timeScale = isPlaying and 1 or 0
		if not isPlaying then
			oEditor:resetItems()
		end
		if isPlaying then
			local motorButtons = {}
			local i = 0
			local itemNum = math.floor((winSize.width-320-70)/110)
			for name,item in pairs(oEditor.items) do
				if tolua.type(item) == "oMotorJoint" then
					local x = winSize.width-370-(i%itemNum)*110
					local y = winSize.height-35-60*math.floor(i/itemNum)
					local jointButton = oButton(name,16,100,50,x,y,function(btn)
						item.enabled = not item.enabled
						btn.color = item.enabled and ccColor3(0xff0080) or ccColor3(0x00ffff)
					end)
					jointButton.opacity = 0
					jointButton:runAction(CCSequence({CCDelay(i*0.1),oOpacity(0.3,1)}))
					table.insert(motorButtons,jointButton)
					menu:addChild(jointButton)
					i = i + 1
				end
			end
			menu.motorButtons = motorButtons
		elseif menu.motorButtons then
			for _,btn in ipairs(menu.motorButtons) do
				menu:removeChild(btn)
			end
			menu.motorButtons = nil
		end
	end)

	menu:gslot("Body.editMenu.created",clearSelectedShape)
	menu:gslot("Body.editor.change",function()
		if not oEditor.dirty and items.Edit.text ~= "Save" then
			items.Edit.text = "Save"
			items.Undo:show()
		end
		oEditor.dirty = true
	end)
	menu:gslot("Body.editMenu.reset",function()
		items.Play.isPlaying = false
	end)

	-- add buttons to menu --
	for _,item in pairs(items) do
		menu:addChild(item)
	end
	menu.items = items

	return menu
end

return oEditMenu