Dorothy!
Class,property = unpack require "class"
ViewPanelView = require "View.Control.Operation.ViewPanel"
ViewItem = require "Control.Operation.ViewItem"
Model = require "Data.Model"

Class
	__partial: (args)=> ViewPanelView args
	__init: (args)=>
		{:width,:height} = @
		itemW = 120
		itemH = 40
		viewSize = CCSize.zero
		offsetY = 0
		drawNode = nil
		sceneData = nil
		@items = nil
		@_selectedItem = nil

		reorderChildItems = (itemData)->
			item = @items[itemData]
			switch itemData.typeName
				when "PlatformWorld"
					{:x,:y} = item.position
					y -= 2*(itemH+10)
					if itemData.ui.children
						y -= (itemH+10)*#itemData.ui.children
					if itemData.children
						for i,childData in ipairs itemData.children
							childItem = @items[childData]
							y -= (itemH+10)
							childItem.position = oVec2 x+10,y
							if childData.children
								if not childItem.fold
									y -= (itemH+10)*#childData.children
								reorderChildItems childData
					@updateLine!
				else
					posX = item.fold and -200 or item.positionX+10
					posY = item.positionY-itemH-10
					for i,childData in ipairs itemData.children
						childItem = @items[childData]
						childItem.position = oVec2 posX,posY-(i-1)*(itemH+10)
			@viewSize = viewSize

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
					viewSize.height -= offset
					@viewSize = viewSize
					@updateLine!
					for _,it in pairs @items
						if it.positionY < item.positionY and it.visible
							it.scaleY = 0
							it\perform oScale 0.3,1,1,oEase.OutBack
					sleep 0.3
				else
					len = #itemData.children
					offset = len*(10+itemH)
					itemBottom = item.positionY-item.height/2
					for _,it in pairs @items
						if it.positionY < itemBottom
							it.positionY -= offset
					posX = item.fold and -200 or item.positionX+10
					posY = item.positionY-itemH-10
					for i,childData in ipairs itemData.children
						childItem = @items[childData]
						childItem.position = oVec2 posX,posY-(i-1)*(itemH+10)
					viewSize.height += offset
					@viewSize = viewSize
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
		handleFolding = (item)->
			if foldingItem and foldingItem == item
				foldingItem = nil
				@menu\unschedule!
				item.checked = true
				doFolding item
				if @_selectedItem ~= item
					if @_selectedItem
						@_selectedItem.checked = false
					@_selectedItem = item
					emit "Scene.ViewPanel.Select",item.itemData
			elseif item.itemData.children and #item.itemData.children > 0
				foldingItem = item
				@menu\schedule once ->
					sleep 0.3
					if @_selectedItem == nil
						emit "Scene.ViewPanel.Select",nil
					foldingItem = nil
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
				checkFolding item
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
			viewSize.width = x+realW/2+10
			viewSize.height = height-y+itemH/2+10

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
				extra = 2 + if not (itemUI and itemUI.fold) and itemData.ui.children and sceneData.children
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
			viewSize = CCSize.zero
			offsetY = @offset.y
			itemX = 10+itemW/2
			itemY = height-10-itemH/2
			traverseData data,itemX,itemY
			@viewSize = viewSize

		@gslot "Scene.DataLoaded",(data)->
			sceneData = data
			@menu\removeAllChildrenWithCleanup!
			@items = {}
			drawNode = CCDrawNode!
			@menu\addChild drawNode
			setupData data

		@gslot "Scene.ViewPanel.Pick",(itemData)->
			item = @items[itemData]
			if item and not item.checked
				item.checked = true
				itemTapped item

		@gslot "Scene.ViewPanel.Fold",(itemData)->
			return unless itemData
			switch itemData.typeName
				when "UILayer","Layer","World"
					item = @items[itemData]
					doFolding item if itemData.children and #itemData.children > 0
					emit "Scene.ViewPanel.Pick",itemData
				when "PlatformWorld","Camera"
					return
				else
					parentData = @items[itemData].parentData
					item = @items[parentData]
					doFolding item if parentData.children and #parentData.children > 0
					emit "Scene.ViewPanel.Pick",parentData

		@gslot "Scene.ViewPanel.FoldState",(args)->
			state = nil
			{:itemData,:handler} = args
			if itemData
				switch itemData.typeName
					when "UILayer","Layer","World"
						item = @items[itemData]
						if itemData.children and #itemData.children > 0
							state = (item.fold == true)
					when "PlatformWorld","Camera"
						state = nil
					else
						parentData = @items[itemData].parentData
						item = @items[parentData]
						if parentData.children and #parentData.children > 0
							state = (item.fold == true)
			handler state

		insertItem = (parentData,newData,targetData)->
			-- insert to data.children
			parentData.children = {} unless parentData.children
			index = #parentData.children+1
			if targetData
				for i,child in ipairs parentData.children
					if child == targetData
						index = i+1
						break
			table.insert parentData.children,index,newData
			-- make room for new item
			parentItem = @items[parentData]
			if parentData.typeName ~= "PlatformWorld"
				if not parentItem.fold
					lastChildData = parentData.children[#parentData.children]
					lastChildItem = lastChildData and @items[lastChildData] or @items[parentData]
					bottom = lastChildItem.positionY-itemH/2
					for _,item in pairs @items
						if item.positionY < bottom
							item.positionY -= (itemH+10)
			-- add new item
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
			-- reoder items
			reorderChildItems parentData
			-- adjust view size
			if not parentItem.fold
				viewSize.height += (itemH+10)
			@viewSize = viewSize
			@updateLine! if parentData.typeName ~= "PlatformWorld"
			index

		@gslot "Scene.ViewArea.Tap",(loc using nil)->
			return unless @menuEnabled
			if @_selectedItem and editor.selectedType
				itemData = @_selectedItem.itemData
				return if itemData.typeName == "Camera"
				parentData = @_selectedItem.parentData
				-- check new item is addable
				pos = nil
				switch editor.selectedType
					when "Body"
						return if switch itemData.typeName
							when "UILayer","PlatformWorld" then true
							else false
						pos = editor.viewArea.crossNode\convertToNodeSpace loc
					when "Layer","World"
						return if switch itemData.typeName
							when "Layer","World","PlatformWorld" then false
							else true
						pos = loc
					else
						return if itemData.typeName == "PlatformWorld"
						if parentData.typeName == "UILayer" or itemData.typeName == "UILayer"
							pos = loc
						else
							pos = editor.viewArea.crossNode\convertToNodeSpace loc
				-- create new item data
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
					when "Layer"
						newData = Model.Layer!
						newData.name = editor\getUsableName newData.name
					when "World"
						newData = Model.World!
						newData.name = editor\getUsableName newData.name

				insertAtParentLevel = ->
					insertItem itemData,newData
					parent = editor\getItem itemData
					child = newData parent,#itemData.children
					if child
						parent\addChild child
					doFolding @_selectedItem if @_selectedItem.fold
				insertAtChildLevel = ->
					index = insertItem parentData,newData,itemData
					parent = editor\getItem parentData
					child = newData parent,index
					if child
						parent\addChild child
						children = parent.children
						children\removeLast!
						children\insert child,index
					elseif parentData.typeName == "PlatformWorld"
						if index < #parentData.children
							for i = #parentData.children,index,-1
								parent\swapLayer i,i+1
					parentItem = @items[parentData]
					doFolding parentItem if parentItem.fold
				switch editor.selectedType
					when "Layer","World"
						switch itemData.typeName
							when "PlatformWorld"
								insertAtParentLevel!
							else
								insertAtChildLevel!
						{:width,:height} = CCDirector.winSize
						length = oVec2(width,height).length
						circle = with CCDrawNode!
							\drawDot oVec2.zero,5,ccColor4 0xff00ffff
							.position = pos
							\perform CCSequence {
								CCSpawn {
									oScale 1,length/10,length/10,oEase.OutQuad
									oOpacity 1,0,oEase.OutQuad
								}
								CCCall -> circle.parent\removeChild circle
							}
						editor.items.UI\addChild circle
					else
						switch itemData.typeName
							when "Layer","UILayer","World"
								insertAtParentLevel!
							else
								insertAtChildLevel!
				emit "Scene.ViewPanel.Pick",newData

		@gslot "Scene.EditMenu.Up",->
			return unless @_selectedItem
			itemData = @_selectedItem.itemData
			parentData = @_selectedItem.parentData
			index = 1
			for i,v in ipairs parentData.children
				if itemData == v
					index = i
					break
			if index > 1
				parentData.children[index] = parentData.children[index-1]
				parentData.children[index-1] = itemData
				parent = editor\getItem parentData
				if parentData.typeName == "PlatformWorld"
					parent\swapLayer index,index-1
				else
					parent.children\exchange index,index-1
				reorderChildItems parentData

		@gslot "Scene.EditMenu.Down",->
			return unless @_selectedItem
			itemData = @_selectedItem.itemData
			parentData = @_selectedItem.parentData
			index = #parentData.children
			for i,v in ipairs parentData.children
				if itemData == v
					index = i
					break
			if index < #parentData.children
				parentData.children[index] = parentData.children[index+1]
				parentData.children[index+1] = itemData
				parent = editor\getItem parentData
				if parentData.typeName == "PlatformWorld"
					parent\swapLayer index,index+1
				else
					parent.children\exchange index,index+1
				reorderChildItems parentData

		@gslot "Scene.EditMenu.Top",->
			return unless @_selectedItem
			itemData = @_selectedItem.itemData
			parentData = @_selectedItem.parentData
			index = 1
			for i,v in ipairs parentData.children
				if itemData == v
					index = i
					break
			if index > 1
				table.remove parentData.children,index
				table.insert parentData.children,1,itemData
				parent = editor\getItem parentData
				if parentData.typeName == "PlatformWorld"
					prev = index-1
					while prev >= 1
						parent\swapLayer index,prev
						prev -= 1
						index -= 1
				else
					prev = index-1
					while prev >= 1
						parent.children\exchange index,prev
						prev -= 1
						index -= 1
				reorderChildItems parentData

		@gslot "Scene.EditMenu.Bottom",->
			return unless @_selectedItem
			itemData = @_selectedItem.itemData
			parentData = @_selectedItem.parentData
			count = #parentData.children
			index = count
			for i,v in ipairs parentData.children
				if itemData == v
					index = i
					break
			if index < count
				table.remove parentData.children,index
				table.insert parentData.children,itemData
				parent = editor\getItem parentData
				if parentData.typeName == "PlatformWorld"
					nextIndex = index+1
					while nextIndex <= count
						parent\swapLayer index,nextIndex
						nextIndex += 1
						index += 1
				else
					nextIndex = index+1
					while nextIndex <= count
						parent.children\exchange index,nextIndex
						nextIndex += 1
						index += 1
				reorderChildItems parentData

		@gslot "Scene.EditMenu.Delete",->
			return unless @_selectedItem
			itemData = @_selectedItem.itemData
			switch itemData.typeName
				when "Camera","UILayer","PlatformWorld"
					return
			-- TODO: check item reference needed here
			parentData = @_selectedItem.parentData
			editor\removeData itemData,parentData

			item = @items[itemData]
			@menu\removeChild item
			@items[itemData] = nil
			if itemData.children
				for child in *itemData.children
					item = @items[child]
					@menu\removeChild item
					@items[child] = nil
			reorderChildItems editor.sceneData
			@_selectedItem = nil

