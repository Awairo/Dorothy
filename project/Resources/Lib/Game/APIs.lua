Dorothy()
local Dummy,DummyNoDefault = unpack(require("Lib.Game.Dummy"))
local Trigger = require("Lib.Game.Trigger")
local Game = require("Lib.Game.Game")

local type = type
local select = select
local ctype = tolua.type
local inf = math.huge
local ninf = -inf

--[[
#define MT_DEL 1
#define MT_CALL 2
#define MT_SUPER 3
#define MT_GET 4
#define MT_SET 5
#define MT_EQ 6
#define MT_ADD 7
#define MT_SUB 8
#define MT_MUL 9
#define MT_DIV 10
#define MT_LT 11
#define MT_LE 12
]]
local MT_GET = 4
local MT_SET = 5

local function IsValidNumber(x)
	return x == x and ninf < x and x < inf
end

local function InvalidNumber(x)
	if x ~= x or ninf > x or x > inf then
		return true
	end
	return false
end

local function InvalidNumbers(...)
	for i = 1,select("#",...) do
		local x = select(i,...)
		if x ~= x or ninf > x or x > inf then
	 		return true
		end
	end
	return false
end

local function IsValid(x)
	if type(x) == "number" then
		return IsValidNumber(x)
	else
		return x ~= Dummy
	end
end

local function GetItem(typeName)
	return setmetatable({},{
		__index = function(_,key)
			local item = Game.instance:getItem(key)
			if ctype(item) == typeName then
				return item
			end
			return Dummy
		end,
	})
end

local function GetSlice(sensor)
	local targetBody
	local SliceItem = setmetatable({},{
		__index = function(_,key)
			local item = targetBody.data[key]
			if not item or (sensor and not item.sensor) then
				return Dummy
			end
			return item
		end,
		__call = function(_,body)
			targetBody = body
			return self
		end,
	})
	local Slice = setmetatable({},{
		__index = function(_,key)
			local item = Game.instance:getItem(key)
			if ctype(item) == "CCNode" then
				return SliceItem(item)
			end
			return DummyNoDefault
		end,
	})
	return Slice
end

local CCNode_perform = CCNode.perform

local APIs
APIs = setmetatable({
	Load = function()
		CCNode[MT_GET].scale = function(self)
			return oVec2(self.scaleX,self.scaleY)
		end
		CCNode[MT_SET].scale = function(self,value)
			self.scaleX = value.x
			self.scaleY = value.y
		end
		CCNode[MT_GET].skew = function(self)
			return oVec2(self.skewX,self.skewY)
		end
		CCNode[MT_SET].skew = function(self,value)
			self.skewX = value.x
			self.skewY = value.y
		end
		CCNode.perform = function(self,...)
			local action
			if select("#",...) > 1 then
				action = CCSequence{...}
			else
				action = select(1,...)
			end
			CCNode_perform(self,action)
			return action.duration or 0
		end
	end,

	Unload = function()
		CCNode[MT_GET].scale = nil
		CCNode[MT_SET].scale = nil
		CCNode[MT_GET].skew = nil
		CCNode[MT_SET].skew = nil
		CCNode.perform = CCNode_perform
	end,

	Trigger = Trigger,

	Event = function(event)
		return event
	end,

	NoEvent = function()
		return Game.instance:slot("NoEvent")
	end,

	SceneInitialized = function()
		return Game.instance:slot("Initialized")
	end,

	TimeCycled = Class {
		__init = function(self,interval)
			if IsValidNumber(interval) then
				self._slots = Game.instance:slot("Update")
				self._interval = interval
			end
		end,
		add = function(self,handler)
			if not self._slots then return end
			if not self._handler then
				self._handler = once(function()
					repeat
						sleep(self._interval)
						thread(handler)
					until false
				end)
			end
			self._slots:add(self._handler)
		end,
		remove = function(self)
			if not self._slots then return end
			self._slots:remove(self._handler)
		end,
	},

	TimeElapsed = Class {
		__init = function(self,interval)
			if IsValidNumber(interval) then
				self._slots = Game.instance:slot("Update")
				self._interval = interval
				self._fired = false
			end
		end,
		add = function(self,handler)
			if self._fired or not self._slots then return end
			if not self._handler then
				self._handler = once(function()
					sleep(self._interval)
					thread(handler)
					self._slots:remove(self._handler)
					self._fired = true
				end)
			end
			self._slots:add(self._handler)
		end,
		remove = function(self)
			if self._fired or not self._slots then return end
			self._slots:remove(self._handler)
		end,
	},

	BodyEnter = Class {
		__init = function(self,sensor)
			if not sensor then return end
			self._slots = sensor:slot("BodyEnter")
			self.passValues = true
		end,
		add = function(self,handler)
			if not self._slots then return end
			if not self._handler then
				self._handler = function(body,sensor)
					handler(body,sensor.tag)
				end
			end
			self._slots:add(self._handler)
		end,
		remove = function(self)
			if not self._slots then return end
			self._slots:remove(self._handler)
		end,
	},

	Condition = function(condition)
		return condition
	end,

	Action = function(condition)
		return condition
	end,

	DoNothing = function() end,
	IsValid = IsValid,
	Sleep = sleep,
	Wait = function(item)
		local itemType = ctype(item)
		if itemType == "oModel" then
			while item.playing do
				sleep()
			end
		elseif itemType == "number" then
			sleep(item)
		end
		return item
	end,
	Print = print,

	Effect = GetItem("oEffect"),
	Sprite = GetItem("CCSprite"),
	Model = GetItem("oModel"),
	Body = GetItem("CCNode"),
	Layer = GetItem("oNode3D"),
	Slice = GetSlice("CCNode",false),
	Sensor = GetSlice("CCNode",true),

	Point = oVec2,

	Loop = function(start,stop,step,work)
		if InvalidNumbers(start,stop,step) then return end
		if (start < stop and step > 0) or (start > stop and step < 0) then
			for i = start,stop,step do
				work(i)
			end
		end
	end,

	CreateModel = function(modelType, position, layer, angle, look, animation, loop)
		if InvalidNumber(angle) or not layer then return nil end
		local modelFile = Game.instance.gamePath..modelType
		if oContent:exist(modelFile) then
			local model = oModel(modelFile)
			model.position = position
			model.angle = angle
			model.look = look
			model.loop = loop
			model:play(animation)
			layer:addChild(model)
			return model
		end
		return Dummy
	end,

	DestroyModel = function(model)
		if model.parent then
			model.parent:removeChild(model)
		end
	end,

	UnitAction = function(name, priority, reaction, recovery, available, run, stop)
		if InvalidNumbers(priority, reaction, recovery) then return end
		oAction:add(name, priority, reaction, recovery, available, run, stop)
	end,

	AIRoot = function(name, ...)
		oAI:add(name,oSel{...})
	end,

	SelNode = function(...)
		return oSel{...}
	end,

	SeqNode = function(...)
		return oSeq{...}
	end,

	ConNode = function(name, condition)
		if condition then
			return oCon(condition)
		else
			return Game.instance:getCondition(name)
		end
	end,

	IsSensed = function(body,tag)
		if not body then return false end
		local sensor = body:getSensorByTag(tag)
		if sensor then
			return sensor.sensed
		end
		return false
	end,

	Sequence = CCSequence,
	Spawn = CCSpawn,
	Delay = CCDelay,
	Move = function(time,pos,easing)
		return oPos(time,pos.x,pos.y,easing)
	end,
	Scale = function(time,scale,easing)
		return oScale(time,scale.x,scale.y,easing)
	end,
},{
	__index=oEase
})

return APIs
