Dorothy()

local BodyTest = class(require('Test.Case.TestBase'))

function BodyTest:__init()
    local groupZero = 0
    local groupOne = 1
    local groupTwo = 2

    local world = oWorld()
    world:setShouldContact(groupZero,groupOne,false)
    world:setShouldContact(groupZero,groupTwo,true)
    world:setShouldContact(groupOne,groupTwo,true)
    world.showDebug = true
    self:addChild(world)

    local terrainDef = oBodyDef()
    terrainDef.type = oBodyDef.Static
    terrainDef:attachPolygon(800,10)

    local terrain = oBody(terrainDef,world,oVec2(400,5))
    terrain.group = groupTwo
    world:addChild(terrain)

    local polygonDef = oBodyDef()
    polygonDef.type = oBodyDef.Dynamic
    polygonDef:attachPolygon({
    	oVec2(60,0),
    	oVec2(30,-30),
    	oVec2(-30,-30),
    	oVec2(-60,0),
    	oVec2(-30,30),
    	oVec2(30,30),
    },1,0.4,0.4)

    local polygon = oBody(polygonDef,world,oVec2(400,500),15)
    polygon.group = groupOne
    world:addChild(polygon)

    local circleDef = oBodyDef()
    circleDef.type = oBodyDef.Dynamic
    circleDef:attachCircle(60,1,0.4,0.4)

    local circle = oBody(circleDef,world,oVec2(450,800))
    circle.group = groupZero
    circle.angularRate = 90
    world:addChild(circle)
end

return BodyTest