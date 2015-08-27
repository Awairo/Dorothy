local require = using("ActionEditor.Script")
local CCDirector = require("CCDirector")
local oEditor = require("oEditor")

oEditor.quitable = CCDirector.sceneStackSize > 0
oEditor:slots("Quit",function()
	CCDirector:popScene()
end)

CCDirector:run(oEditor)
