local Class = require("Class")
local CCScene = require("CCScene")
local classfield = require("classfield")
local CCDirector = require("CCDirector")
local cclog = require("cclog")

--[[
Usage:
-- Extend TestBase and override function run()

local MyTest = Class(TestBase)

function MyTest:run()
	print("Test is running.")
end
--]]

local TestBase = Class(CCScene,
{
	isTest = classfield(function()
		return true
	end),
})

function TestBase:run() -- override it
end

function TestBase:profile(name,work)
	--collectgarbage("collect")
	collectgarbage("stop")
	local startMem = collectgarbage("count")
	local startTime = CCDirector.eclapsedInterval
	work()
	local endTime = CCDirector.eclapsedInterval
	local endMem = collectgarbage("count")
	cclog("[%s] done! Time cost %.4f s. Memory cost %d KB.",name,endTime-startTime,endMem-startMem)
	collectgarbage("restart")
end

function TestBase:profileRun()
	local startTime = CCDirector.eclapsedInterval
	self:run()
	local endTime = CCDirector.eclapsedInterval
	print("Test done. Time cost "..string.format("%.4f",endTime-startTime).." s.")
end

function TestBase:enterScene()
	CCDirector:run(self)
end

return TestBase
