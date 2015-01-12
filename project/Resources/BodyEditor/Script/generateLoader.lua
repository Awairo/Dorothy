local oContent = require("oContent")
local oEditor = require("oEditor")
local Rectangle = oEditor.Rectangle
local Circle = oEditor.Circle
local Polygon = oEditor.Polygon
local Chain = oEditor.Chain
local Loop = oEditor.Loop
local SubRectangle = oEditor.SubRectangle
local SubCircle = oEditor.SubCircle
local SubPolygon = oEditor.SubPolygon
local SubChain = oEditor.SubChain
local SubLoop = oEditor.SubLoop
local Distance = oEditor.Distance
local Friction = oEditor.Friction
local Gear = oEditor.Gear
local Spring = oEditor.Spring
local Prismatic = oEditor.Prismatic
local Pulley = oEditor.Pulley
local Revolute = oEditor.Revolute
local Rope = oEditor.Rope
local Weld = oEditor.Weld
local Wheel = oEditor.Wheel

local loaderCodes = [[
local CCDictionary = require("CCDictionary")
local CCNode = require("CCNode")
local tolua = require("tolua")
local oBody = require("oBody")
local oVec2 = require("oVec2")
local oJoint = require("oJoint")
local oBodyDef = require("oBodyDef")
local oJointDef = require("oJointDef")

local loadFuncs = nil
local function loadData(data,item)
	local itemType = data[1]
	loadFuncs[itemType](data,item)
end

local function load(_,filename)
	local bodyData = dofile(filename)
	local itemDict = CCDictionary()
	for _,data in ipairs(bodyData) do
		loadData(data,itemDict)
	end
	return itemDict
end

local function create(_,itemDict,world,pos)
	local items = CCDictionary()
	local node = CCNode()
	node.data = items
	local firstBodyPos = nil
	local keys = itemDict.keys
	for i = 1,#keys do
		local key = keys[i]
		local itemDef = itemDict[key]
		if tolua.type(itemDef) == "oBodyDef" then
			local body = oBody(itemDef,world,pos)
			items[key] = body
			node:addChild(body)
		else
			local joint = oJoint(itemDef,items)
			if joint then
				items[key] = joint
			end
		end
	end
	return node
end

loadFuncs =
{
]]..string.format([[
	Rectangle = function(data,itemDict)
		local bodyDef = oBodyDef()
		bodyDef.type = data[%d]
		bodyDef.isBullet = data[%d]
		bodyDef.gravityScale = data[%d]
		bodyDef.fixedRotation = data[%d]
		bodyDef.linearDamping = data[%d]
		bodyDef.angularDamping = data[%d]
		bodyDef.position = data[%d]
		bodyDef.angle = data[%d]
		if data[%d] then
			bodyDef:attachPolygonSensor(data[%d],
				data[%d].width,data[%d].height,data[%d],0)
		else
			bodyDef:attachPolygon(data[%d],
				data[%d].width,data[%d].height,
				0,data[%d],data[%d],data[%d])
		end
		if data[%d] then
			for _,subShape in ipairs(data[%d]) do
				loadData(subShape,bodyDef)
			end
		end
		itemDict:set(data[%d],bodyDef)
	end,
]],
Rectangle.Type,
Rectangle.Bullet,
Rectangle.GravityScale,
Rectangle.FixedRotation,
Rectangle.LinearDamping,
Rectangle.AngularDamping,
Rectangle.Position,
Rectangle.Angle,
Rectangle.Sensor,
Rectangle.SensorTag,
Rectangle.Size,
Rectangle.Size,
Rectangle.Center,
Rectangle.Center,
Rectangle.Size,
Rectangle.Size,
Rectangle.Density,
Rectangle.Friction,
Rectangle.Restitution,
Rectangle.SubShapes,
Rectangle.SubShapes,
Rectangle.Name)..string.format([[
	Circle = function(data,itemDict)
		local bodyDef = oBodyDef()
		bodyDef.type = data[%d]
		bodyDef.isBullet = data[%d]
		bodyDef.gravityScale = data[%d]
		bodyDef.fixedRotation = data[%d]
		bodyDef.linearDamping = data[%d]
		bodyDef.angularDamping = data[%d]
		bodyDef.position = data[%d]
		bodyDef.angle = data[%d]
		if data[%d] then
			bodyDef:attachCircleSensor(data[%d],data[%d],data[%d])
		else
			bodyDef:attachCircle(data[%d],data[%d],data[%d],data[%d],data[%d])
		end
		if data[%d] then
			for _,subShape in ipairs(data[%d]) do
				loadData(subShape,bodyDef)
			end
		end
		itemDict:set(data[%d],bodyDef)
	end,
]],
Circle.Type,
Circle.Bullet,
Circle.GravityScale,
Circle.FixedRotation,
Circle.LinearDamping,
Circle.AngularDamping,
Circle.Position,
Circle.Angle,
Circle.Sensor,
Circle.SensorTag,
Circle.Center,
Circle.Radius,
Circle.Center,
Circle.Radius,
Circle.Density,
Circle.Friction,
Circle.Restitution,
Circle.SubShapes,
Circle.SubShapes,
Circle.Name)..string.format([[
	Polygon = function(data,itemDict)
		if not data[%d] or #data[%d] < 3 then return end
		local bodyDef = oBodyDef()
		bodyDef.type = data[%d]
		bodyDef.isBullet = data[%d]
		bodyDef.gravityScale = data[%d]
		bodyDef.fixedRotation = data[%d]
		bodyDef.linearDamping = data[%d]
		bodyDef.angularDamping = data[%d]
		bodyDef.position = data[%d]
		bodyDef.angle = data[%d]
		if data[%d] then
			bodyDef:attachPolygonSensor(data[%d],data[%d])
		else
			bodyDef:attachPolygon(data[%d],data[%d],data[%d],data[%d])
		end
		if data[%d] then
			for _,subShape in ipairs(data[%d]) do
				loadData(subShape,bodyDef)
			end
		end
		itemDict:set(data[%d],bodyDef)
	end,
]],
Polygon.Vertices,
Polygon.Vertices,
Polygon.Type,
Polygon.Bullet,
Polygon.GravityScale,
Polygon.FixedRotation,
Polygon.LinearDamping,
Polygon.AngularDamping,
Polygon.Position,
Polygon.Angle,
Polygon.Sensor,
Polygon.SensorTag,
Polygon.Vertices,
Polygon.Vertices,
Polygon.Density,
Polygon.Friction,
Polygon.Restitution,
Polygon.SubShapes,
Polygon.SubShapes,
Polygon.Name)..string.format([[
	Chain = function(data,itemDict)
		if not data[%d] or #data[%d] < 2 then return end
		local bodyDef = oBodyDef()
		bodyDef.type = data[%d]
		bodyDef.isBullet = data[%d]
		bodyDef.gravityScale = data[%d]
		bodyDef.fixedRotation = data[%d]
		bodyDef.linearDamping = data[%d]
		bodyDef.angularDamping = data[%d]
		bodyDef.position = data[%d]
		bodyDef.angle = data[%d]
		bodyDef:attachChain(data[%d],data[%d],data[%d])
		if data[%d] then
			for _,subShape in ipairs(data[%d]) do
				loadData(subShape,bodyDef)
			end
		end
		itemDict:set(data[%d],bodyDef)
	end,
]],
Chain.Vertices,
Chain.Vertices,
Chain.Type,
Chain.Bullet,
Chain.GravityScale,
Chain.FixedRotation,
Chain.LinearDamping,
Chain.AngularDamping,
Chain.Position,
Chain.Angle,
Chain.Vertices,
Chain.Friction,
Chain.Restitution,
Chain.SubShapes,
Chain.SubShapes,
Chain.Name)..string.format([[
	Loop = function(data,itemDict)
		if not data[%d] or #data[%d] < 3 then return end
		local bodyDef = oBodyDef()
		bodyDef.type = data[%d]
		bodyDef.isBullet = data[%d]
		bodyDef.gravityScale = data[%d]
		bodyDef.fixedRotation = data[%d]
		bodyDef.linearDamping = data[%d]
		bodyDef.angularDamping = data[%d]
		bodyDef.position = data[%d]
		bodyDef.angle = data[%d]
		bodyDef:attachLoop(data[%d],data[%d],data[%d])
		if data[%d] then
			for _,subShape in ipairs(data[%d]) do
				loadData(subShape,bodyDef)
			end
		end
		itemDict:set(data[%d],bodyDef)
	end,
]],
Loop.Vertices,
Loop.Vertices,
Loop.Type,
Loop.Bullet,
Loop.GravityScale,
Loop.FixedRotation,
Loop.LinearDamping,
Loop.AngularDamping,
Loop.Position,
Loop.Angle,
Loop.Vertices,
Loop.Friction,
Loop.Restitution,
Loop.SubShapes,
Loop.SubShapes,
Loop.Name)..string.format([[
	SubRectangle = function(data,bodyDef)
		if data[%d] then
			bodyDef:attachPolygonSensor(data[%d],
				data[%d].width,data[%d].height,
				data[%d],data[%d])
		else
			bodyDef:attachPolygon(data[%d],
				data[%d].width,data[%d].height,
				data[%d],data[%d],data[%d],data[%d])
		end
	end,
]],
SubRectangle.Sensor,
SubRectangle.SensorTag,
SubRectangle.Size,
SubRectangle.Size,
SubRectangle.Center,
SubRectangle.Angle,
SubRectangle.Center,
SubRectangle.Size,
SubRectangle.Size,
SubRectangle.Angle,
SubRectangle.Density,
SubRectangle.Friction,
SubRectangle.Restitution)..string.format([[
	SubCircle = function(data,bodyDef)
		if data[%d] then
			bodyDef:attachCircleSensor(data[%d],data[%d],data[%d])
		else
			bodyDef:attachCircle(data[%d],data[%d],data[%d],data[%d],data[%d])
		end
	end,
]],
SubCircle.Sensor,
SubCircle.SensorTag,
SubCircle.Center,
SubCircle.Radius,
SubCircle.Center,
SubCircle.Radius,
SubCircle.Density,
SubCircle.Friction,
SubCircle.Restitution)..string.format([[
	SubPolygon = function(data,bodyDef)
		if not data[%d] or #data[%d] < 3 then return end
		if data[%d] then
			bodyDef:attachPolygonSensor(data[%d],data[%d])
		else
			bodyDef:attachPolygon(data[%d],data[%d],data[%d],data[%d])
		end
	end,
]],
SubPolygon.Vertices,
SubPolygon.Vertices,
SubPolygon.Sensor,
SubPolygon.SensorTag,
SubPolygon.Vertices,
SubPolygon.Vertices,
SubPolygon.Density,
SubPolygon.Friction,
SubPolygon.Restitution)..string.format([[
	SubChain = function(data,bodyDef)
		if not data[%d] or #data[%d] < 2 then return end
		bodyDef:attachChain(data[%d],data[%d],data[%d])
	end,
]],
SubChain.Vertices,
SubChain.Vertices,
SubChain.Vertices,
SubChain.Friction,
SubChain.Restitution)..string.format([[
	SubLoop = function(data,bodyDef)
		if not data[%d] or #data[%d] < 3 then return end
		bodyDef:attachLoop(data[%d],data[%d],data[%d])
	end,
]],
SubLoop.Vertices,
SubLoop.Vertices,
SubLoop.Vertices,
SubLoop.Friction,
SubLoop.Restitution)..string.format([[
	Distance = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:distance(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Distance.Name,
Distance.Collision,
Distance.BodyA,
Distance.BodyB,
Distance.AnchorA,
Distance.AnchorB,
Distance.Frequency,
Distance.Damping)..string.format([[
	Friction = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:friction(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Friction.Name,
Friction.Collision,
Friction.BodyA,
Friction.BodyB,
Friction.WorldPos,
Friction.MaxForce,
Friction.MaxTorque)..string.format([[
	Gear = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:gear(data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Gear.Name,
Gear.Collision,
Gear.JointA,
Gear.JointB,
Gear.Ratio)..string.format([[
	Spring = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:spring(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Spring.Name,
Spring.Collision,
Spring.BodyA,
Spring.BodyB,
Spring.Offset,
Spring.AngularOffset,
Spring.MaxForce,
Spring.MaxTorque,
Spring.CorrectionFactor)..string.format([[
	Prismatic = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:prismatic(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Prismatic.Name,
Prismatic.Collision,
Prismatic.BodyA,
Prismatic.BodyB,
Prismatic.WorldPos,
Prismatic.Axis,
Prismatic.Lower,
Prismatic.Upper,
Prismatic.MaxMotorForce,
Prismatic.MotorSpeed)..string.format([[
	Pulley = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:pulley(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Pulley.Name,
Pulley.Collision,
Pulley.BodyA,
Pulley.BodyB,
Pulley.AnchorA,
Pulley.AnchorB,
Pulley.GroundA,
Pulley.GroundB,
Pulley.Ratio)..string.format([[
	Revolute = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:revolute(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Revolute.Name,
Revolute.Collision,
Revolute.BodyA,
Revolute.BodyB,
Revolute.WorldPos,
Revolute.LowerAngle,
Revolute.UpperAngle,
Revolute.MaxMotorTorque,
Revolute.MotorSpeed)..string.format([[
	Rope = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:rope(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Rope.Name,
Rope.Collision,
Rope.BodyA,
Rope.BodyB,
Rope.AnchorA,
Rope.AnchorB,
Rope.MaxLength)..string.format([[
	Weld = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:weld(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Weld.Name,
Weld.Collision,
Weld.BodyA,
Weld.BodyB,
Weld.WorldPos,
Weld.Frequency,
Weld.Damping)..string.format([[
	Wheel = function(data,itemDict)
		itemDict:set(data[%d],
			oJointDef:wheel(data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d],data[%d]))
	end,
]],
Wheel.Name,
Wheel.Collision,
Wheel.BodyA,
Wheel.BodyB,
Wheel.WorldPos,
Wheel.Axis,
Wheel.MaxMotorTorque,
Wheel.MotorSpeed,
Wheel.Frequency,
Wheel.Damping)..[[
}

return {create=create,load=load}
]]

oContent:saveToFile(oContent.writablePath.."oBodyLoader.lua",loaderCodes)
