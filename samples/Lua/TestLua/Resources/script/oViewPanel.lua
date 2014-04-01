local function oViewPanel()
	local winSize = CCDirector.winSize
	local borderSize = CCSize(160,310*winSize.height/600)
	local viewWidth = 0
	local viewHeight = 0
	local moveY = 0
	local moveX = 0
	local totalDelta = oVec2.zero
	local padding = 100
	local startPos = oVec2.zero
	local time = 0
	local _s = oVec2.zero
	local _v = oVec2.zero
	local deltaMoveLength = 0
	local function initValues()
		viewWidth = 0
		viewHeight = 0
		moveY = 0
		moveX = 0
		totalDelta = oVec2.zero
		startPos = oVec2.zero
		time = 0
		_s = oVec2.zero
		_v = oVec2.zero
		deltaMoveLength = 0
	end
	local panel = CCLayer()
	panel.anchorPoint = oVec2.zero
	panel.contentSize = borderSize
	panel.opacity = 0.3
	panel.touchEnabled = true
	panel.position = oVec2(winSize.width-170,winSize.height-borderSize.height-10)
	
	local border = CCDrawNode()
	border:drawPolygon(
	{
		oVec2(0,0),
		oVec2(borderSize.width,0),
		oVec2(borderSize.width,borderSize.height),
		oVec2(0,borderSize.height)
	},ccColor4(0x88000000),0.5,ccColor4(0xffffffff))
	panel:addChild(border)

	local stencil = CCDrawNode()
	stencil:drawPolygon(
	{
		oVec2(0,0),
		oVec2(borderSize.width-2,0),
		oVec2(borderSize.width-2,borderSize.height-2),
		oVec2(0,borderSize.height-2)
	},ccColor4(0xffffffff),0,ccColor4(0x00000000))
	stencil.position = oVec2(1,1)

	local view = CCClipNode(stencil)
	panel:addChild(view)

	local menu = CCMenu(false)
	menu.contentSize = borderSize
	menu.anchorPoint = oVec2(0,1)
	menu.positionY = borderSize.height

	local function updateReset(deltaTime)
		local children = menu.children
		if not children then return end

		local xVal = nil
		local yVal = nil
		time = time + deltaTime
		local t = time/4.0
		if t > 1.0 then t = 1.0 end
		--[[if startPos.x > 0 then
			xVal = totalDelta.x
			totalDelta.x = oEase:func(oEase.OutExpo,t,startPos.x,0-startPos.x)
			xVal = totalDelta.x - xVal
		end]]
		if startPos.x < moveX then
			xVal = totalDelta.x
			totalDelta.x = oEase:func(oEase.OutBack,t,startPos.x,moveX-startPos.x)
			xVal = totalDelta.x - xVal
		end
		if startPos.y < 0 then
			yVal = totalDelta.y
			totalDelta.y = oEase:func(oEase.OutBack,t,startPos.y,0-startPos.y)
			yVal = totalDelta.y - yVal
		end
		if startPos.y > moveY then
			yVal = totalDelta.y
			totalDelta.y = oEase:func(oEase.OutBack,t,startPos.y,moveY-startPos.y)
			yVal = totalDelta.y - yVal
		end
		
		for i = 1, children.count do
			local node = tolua.cast(children:get(i), "CCNode")
			node.position = node.position + oVec2(xVal and xVal or 0, yVal and yVal or 0)
		end
		
		if t == 1.0 then
			panel:unscheduleUpdate()
			--panel.touchEnabled = true
			--menu.touchEnabled = true
			panel:hide()
		end
	end

	local function isReseting()
		if --[[totalDelta.x > 0 or]] totalDelta.x < moveX or totalDelta.y > moveY or totalDelta.y < 0 then
			return true
		end
		return false
	end

	local function startReset()
		startPos = totalDelta
		time = 0
		--panel.touchEnabled = false
		--menu.touchEnabled = false
		panel:scheduleUpdate(updateReset)
	end

	local function setOffset(deltaPos, touching)
		local children = menu.children
		if not children then return end

		local newPos = totalDelta + deltaPos
		
		if touching then
			if newPos.x > 0 then
				newPos.x = 0--padding 
			elseif newPos.x-moveX < -padding then
				newPos.x = moveX-padding
			end
			if newPos.y < -padding then
				newPos.y = -padding
			elseif moveY-newPos.y < -padding then
				newPos.y = moveY+padding
			end
			deltaPos = newPos - totalDelta
			
			local lenY = 0
			local lenX = 0
			if newPos.y < 0 then
				lenY = -newPos.y/padding
			elseif newPos.y > moveY then
				lenY = (newPos.y-moveY)/padding
			end
			--[[if newPos.x > 0 then
				lenX = newPos.x/padding
			else]]if newPos.x < moveX then
				lenX = (moveX-newPos.x)/padding
			end
			if lenY > 0 then
				local v = 3*lenY
				deltaPos.y = deltaPos.y / (v > 1 and v*v or 1)
			end
			if lenX > 0 then
				local v = 3*lenX
				deltaPos.x = deltaPos.x / (v > 1 and v*v or 1)
			end
		else
			if newPos.x > 0 then
				newPos.x = 0
			elseif newPos.x < moveX then
				newPos.x = moveX
			end
			if newPos.y < -padding then
				newPos.y = -padding
			elseif newPos.y > moveY+padding then
				newPos.y = moveY+padding
			end
			deltaPos = newPos - totalDelta
		end
		
		if viewWidth < borderSize.width then deltaPos.x = 0 end
		if viewHeight < borderSize.width then deltaPos.y = 0 end

		totalDelta = totalDelta + deltaPos

		for i = 1, children.count do
			local node = tolua.cast(children:get(i), "CCNode")
			node.position = node.position + deltaPos
		end
		
		if not touching and (newPos.y < -padding*0.5 or newPos.y > moveY+padding*0.5) then
			startReset()
		end
	end
	view:addChild(menu)

	local function oImageView(size, x, y, clipStr, tapped)
		local borderSelected = CCDrawNode()
		local borderHalfSize = size*0.5+1
		borderSelected:drawPolygon(
		{
			oVec2(-borderHalfSize,-borderHalfSize),
			oVec2(borderHalfSize,-borderHalfSize),
			oVec2(borderHalfSize,borderHalfSize),
			oVec2(-borderHalfSize,borderHalfSize)
		},ccColor4(0x00000000),1,ccColor4(0xff00ffff))
		borderSelected.position = oVec2(size*0.5,size*0.5)
		borderSelected.visible = false
		
		local border = CCDrawNode()
		border:drawPolygon(
		{
			oVec2(0,0),
			oVec2(size,0),
			oVec2(size,size),
			oVec2(0,size)
		},ccColor4(0x88000000),0,ccColor4(0x00000000))

		border:addChild(oLine(
		{
			oVec2(0,0),
			oVec2(size,0),
			oVec2(size,size),
			oVec2(0,size),
			oVec2(0,0)
		},ccColor4(0xffffffff)))
		
		local menuItem = CCMenuItem()
		menuItem.anchorPoint = oVec2(0,1)
		menuItem.contentSize = CCSize(size,size)
		menuItem.position = oVec2(x, y)
		menuItem:addChild(borderSelected)
		menuItem:addChild(border)

		local isSelected = false
		local seqAnim = CCSequence(
		{
			oScale(0.15,1.3,1.3,oEase.OutSine),
			oScale(0.15,1.0,1.0,oEase.InSine)
		})
		menuItem.select = function(self,selected)
			isSelected = selected
			borderSelected.visible = selected
			if selected then
				borderSelected:runAction(seqAnim)
				border.color = ccColor3(0x00ffff)
			else
				border.color = ccColor3(0xffffff)
			end
		end
		menuItem:registerTapHandler(
			function(eventType, self)
				if eventType == CCMenuItem.TapBegan then
				elseif eventType == CCMenuItem.TapEnded then
				elseif eventType == CCMenuItem.Tapped then
					menuItem:select(true)
					if tapped then
						tapped(menuItem,isSelected)
					end
				end
			end)
		if clipStr ~= "" then
			local sprite = CCSprite(clipStr)
			local contentSize = sprite.contentSize
			local scale = contentSize.width > contentSize.height and (size-2)/contentSize.width or (size-2)/contentSize.height
			sprite.scaleX = scale
			sprite.scaleY = scale
			sprite.position = oVec2(size*0.5,size*0.5)
			menuItem:addChild(sprite)
		else
			local label = CCLabelTTF("Empty","Arial",16)
			label.color = ccColor3(0x00ffff)
			label.position = oVec2(size*0.5, size*0.5)
			label.texture.antiAlias = false
			menuItem:addChild(label)
		end
		return menuItem
	end
	
	local opacity = oOpacity(0.5,0.3,oEase.InExpo)
	panel.show = function(self)
		if not opacity.done then
			self:stopAction(opacity)
		end
		self.opacity = 1.0
	end
	panel.hide = function(self)
		self:runAction(opacity)
	end

	local function updateSpeed(deltaTime)
		if _s == oVec2.zero then
			return
		end
		_v = _s / deltaTime
		_s = oVec2.zero
	end
	local function updatePos(deltaTime)
		local val = winSize.height*2
		local a = oVec2(_v.x > 0 and -val or val,_v.y > 0 and -val or val)
		
		local xR = _v.x > 0
		local yR = _v.y > 0
		
		_v = _v + a*deltaTime
		if _v.x < 0 == xR then _v.x = 0;a.x = 0 end
		if _v.y < 0 == yR then _v.y = 0;a.y = 0 end
		
		local ds = _v * deltaTime + a*(0.5*deltaTime*deltaTime)
		setOffset(ds, false)
		
		if _v == oVec2.zero then
			if isReseting() then
				startReset()
			else
				panel:hide()
				panel:unscheduleUpdate()
			end
		end
	end

	panel:registerTouchHandler(
		function(eventType, touch)
			--touch=CCTouch
			if touch.id ~= 0 then
				return false
			end
			if eventType == CCTouch.Began then
				if not CCRect(oVec2.zero, panel.contentSize):containsPoint(panel:convertToNodeSpace(touch.location)) then
					return false
				end
				
				panel:show()

				deltaMoveLength = 0
				menu.enabled = true
				panel:scheduleUpdate(updateSpeed)
			elseif eventType == CCTouch.Ended or eventType == CCTouch.Cancelled then
				menu.enabled = true
				if isReseting() then
					startReset()
				else
					if _v == oVec2.zero or deltaMoveLength <= 20 then
						panel:hide()
					else
						panel:scheduleUpdate(updatePos)
					end
				end
			elseif eventType == CCTouch.Moved then
				deltaMoveLength = deltaMoveLength + touch.delta.length
				_s = _s + touch.delta
				if deltaMoveLength > 20 then
					menu.enabled = false
					setOffset(touch.delta, true)
				end
			end
			return true
		end, false, 0, true)

	panel.updateImages = function(self, data, model)
		initValues()
		menu:removeAllChildrenWithCleanup()
		local clipFile = data[oSd.clipFile]
		local drawNode = CCDrawNode()
		menu:addChild(drawNode)
		local size = 60
		local indent = 10
		local function visitSprite(sp,x,y,node)
			local clip = sp[oSd.clip]
			local child = tolua.cast(node,tolua.type(node) == "CCNode" and "CCNode" or "CCSprite")
			sp[oSd.sprite] = child
			menu:addChild(
				oImageView(
					size,
					x, y,
					clip == -1 and "" or (clipFile.."|"..tostring(clip)),
					function(menuItem,selected)
						oEvent:send("ImageSelected",{sp,menuItem,child})
					end
				))
			local children = sp[oSd.children]
			local nextY = -size-indent
			local layer = 1
			local maxSubLayer = 0
			local lastLen = 0
			local childrenSize = #children
			for i = 1, childrenSize do
				drawNode:drawSegment(oVec2(x+indent,y+nextY-size*0.5),oVec2(x+indent*2,y+nextY-size*0.5),0.5,ccColor4(0xffffffff))
				local lenY, subLayer = visitSprite(children[i],x+indent*2,y+nextY,child.children:get(i))
				nextY = nextY + lenY
				if maxSubLayer < subLayer then maxSubLayer = subLayer end
				if i == childrenSize then
					lastLen = lenY
				end
			end
			if nextY < -size-indent then
				drawNode:drawSegment(oVec2(x+indent,y-size),oVec2(x+indent,y+nextY-lastLen-size*0.5),0.5,ccColor4(0xffffffff))
			end
			return nextY, layer+maxSubLayer
		end
		
		local height, layer = visitSprite(data,indent,borderSize.height-indent,tolua.cast(model.children:get(1),"CCNode"))
		viewHeight = -height+indent
		viewWidth = layer*indent*2+size
		moveY = viewHeight-borderSize.height
		moveX = borderSize.width-viewWidth
	end

	local function oImageOutline(node, withFrame)
		local w = node.contentSize.width
		local h = node.contentSize.height
		local outline = CCNode()
		local frame = oLine({},ccColor4(0xff00a2d8))
		if withFrame then
			frame:set(
			{
				oVec2(0,0),
				oVec2(w,0),
				oVec2(w,h),
				oVec2(0,h),
				oVec2(0,0),
			})
		end
		frame.acceptOpacity = false
		outline:addChild(frame)
		local anchor = oLine(
		{
			oVec2(0,-5),
			oVec2(5,0),
			oVec2(0,5),
			oVec2(-5,0),
			oVec2(0,-5)
		},ccColor4(0xffffffff))
		anchor:addChild(oLine(
		{
			oVec2(0,-5),
			oVec2(0,5)
		},ccColor4(0xffffffff)))
		anchor:addChild(oLine(
		{
			oVec2(-5,0),
			oVec2(5,0)
		},ccColor4(0xffffffff)))
		anchor.position = oVec2(w*node.anchorPoint.x, h*node.anchorPoint.y)
		anchor.acceptOpacity = false
		outline:addChild(anchor)
		
		local vs = {}
		local num = 30
		for i = 0, num do
			local angle = 2*math.pi*i/num
			table.insert(vs,oVec2(200*math.cos(angle),200*math.sin(angle)))
		end
		local line = oLine(vs,ccColor4(0xffffffff))
		anchor:addChild(line)
		anchor:addChild(oLine({oVec2(-200,0),oVec2(200,0)},ccColor4()))
		anchor:addChild(oLine({oVec2(0,-200),oVec2(0,200)},ccColor4()))
		outline.setNode = function(self, node, withFrame)
			local w = node.contentSize.width
			local h = node.contentSize.height
			if withFrame then
				frame:set(
				{
					oVec2(0,0),
					oVec2(w,0),
					oVec2(w,h),
					oVec2(0,h),
					oVec2(0,0),
				})
			else
				frame:set({})
			end
			anchor.position = oVec2(w*node.anchorPoint.x, h*node.anchorPoint.y)
		end
		return outline
	end

	local selectedItem = nil
	local outline = nil
	panel.listener = oListener("ImageSelected",
		function(args)
			local sp = args[1]
			local menuItem = args[2]
			local node = args[3]
			local aDefs = sp[oSd.animationDefs]
			local aNames = oEditor.data[oSd.animationNames]
			local animation = aDefs[aNames[oEditor.animation]+1]

			oEditor.animationData = animation

			if outline then
				outline.visible = (selectedItem ~= menuItem)
			end

			if selectedItem then
				selectedItem:select(false)
			end

			if selectedItem ~= menuItem then
				local withFrame = node.contentSize ~= CCSize.zero
				if not outline then
					outline = oImageOutline(node,withFrame)
				else
					outline.parent:removeChild(outline)
					outline:setNode(node,withFrame)
				end
				oEditor.sprite = node
				oEditor.spriteData = sp
				node:addChild(outline)
				if animation then
					if animation[oAd.type] == 1 then
						local d = 0
						oEditor.controlBar:clearCursors()
						for i = oAd.frameDefs, #animation do
							d = d + animation[i][oKd.duration]
							oEditor.controlBar:addCursor(d*60.0)
						end
					elseif animation[oAd.type] == 2 then
						--TODO Frame animation
					end
					oEditor.settingPanel:updateValues(0)
				else
					oEditor.controlBar:clearCursors()
					oEditor.settingPanel:updateValues(nil)
				end
				selectedItem = menuItem
			else
				selectedItem = nil
				oEditor.controlBar:clearCursors()
				oEditor.settingPanel:updateValues(nil)
			end
			
		end)
	return panel
end

return oViewPanel