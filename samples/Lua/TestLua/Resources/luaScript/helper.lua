Vec2s = function(verts)
	local vs = oVec2s(#verts)
	for i,v in ipairs(verts) do
		vs[i-1] = oVec2(v[1], v[2])
	end
	return vs
end

-- add the menu item for back to main menu
function CreateBackMenuItem()
    local label = CCLabelTTF("Exit", "Arial", 20)
    local menuItem = CCMenuItemLabel(label)
    menuItem:registerScriptTapHandler(function() CCDirector:stop() end)
	cclog("bad")
    local s = CCDirector.winSize
    local menu = CCMenu()
    menu:addChild(menuItem)
    menu.position = oVec2(0, 0)
    menuItem.position = oVec2(s.width - 50, 25)
	--CCView:setDesignResolution(1024, 768,CCView)
    return menu
end
