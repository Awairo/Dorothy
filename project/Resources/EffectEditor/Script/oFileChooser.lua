local require = using("EffectEditor.Script")
local CCDirector = require("CCDirector")
local CCSize = require("CCSize")
local oSelectionPanel = require("oSelectionPanel")
local CCDrawNode = require("CCDrawNode")
local oVec2 = require("oVec2")
local ccColor4 = require("ccColor4")
local oContent = require("oContent")
local oEditor = require("oEditor")
local CCLabelTTF = require("CCLabelTTF")
local ccColor3 = require("ccColor3")
local oOpacity = require("oOpacity")
local oButton = require("oButton")
local CCSequence = require("CCSequence")
local CCDelay = require("CCDelay")
local CCCall = require("CCCall")
local CCMenu = require("CCMenu")
local oBox = require("oBox")
local emit = require("emit")
local oTemplateChooser = require("oTemplateChooser")
local CCDictionary = require("CCDictionary")
local oCache = require("oCache")
local CCRect = require("CCRect")

local function oFileChooser(addExisted,newEffectName)
	local winSize = CCDirector.winSize
	local itemWidth = 120
	local itemNum = 3
	while (itemWidth+10)*itemNum+10 > winSize.width and itemNum > 1 do
		itemNum = itemNum - 1
	end
	local borderSize = CCSize((itemWidth+10)*itemNum+10,winSize.height*0.6)
	local panel = oSelectionPanel(borderSize)
	local menu = panel.menu
	local border = panel.border
	local halfBW = borderSize.width*0.5
	local halfBH = borderSize.height*0.5
	local background= CCDrawNode()
	background:drawPolygon(
	{
		oVec2(-halfBW,-halfBH),
		oVec2(halfBW,-halfBH),
		oVec2(halfBW,halfBH),
		oVec2(-halfBW,halfBH)
	},ccColor4(0xe5100000),0.5,ccColor4(0x88ffafaf))
	border:addChild(background,-1)

	local opMenu = CCMenu()
	opMenu.swallowTouches = true
	opMenu.contentSize = CCSize(130,60)
	opMenu.anchor = oVec2(1,0.5)
	opMenu.touchPriority = CCMenu.DefaultHandlerPriority-3
	opMenu.position = oVec2(winSize.width*0.5+borderSize.width*0.5+30,winSize.height*0.5+borderSize.height*0.5)
	panel:addChild(opMenu)

	local cancelButton = oButton("Cancel",17,60,false,
		70,0,
		function(item)
			opMenu.enabled = false
			panel:hide()
			item.enabled = false
		end)
	cancelButton.anchor = oVec2.zero
	local btnBk = CCDrawNode()
	btnBk:drawDot(oVec2.zero,30,ccColor4(0x22ffffff))
	btnBk.position = oVec2(30,30)
	cancelButton:addChild(btnBk,-1)
	opMenu:addChild(cancelButton)
	
	local listFile = oEditor.output..oEditor.listFile

	if not oContent:exist(listFile) then
		local file = io.open(listFile,"w")
		file:write("<A></A>")
		file:close()
	end
	local file = io.open(listFile,"r")
	for item in file:read("*a"):gmatch("%b<>") do
		if not item:sub(2,2):match("[A/]") then
			local line = item:gsub("%s","")
			local name = line:match("A=\"(.-)\"")
			local filename = line:match("B=\"(.-)\"")
			oEditor.items[name] = filename
		end
	end
	file:close()
	oCache.Effect:load(listFile)

	local n = 0
	local y = 0
	local xStart = 0 -- left
	local yStart = borderSize.height -- top
	local function resetPanel()
		local viewHeight = winSize.height*0.5+halfBH-y-5
		local viewWidth = borderSize.width
		local paddingX = 0
		local paddingY = 100
		panel:reset(viewWidth,viewHeight,paddingX,paddingY)
	end

	local pair = {true,true}
	local function updateAttr(name,value)
		pair[1] = name
		pair[2] = value
		emit("Effect.attr",pair)
	end

	local function loadEffect(name,file)
		oCache.Effect:load(listFile)
		local extension = string.match(file, "%.([^%.\\/]*)$")
		if extension == "par" then
			local dict = CCDictionary(oEditor.output..oEditor.prefix..file)
			local keys = dict:getKeys()
			local parData = {}
			local dataWrapper = {}
			setmetatable(dataWrapper,
			{
				__newindex = function(_,name,value)
					if not oEditor.dirty then
						oEditor.dirty = rawget(parData,name) ~= value
					end
					rawset(parData,name,value)
				end,
				__index = function(_,name)
					return rawget(parData,name)
				end,
				__call = function(_)
					return parData
				end
			})
			for _,v in ipairs(keys) do
				parData[v] = dict[v]
			end
			oEditor.effectData = dataWrapper
			if not parData.textureRectx then
				parData.textureRectx = 0
				parData.textureRecty = 0
				parData.textureRectw = 0
				parData.textureRecth = 0
			end
			for k,v in pairs(parData) do
				updateAttr(k,v)
			end
			updateAttr("name",name)
			updateAttr("file",file)
		elseif extension == "frame" then
			local frameFile = io.open(oEditor.output..oEditor.prefix..file)
			local fileName = file:match("[^\\/]*$")
			local filePath = oEditor.prefix..(#fileName < #file and file:sub(1,-#fileName-1) or "")
			local data = frameFile:read("*a")
			frameFile:close()
			local img = filePath..data:match("A%s*=%s*\"([^\"]*)\"")
			local interval = tonumber(data:match("<A.*B%s*=%s*\"([^\"]*)\""))
			local frameData = {file=img,interval=interval}
			for rc in data:gmatch("<B[^>]*A%s*=%s*\"([^\"]*)\"") do
				local rect = rc..","
				local nums = {}
				for num in rect:gmatch("(%d+),") do
					table.insert(nums,num)
				end
				table.insert(frameData,{rect = CCRect(nums[1],nums[2],nums[3],nums[4])})
			end
			oEditor.effectData = frameData
			updateAttr("name",name)
			updateAttr("file",file)
			updateAttr("interval",interval)
			emit("Effect.frameViewer.data",oEditor.effectData)
		end
		emit("Effect.viewArea.changeEffect",name)
	end

	if addExisted then
		local title = CCLabelTTF("Add Existing Effect","Arial",24)
		title.texture.antiAlias = false
		title.color = ccColor3(0x00ffff)
		title.anchor = oVec2(0.5,1)
		y = yStart-20
		title.position = oVec2(halfBW,y)
		menu:addChild(title)
		title.opacity = 0
		title:runAction(oOpacity(0.3,0.5))
		yStart = y-title.contentSize.height-20

		local files = {}
		local function getResources(path)
			local entries = oContent:getEntries(oEditor.output..oEditor.prefix..path,false)
			for i = 1,#entries do
				local extension = string.match(entries[i], "%.([^%.\\/]*)$")
				if extension then extension = string.lower(extension) end
				if extension == "par" or extension == "frame" then
					table.insert(files,path..entries[i])
				end
			end
			local folders = oContent:getEntries(oEditor.output..oEditor.prefix..path,true)
			for _,folder in ipairs(folders) do
				if folder ~= "." and folder ~= ".." then
					getResources(path..folder.."/")
				end
			end
		end
		getResources("")

		for i = 1,#files do
			n = n+1
			y = yStart-10-math.floor((n-1)/itemNum)*60
			local itemName = files[i]:match("([^\\/]*)%.[^%.\\/]*$")
			local name = #itemName > 10 and itemName:sub(1,7).."..." or itemName
			local ext = files[i]:match("%.([^%.\\/]*)$"):lower()
			name = name..(ext == "par" and "\n[Particle]" or "\n[Frame]")
			local button = oButton(
				name,
				17,
				itemWidth,50,
				xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
				function(item)
					panel.ended = function()
						panel.parent:removeChild(panel)
					end
					panel:hide()
					oEditor.items[newEffectName] = item.file
					oEditor.currentName = newEffectName
					oEditor.currentFile = item.file
					oEditor:dumpEffectFile()
					loadEffect(newEffectName,item.file)
				end)
			button.file = files[i]
			button.enabled = false
			button.opacity = 0
			button.anchor = oVec2(0,1)
			button:runAction(
				CCSequence(
				{
					CCDelay(n*0.05),
					oOpacity(0.2,1),
					CCCall(function()
						button.enabled = true
					end)
				}))
			menu:addChild(button)
		end

		resetPanel()
		panel:show()
		return panel
	end

	local title = CCLabelTTF("Choose Effect","Arial",24)
	title.texture.antiAlias = false
	title.color = ccColor3(0x00ffff)
	title.anchor = oVec2(0.5,1)
	y = yStart-20
	title.position = oVec2(halfBW,y)
	menu:addChild(title)
	title.opacity = 0
	title:runAction(oOpacity(0.3,0.5))
	yStart = y-title.contentSize.height-(oEditor.currentFile and -10 or 20)

	if oEditor.currentFile then
		title = CCLabelTTF("(Current: "..oEditor.currentName..")","Arial",16)
		title.texture.antiAlias = false
		title.color = ccColor3(0x00ffff)
		title.anchor = oVec2(0.5,1)
		y = yStart-20
		title.position = oVec2(halfBW,y)
		menu:addChild(title)
		title.opacity = 0
		title:runAction(oOpacity(0.3,0.5))
		yStart = y-title.contentSize.height-10
	end

	local effectFile = io.open(listFile,"r")
	for item in effectFile:read("*a"):gmatch("%b<>") do
		if not item:sub(2,2):match("[A/]") then
			local line = item:gsub("%s","")
			local name = line:match("A=\"(.-)\"")
			local filename = line:match("B=\"(.-)\"")
			oEditor.items[name] = filename
		end
	end
	effectFile:close()

	local i = 0
	for itemName,filename in pairs(oEditor.items) do
		n = n+1
		i = i+1
		y = yStart-10-math.floor((n-1)/itemNum)*60
		local name = #itemName > 10 and itemName:sub(1,7).."..." or itemName
		local button = oButton(
			name,
			17,
			itemWidth,50,
			xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
			function(item)
				oEditor.currentName = item.name
				oEditor.currentFile = item.file
				panel.ended = function()
					panel.parent:removeChild(panel)
				end
				panel:hide()
				loadEffect(item.name,item.file)
			end)
		button.name = name
		button.file = filename
		button.enabled = false
		button.anchor = oVec2(0,1)
		button.opacity = 0
		button:runAction(
			CCSequence(
			{
				CCDelay(n*0.05),
				oOpacity(0.2,1),
				CCCall(function()
					button.enabled = true
				end)
			}))
		menu:addChild(button)
	end
	n = n+1
	y = yStart-10-math.floor((n-1)/itemNum)*60
	local newPButton = oButton(
		"<PARTICLE>",
		17,
		itemWidth,50,
		xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
		function()
			panel.ended = function()
				panel.parent:removeChild(panel)
			end
			panel:hide()
			oEditor:addChild(oBox("New Particle Name",function(name)
				if name == "" or name:match("[\\/|:*?<>\"%.]") or oEditor:isNameExist(name) then
					oEditor:addChild(oBox("Invalid Name"),oEditor.topMost)
				else
					oEditor:addChild(oTemplateChooser(name..".par"),oEditor.topMost)
				end
			end,true),oEditor.topMost)
		end)
	newPButton.color = ccColor3(0x80ff00)
	newPButton.anchor = oVec2(0,1)
	newPButton.enabled = false
	newPButton.opacity = 0
	newPButton:runAction(
		CCSequence(
		{
			CCDelay(n*0.05),
			oOpacity(0.2,1),
			CCCall(function()
				newPButton.enabled = true
			end)
		}))
	menu:addChild(newPButton)
	n = n+1
	y = yStart-10-math.floor((n-1)/itemNum)*60
	local newFButton = oButton(
		"<FRAME>",
		17,
		itemWidth,50,
		xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
		function()
			panel.ended = function()
				panel.parent:removeChild(panel)
			end
			panel:hide()
			oEditor:addChild(oBox("New Frame Name",function(name)
				if name == "" or name:match("[\\/|:*?<>\"%.]") or oEditor:isNameExist(name) then
					oEditor:addChild(oBox("Invalid Name"),oEditor.topMost)
				else
					oEditor.currentName = name
					oEditor.currentFile = oEditor.currentName..".frame"
					oEditor.items[oEditor.currentName] = oEditor.currentFile
					oEditor:dumpEffectFile()
					oEditor.effectData = {file="",interval=1}
					updateAttr("name",oEditor.currentName)
					updateAttr("file",oEditor.currentFile)
					updateAttr("interval",1)
					oContent:saveToFile(oEditor.output..oEditor.currentFile,[[<A A="" B="1"></A>]])
					oCache.Effect:load(oEditor.output..oEditor.listFile)
					emit("Effect.viewArea.changeEffect",oEditor.currentName)
				end
			end,true),oEditor.topMost)
		end)
	newFButton.color = ccColor3(0x80ff00)
	newFButton.anchor = oVec2(0,1)
	newFButton.enabled = false
	newFButton.opacity = 0
	newFButton:runAction(
		CCSequence(
		{
			CCDelay(n*0.05),
			oOpacity(0.2,1),
			CCCall(function()
				newFButton.enabled = true
			end)
		}))
	menu:addChild(newFButton)

	n = n+1
	y = yStart-10-math.floor((n-1)/itemNum)*60
	local addButton = oButton(
		"<ADD>",
		17,
		itemWidth,50,
		xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
		function()
			panel.ended = function()
				panel.parent:removeChild(panel)
			end
			panel:hide()

			oEditor:addChild(oBox("New Effect Name",function(name)
				if name == "" or name:match("[\\/|:*?<>\"%.]") or oEditor:isNameExist(name) then
					oEditor:addChild(oBox("Invalid Name"),oEditor.topMost)
				else
					oEditor:addChild(oFileChooser(true,name),oEditor.topMost)
				end
			end,true),oEditor.topMost)
		end)
	addButton.color = ccColor3(0xff8000)
	addButton.anchor = oVec2(0,1)
	addButton.enabled = false
	addButton.opacity = 0
	addButton:runAction(
		CCSequence(
		{
			CCDelay(n*0.05),
			oOpacity(0.2,1),
			CCCall(function()
				addButton.enabled = true
			end)
		}))
	menu:addChild(addButton)

	if oEditor.currentFile then
		n = n+1
		y = yStart-10-math.floor((n-1)/itemNum)*60
		local delButton = oButton(
			"<DEL>",
			17,
			itemWidth,50,
			xStart+10+((n-1)%itemNum)*(itemWidth+10), y,
			function()
				panel.ended = function()
					panel.parent:removeChild(panel)
				end
				panel:hide()
				oEditor:addChild(oBox("Remove \n"..oEditor.currentName,function()
					local count = 0
					for _,file in pairs(oEditor.items) do
						if file == oEditor.currentFile then
							count = count + 1
						end
					end
					oEditor.items[oEditor.currentName] = nil
					oEditor.currentName = nil
					local lastFile = oEditor.currentFile
					oEditor.currentFile = nil
					oEditor:dumpEffectFile()
					emit("Effect.viewArea.changeEffect",nil)
					emit("Effect.settingPanel.hide")

					if count <= 1 then
						local box = oBox("Delete Unused File\n"..lastFile,function()
							oContent:remove(oEditor.output..lastFile)
							oEditor:addChild(oFileChooser(),oEditor.topMost)
						end)
						box.cancelHandler = function()
							oEditor:addChild(oFileChooser(),oEditor.topMost)
						end
						oEditor:addChild(box,oEditor.topMost)
					else
						oEditor:addChild(oFileChooser(),oEditor.topMost)
					end
				end),oEditor.topMost)
			end)
		delButton.color = ccColor3(0xff0080)
		delButton.anchor = oVec2(0,1)
		delButton.enabled = false
		delButton.opacity = 0
		delButton:runAction(
			CCSequence(
			{
				CCDelay(n*0.05),
				oOpacity(0.2,1),
				CCCall(function()
					delButton.enabled = true
				end)
			}))
		menu:addChild(delButton)
	end

	if oEditor.quitable then
		local backButton = oButton("Quit",17,60,false,
			0,0,
			function(item)
				opMenu.enabled = false
				item.enabled = false
				panel:hide()
				oEditor:emit("Quit")
			end)
		backButton.anchor = oVec2.zero
		local btnBk = CCDrawNode()
		btnBk:drawDot(oVec2.zero,30,ccColor4(0x22ffffff))
		btnBk.position = oVec2(30,30)
		backButton:addChild(btnBk,-1)
		opMenu:addChild(backButton)
	end

	resetPanel()
	panel:show()
	return panel
end

return oFileChooser
