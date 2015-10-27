Dorothy!
Class,property = unpack require "class"
ViewPanelView = require "View.Control.Operation.ViewPanel"
ViewItem = require "Control.Operation.ViewItem"
Model = require "Data.Model"

Class
	__partial: (args)=> ViewPanelView args
	__init: (args)=>
		width = @width
		height = @height
		itemW = 120
		itemH = 40
		right = 0
		bottom = 0
		offsetY = 0
		drawNode = nil
		sceneData = nil
		@items = nil
		@_selectedItem = nil

		doFolding = (item)->
			item.fold = not item.fold
			itemData = item.itemData
			thread ->
				@menuEnabled = false
				if item.fold
					for child in *itemData.children
						@items[child]\perform oScale 0.3,1,0,oEase.OutQuad
					sleep 0.3
					for child in *itemData.children
						@items[child].positionX = -200
					len = #itemData.children
					offset = len*(10+itemH)
					lastChild = @items[itemData.children[len]]
					lastChildBottom = lastChild.positionY-lastChild.height/2
					for _,it in pairs @items
						if it.positionY < lastChildBottom
							it.positionY += offset
					viewSize = @viewSize
					@viewSize = CCSize viewSize.width,viewSize.height-offset
					@updateLine!
					for _,it in pairs @items
						if it.positionY < item.positionY and it.visible
							it.scaleY = 0
							it\perform oScale 0.3,1,1,oEase.OutBack
					sleep 0.3
				else
					for child in *itemData.children
						@items[child].positionX = 400
					len = #itemData.children
					offset = len*(10+itemH)
					itemBottom = item.positionY-item.height/2
					for _,it in pairs @items
						if it.positionY < itemBottom and it.positionX < 400
							it.positionY -= offset
					for child in *itemData.children
						@items[child].positionX = width-10-@items[child].width/2
					viewSize = @viewSize
					@viewSize = CCSize viewSize.width,viewSize.height+offset
					@updateLine!
					for child in *itemData.children
						with @items[child]
							if .visible
								\perform oScale 0.3,1,1,oEase.OutBack
							else
								.scaleY = 1
					sleep 0.3
				@menuEnabled = true

		foldingItem = nil
		foldingRoutine = nil
		handleFolding = (item)->
			if foldingItem and foldingItem == item
				foldingItem = nil
				if foldingRoutine
					oRoutine\remove foldingRoutine
					foldingRoutine = nil
				item.checked = true
				if @_selectedItem ~= item
					if @_selectedItem
						@_selectedItem.checked = false
					@_selectedItem = item
					emit "Scene.ViewPanel.Select",item.itemData
				doFolding item
			elseif item.itemData.children and #item.itemData.children > 0
				foldingItem = item
				foldingRoutine = thread ->
					sleep 0.3
					if @_selectedItem == nil
						emit "Scene.ViewPanel.Select",nil
					foldingItem = nil
					foldingRoutine = nil
			elseif @_selectedItem == nil
				emit "Scene.ViewPanel.Select",nil

		checkFolding = (item)->
			switch item.itemData.typeName
				when "UILayer","Layer","World"
					handleFolding item
				else
					if @_selectedItem == nil
						emit "Scene.ViewPanel.Select",nil

		itemTapped = (item)->
			if item.checked
				if @_selectedItem
					@_selectedItem.checked = false
				@_selectedItem = item
				emit "Scene.ViewPanel.Select",item.itemData
			elseif @_selectedItem == item
				@_selectedItem = nil
			checkFolding item

		addItem = (x,y,text,data,parentData)->
			realW = width-(x-itemW/2)-10
			realX = (x-itemW/2)+realW/2
			item = ViewItem {
				text:text
				x:realX
				y:y
				width:realW
				height:itemH
			}
			item.itemData = data
			item.parentData = parentData
			item\slots "Tapped",itemTapped
			@menu\addChild item
			@items[data] = item
			right = math.max x+realW/2+10,right
			bottom = math.max height-y+itemH/2+10,bottom

		getChildCount = (parent)->
			item = @items[parent]
			return 0 if item and item.fold
			children = parent.children
			if children
				count = #children
				for child in *children
					count += getChildCount child
				count
			else
				0

		drawVLine = (itemData,itemCount)->
			item = @items[itemData]
			return if item and item.fold
			itemCount or= 0
			childCount = 0
			children = itemData.children
			if children
				for i = 1,#children-1
					itemCount += 1
					itemCount += getChildCount children[i]
				itemCount += 1
				childCount = itemCount
				childCount += getChildCount children[#children]
			if itemCount > 0
				item = @items[itemData]
				startX = item.positionX-item.width/2+10
				startY = item.positionY-itemH/2-offsetY
				endX = startX
				endY = startY-(itemH/2+10)-(itemCount-1)*(itemH+10)
				drawNode\drawSegment oVec2(startX,startY),oVec2(endX,endY),0.5,ccColor4!
				endY = startY-(itemH/2+10)-(childCount-1)*(itemH+10)
				itemH/2+startY-endY
			else
				0

		drawHLine = (itemData)->
			item = @items[itemData]
			return if item.positionX < 0
			startX = item.positionX-item.width/2-10
			startY = item.positionY-offsetY
			endX = startX+10
			endY = startY
			drawNode\drawSegment oVec2(startX,startY),oVec2(endX,endY),0.5,ccColor4!

		traverseData = (itemData,x,y,parentData)->
			if itemData == sceneData
				addItem x,y,"Scene",itemData
				extra = 2 + if itemData.ui.children
					#itemData.ui.children
				else
					0
				dV = drawVLine itemData,extra
				x += 20
				y -= (10+itemH)
				addItem x,y,"Camera",itemData.camera,itemData
				drawVLine itemData.camera
				drawHLine itemData.camera
				y -= (10+itemH)
				addItem x,y,"UI",itemData.ui,itemData
				uiX = x+20
				uiY = y
				if itemData.ui.children
					for child in *itemData.ui.children
						uiY -= (10+itemH)
						uiY -= traverseData child,uiX,uiY,itemData.ui
				y -= drawVLine itemData.ui
				drawHLine itemData.ui
				if itemData.children
					for child in *itemData.children
						y -= (10+itemH)
						y -= traverseData child,x,y,itemData
				dV
			else
				addItem x,y,itemData.name,itemData,parentData
				dV = drawVLine itemData
				drawHLine itemData
				x += 20
				if itemData.children
					for child in *itemData.children
						y -= (10+itemH)
						y -= traverseData child,x,y,itemData
				dV

		updateLine = (itemData)->
			if itemData == sceneData
				itemUI = @items[itemData.ui]
				extra = 2 + if not (itemUI and itemUI.fold) and itemData.ui.children
					#itemData.ui.children
				else
					0
				drawVLine itemData,extra
				drawVLine itemData.camera
				drawHLine itemData.camera
				if itemData.ui.children
					for child in *itemData.ui.children
						updateLine child
				drawVLine itemData.ui
				drawHLine itemData.ui
				if itemData.children
					for child in *itemData.children
						updateLine child
			else
				drawVLine itemData
				drawHLine itemData
				if itemData.children
					for child in *itemData.children
						updateLine child

		@updateLine = =>
			drawNode\clear!
			offsetY = @offset.y
			updateLine sceneData

		setupData = (data)->
			right = 0
			bottom = 0
			offsetY = @offset.y
			itemX = 10+itemW/2
			itemY = height-10-itemH/2
			traverseData data,itemX,itemY
			@viewSize = CCSize right,bottom

		@gslot "Scene.DataLoaded",(data)->
			sceneData = data
			@menu\removeAllChildrenWithCleanup!
			@items = {}
			drawNode = CCDrawNode!
			@menu\addChild drawNode
			setupData data

		insertItem = (parentData,newData,targetData)->
			parentData.children = {} unless parentData.children
			index = #parentData.children+1
			if targetData
				for i,child in ipairs parentData.children
					if child == targetData
						index = i
						break
			table.insert parentData.children,index,newData

			parentItem = @items[parentData]
			if not parentItem.fold
				lastChildData = parentData.children[#parentData.children]
				lastChildItem = lastChildData and @items[lastChildData] or @items[parentData]
				bottom = lastChildItem.positionY-itemH/2
				for _,item in pairs @items
					if item.positionY < bottom
						item.positionY -= (itemH+10)

			item = ViewItem {
				text:newData.name
				x:0
				y:0
				width:parentItem.width-20
				height:itemH
			}
			item.itemData = newData
			item.parentData = parentData
			item\slots "Tapped",itemTapped
			@menu\addChild item
			@items[newData] = item

			posX = parentItem.fold and -200 or parentItem.positionX+10
			posY = parentItem.positionY-itemH-10
			for i,childData in ipairs parentData.children
				childItem = @items[childData]
				childItem.position = oVec2 posX,posY-(i-1)*(itemH+10)

			viewSize = @viewSize
			viewSize.height += (itemH+10)
			@viewSize = viewSize
			@updateLine!
			index

		@gslot "Scene.ViewArea.Tap",(loc)->
			if @_selectedItem and editor.selectedType
				itemData = @_selectedItem.itemData
				pos = nil
				switch itemData.typeName
					when "Camera"
						return
					when "UILayer"
						pos = loc-editor.origin
						return if editor.selectedType == "Body"
					else
						pos = editor.viewArea.crossNode\convertToNodeSpace loc

				newData = nil
				switch editor.selectedType
					when "Sprite","Model","Body"
						newData = Model[editor.selectedType]!
						newData.file = editor.selectedItem
						newData.name = editor\getUsableName newData.name
						newData.position = pos
					when "Effect"
						newData = Model.Effect!
						newData.effect = editor.selectedItem
						newData.name = editor\getUsableName newData.name
						newData.position = pos

				switch itemData.typeName
					when "Layer","UILayer","World"
						insertItem itemData,newData
						name = if itemData.typeName == "UILayer"
							"UI"
						else
							itemData.name
						parentInst = editor.items[name]
						child = newData parentInst,#itemData.children
						if child
							parentInst\addChild child
					else
						parentData = @_selectedItem.parentData
						index = insertItem parentData,newData,itemData
						name = switch parentData.typeName
							when "PlatformWorld"
								"Scene"
							when "UILayer"
								"UI"
							else
								parentData.name
						parentInst = editor.items[name]
						child = newData parentInst,index
						if child
							parentInst\addChild child--insertChild
