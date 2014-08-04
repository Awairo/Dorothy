setfenv(1,Dorothy())
local wait = oRoutine.wait
local once = oRoutine.once
local loop = oRoutine.loop
local seconds = oRoutine.seconds
local cycle = oRoutine.cycle
local oTextField = require("ActionEditor/Script/oTextField")
local oButton = require("ActionEditor/Script/oButton")

oAction:add(oAction.UserID,998,0,0,
	--self=oAction
	function(self)
		return true
	end,
	function(self)
		print("begin")
		local owner = self.owner
		wait(cycle(1,
			function()
				owner.velocityX = 100
			end))
		wait(cycle(1,
			function()
				owner.velocityX = -100
			end))
	end,
	function(self)
		print("end")
	end)

CCKey =
{
	Left = 0x25,
	Up = 0x26,
	Right = 0x27,
	Down = 0x28,
}

oAI:add(1,oSel({
	oSeq({
		oCon(function()
			return CCKeyboard:isKeyPressed(CCKey.Left) or CCKeyboard:isKeyPressed(CCKey.Right)
		end),
		oSel({
			oSeq({
				oCon(function()
					return oAI.self.faceRight ~= CCKeyboard:isKeyPressed(CCKey.Right)
				end),
				oAct(oAction.Turn),
			}),
			oAct(oAction.Walk),
		}),
	}),
	oSeq({
		oCon(function()
			return not CCKeyboard:isKeyPressed(CCKey.Left)
				and not CCKeyboard:isKeyPressed(CCKey.Right)
				and (oAI.self.currentAction and oAI.self.currentAction.id == oAction.Walk)
		end),
		oAct(oAction.Stop),
		oAct(oAction.Idle)
	}),
	oSeq({
		oCon(function()
			return CCKeyboard:isKeyDown(CCKey.Up)
		end),
		oAct(oAction.Jump),
	}),
	oAct(oAction.Idle),
}))

local world = oPlatformWorld()
world.showDebug = false

local unitDef = oUnitDef()
unitDef.model = "ActionEditor/Model/Output/role.model"
unitDef.static = false
unitDef.density = 1
unitDef.restitution = 0
unitDef.friction = 1
unitDef.move = 200
unitDef.jump = 550
unitDef.sensity = 0
--unitDef.scale = 0.6
unitDef:setActions(
{
	oAction.Walk,
	oAction.Turn,
	oAction.Stop,
	oAction.Jump,
	oAction.Idle,
	oAction.UserID
})
unitDef.reflexArc = 1

local unit = oUnit(unitDef,world,oVec2(400,300))
unit.group = 1
unit:getAction(oAction.Idle).recovery = 0.1
--unit:doIt(oAction.UserID)

--[[
local routine = loop(function()
	wait(seconds(5))
	wait(function() return not unit.onSurface end)
	unit:doIt(oAction.Walk)
end)
oRoutine(routine)
--]]

local bodyDef = oBodyDef()
bodyDef:attachPolygon(800,10,1,1,0)
local body = oBody(bodyDef,world,oVec2(400,0))
body.group = oData.GroupTerrain

local scene = CCScene()
scene:addChild(world)
world:addChild(unit)
world:addChild(body)
--scene:addChild(model)
--scene:addChild(model2)
--[[
local textField = oTextField(120,18,17,10,
	function(self)
		print(self.text)
		self.text = ""
		oRoutine(once(function()
			wait(seconds(0))
			self:attachWithIME()
		end))
	end)
textField.anchor = oVec2.zero
textField.position = oVec2(2,1)
textField:attachWithIME()
scene:addChild(textField)
--]]

local menu = CCMenu(false)
menu.anchor = oVec2.zero
world.UILayer:addChild(menu)
local changed = false
local btn = oButton("Change",16,60,nil,10,10,
	function()
		if changed then
			return
		end
		changed = true
		local suit = loadfile("miku.lua")()
		for name,items in pairs(suit) do
			local node = unit.model:getChildByName(name)
			if items then
				for i = 1,#items do
					local item = items[i]
					local sp = CCSprite(item[1])
					for j = 2,#item do
						sp[item[j][1]] = item[j][2]
					end
					node:addChild(sp)
				end
			end
		end
	end)
btn.anchor = oVec2.zero
menu:addChild(btn)

CCDirector:run(scene)

--[[local class,property,classfield,classmethod = unpack(require("class"))

local ClassA = class(
{
	name = "aaaa",
	show = function(self)
		print("XXX")
	end,
})

local a = ClassA()
print(a.name)
a:show()
--]]