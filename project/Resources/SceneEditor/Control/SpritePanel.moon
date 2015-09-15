Dorothy!
Class,property = unpack require "class"
SpritePanelView = require "View.Control.SpritePanel"
TabButton = require "Control.TabButton"
SpriteView = require "Control.SpriteView"
MessageBox = require "Control.MessageBox"
import CompareTable from require "Data.Utils"
-- [signals]
-- "Selected",(spriteStr)->
-- "Hide",->
-- [params]
-- x, y, width, height
Class
	__partial: (args)=> SpritePanelView args
	__init: (args)=>
		@_isSelecting = false
		@selectedImages = {}
		@selectedClips = {}
		@viewItemChecked = (checked,item)->
			if @selectedImages
				@selectedImages[item.file] = if checked then true else nil
		@clipItemChecked = (checked,item)->
			if @selectedClips
				@selectedClips[item.file] = if checked then true else nil
		@selected = (item)->
			@\hide!
			@\emit "Selected",item.spriteStr
			emit "Scene.SpriteSelected",item.spriteStr

		contentRect = CCRect.zero
		itemRect = CCRect.zero
		@scrollArea\slots "Scrolled",(delta)->
			contentRect\set 0,0,@scrollArea.width,@scrollArea.height
			@menu\eachChild (child)->
				child.position += delta
				{:positionX,:positionY,:width,:height} = child
				itemRect\set positionX-width/2,positionY-height/2,width,height
				child.visible = contentRect\intersectsRect itemRect -- reduce draw calls

		@scrollArea\slots "ScrollStart",->
			@menu.enabled = false

		@scrollArea\slots "ScrollEnd",->
			@menu.enabled = true

		@\slots "Cleanup",->
			oRoutine\remove @routine if @routine

		@\gslot "Scene.ViewSprite",->
			@\show!

		@\gslot "Scene.ClearSprite",->
			@clips = nil
			@images = nil

		@\gslot "Scene.LoadSprite",(resPath)->
			@\runThread ->
				-- get image and clip files
				images = {}
				clips = {}
				visitResource = (path)->
					return unless oContent\exist path
					path = path\gsub("[\\/]*$","")
					files = oContent\getEntries path,false
					sleep!
					for file in *files
						extension = file\match "%.([^%.\\/]*)$"
						extension = extension\lower! if extension
						filename = path.."/"..file
						switch extension
							when "png","jpg","jpeg","tiff","webp"
								clipFile = filename\match("(.*)%.[^%.\\/]*$")..".clip"
								table.insert images,filename unless oContent\exist clipFile
							when "clip"
								table.insert clips,filename
					folders = oContent\getEntries path,true
					for folder in *folders
						if folder ~= "." and folder ~= ".."
							visitResource path.."/"..folder
					if #files == 0 and #folders == 2
						oContent\remove path
				visitResource resPath

				{:width,:height} = @scrollArea
				compareClip = (a,b)->
					a\match("[\\/]([^\\/]*)$") < b\match("[\\/]([^\\/]*)$")

				i = 0
				if @clips -- already loaded clips
					clipsToAdd,clipsToDel = CompareTable @clips,clips
					for clipDel in *clipsToDel
						item = @clipItems[clipDel]
						item.parent\removeChild item
						@clipItems[clipDel] = nil
						expandItems = @clipExpands[clipDel]
						if expandItems
							for expItem in *expandItems
								expItem.parent\removeChild expItem
							@clipExpands[clipDel] = nil
						@\playUpdateHint!
					table.sort clipsToAdd,compareClip
					table.sort clips,compareClip
					for clipAdd in *clipsToAdd
						@clipItems[clipAdd] = @\_addClipTab clipAdd,i
						@\playUpdateHint!
						sleep!
						i += 1
				else -- first load clips
					if @clipItems
						@\playUpdateHint!
						for clip,item in pairs @clipItems
							item.parent\removeChild item
							expandItems = @clipExpands[clip]
							if expandItems
								for expItem in *expandItems
									expItem.parent\removeChild expItem
								@clipExpands[clip] = nil
					@clipItems = {}
					@clipExpands = {}
					table.sort clips,compareClip
					for clip in *clips
						clipTab = @\_addClipTab clip,i
						@\playUpdateHint!
						sleep!
						i += 1
						clipTab.visible = false
						@clipItems[clip] = clipTab
				@clips = clips

				if @images
					imagesToAdd,imagesToDel = CompareTable @images,images
					for imageDel in *imagesToDel
						item = @imageItems[imageDel]
						item.parent\removeChild item
						@imageItems[imageDel] = nil
						@\playUpdateHint!
					for imageAdd in *imagesToAdd
						viewItem = SpriteView {
							file: imageAdd
							width: 100
							height: 100
							needUnload: true
						}
						viewItem.visible = false
						viewItem.enabled = false
						viewItem.isCheckMode = @_isSelecting
						viewItem\slots "Checked",@viewItemChecked
						viewItem\slots "Selected",@selected
						@menu\addChild viewItem
						@\playUpdateHint!
						sleep!
						@imageItems[imageAdd] = viewItem
						viewItem.opacity = 0
						viewItem\perform CCSequence {
							CCDelay i*0.1
							oOpacity 0.3,1
						}
						i += 1
				else
					if @imageItems
						@\playUpdateHint!
						for _,item in pairs @imageItems
							item.parent\removeChild item
					@imageItems = {}
					for image in *images
						viewItem = SpriteView {
							file: image
							width: 100
							height: 100
							needUnload: true
						}
						viewItem\slots "Checked",@viewItemChecked
						viewItem\slots "Selected",@selected
						viewItem.visible = false
						viewItem.enabled = false
						viewItem.isCheckMode = @_isSelecting
						@menu\addChild viewItem
						@\playUpdateHint!
						sleep!
						@imageItems[image] = viewItem
						viewItem.opacity = 0
						viewItem\perform CCSequence {
							CCDelay i*0.1
							oOpacity 0.3,1
						}
						i += 1
				@images = images

				itemCount = math.floor (@panel.width-10)/110
				y = height
				startY = height-40
				for i,clip in ipairs @clips
					i -= 1
					y = startY-30-i*50
					clipTab = @clipItems[clip]
					clipTab.position = oVec2(width/2,y) + @scrollArea.offset
					expandItems = @clipExpands[clip]
					if expandItems
						startY -= clipTab.deltaY
						posY = y-20
						for i,expItem in ipairs expandItems
							i -= 1
							x = 60+(i%itemCount)*110
							y = posY-60-math.floor(i/itemCount)*110
							expItem.position = oVec2(x,y) + @scrollArea.offset
						y -= 30 if #expandItems > 0
				y -= 20 if #@clips > 0

				startY = y
				for i,image in ipairs @images
					i -= 1
					x = 60+(i%itemCount)*110
					y = startY-60-math.floor(i/itemCount)*110
					viewItem = @imageItems[image]
					viewItem.position = oVec2(x,y) + @scrollArea.offset
				y -= 60 if #@images > 0
				@scrollArea.viewSize = CCSize width,height-y

		@addBtn.visible = false
		@delBtn.visible = false
		@groupBtn.visible = false
		@delGroupBtn.visible = false

		@modeBtn\slots "Tapped",->
			@\_setCheckMode not @_isSelecting

		@addBtn\slots "Tapped",->
			MessageBox text:"Place Images In\n/Graphic/ folder",okOnly:true

		@delBtn\slots "Tapped",->
			images = [image for image,_ in pairs @selectedImages]
			clips = [clip for clip,_ in pairs @selectedClips]
			if #images + #clips > 0
				with MessageBox text:"Delete "..(#images+#clips == 1 and "item" or "items")
					\slots "OK",(result)->
						return unless result
						with MessageBox text:"Confirm This\nDeletion"
							\slots "OK",(result)->
								return unless result
								@\runThread ->
									for image in *images
										sleep!
										@imageItems[image].isCheckMode = false
										oContent\remove image
										oCache.Texture\unload image
									for clip in *clips
										sleep!
										@clipItems[clip].isCheckMode = false
										texFile = oCache.Clip\getTextureFile clip
										oContent\remove clip
										oContent\remove texFile
										oCache.Clip\unload clip
										oCache.Texture\unload texFile
									sleep 0.3
									editor\updateSprites!
			else
				MessageBox text:"No Item Selected",okOnly:true

		@groupBtn\slots "Tapped",->
			images = [image for image,_ in pairs @selectedImages]
			if #images > 0
				ClipEditor = require "Control.ClipEditor"
				clipEditor = ClipEditor :images
				clipEditor\slots "Grouped",(result)->
					return unless result
					for image in *images
						@imageItems[image].isCheckMode = false
					thread ->
						sleep 0.3
						editor\updateSprites!
			else
				MessageBox text:"No Sprite Selected",okOnly:true

		@delGroupBtn\slots "Tapped",->
			clips = [clip for clip,_ in pairs @selectedClips]
			if #clips > 0
				msgBox = MessageBox text:"Break Selected\nGroups"
				msgBox\slots "OK",(result)->
					return unless result
					@\runThread ->
						for clip in *clips
							sleep!
							folder = editor.graphicFullPath..clip\match "[\\/]([^\\/]*)%.[^%.\\/]*$"
							if oContent\exist folder
								sleep!
								index = 1
								while oContent\exist folder..tostring index
									sleep!
									index += 1
								folder ..= tostring index
							folder ..= "/"
							oContent\mkdir folder
							sleep!
							texFile = oCache.Clip\getTextureFile clip
							oCache.Texture\unload texFile
							CCImage.isPngAlphaPremultiplied = false
							oCache\loadAsync texFile
							CCImage.isPngAlphaPremultiplied = true
							blendFunc = ccBlendFunc ccBlendFunc.One,ccBlendFunc.Zero
							tex = oCache.Texture\load texFile
							tex.antiAlias = false
							names = oCache.Clip\getNames clip
							for name in *names
								sleep!
								sp = CCSprite clip.."|"..name
								sp.blendFunc = blendFunc
								sp.anchor = oVec2.zero
								target = CCRenderTarget sp.width,sp.height
								target\beginDraw!
								target\draw sp
								target\endDraw!
								sleep!
								target\save folder..name..".png",CCImage.PNG
							oCache.Texture\unload texFile
							oContent\remove texFile
							oCache.Clip\unload clip
							oContent\remove clip
							@clipItems[clip].isCheckMode = false
						sleep 0.3
						editor\updateSprites!
				else
					MessageBox text:"No Group Selected",okOnly:true

		@closeBtn\slots "Tapped",->
			@\hide!

	playUpdateHint: =>
		if not @hint.visible
			@hint.visible = true
			@hint.opacity = 1
			@hint\perform @loopFade

	runThread: (task)=>
		oRoutine\remove @routine if @routine
		@routine = thread ->
			@scrollArea.touchEnabled = false
			@menu\eachChild (child)->
				if tolua.type child == "CCMenuItem"
					child.enabled = false
			@opMenu.enabled = false
			task!
			@hint\perform CCSequence {
				oOpacity 0.3,0,oEase.OutQuad
				CCHide!
			}
			@opMenu.enabled = true
			@menu\eachChild (child)->
				if tolua.type child == "CCMenuItem"
					child.enabled = child.isCheckMode or not @_isSelecting
			@scrollArea.touchEnabled = true
			@routine = nil

	_addClipTab: (clip,index)=>
		clipTab = TabButton {
			file: clip
			width: @scrollArea.width-20
			height: 40
			text: clip\match "[\\/]([^\\/]*)%.[^%.\\/]*$"
		}
		clipTab\slots "Expanded",(expanded)->
			if expanded
				posY = clipTab.positionY-20
				names = oCache.Clip\getNames clip
				texFile = oCache.Clip\getTextureFile clip
				@clipExpands[clip] = {}
				newY = posY
				itemCount = math.floor (@width-10)/110
				for i,name in ipairs names
					i -= 1
					spriteStr = clip.."|"..name
					newX = 60+(i%itemCount)*110
					newY = posY-60-math.floor(i/itemCount)*110
					viewItem = SpriteView {
						file: texFile
						spriteStr: spriteStr
						x: newX
						y: newY
						width: 100
						height: 100
						alias: #names
						needUnload: i == #names-1
					}
					viewItem.clip = clip
					viewItem\slots "Selected",@selected
					@menu\addChild viewItem
					table.insert @clipExpands[clip],viewItem
				newY -= 50
				deltaY = posY - newY
				clipTab.deltaY = deltaY
				@menu\eachChild (child)->
					if child.clip ~= clip
						child.positionY -= deltaY if child.positionY < posY
				with @scrollArea.viewSize
					@scrollArea.viewSize = CCSize .width,.height+deltaY
			else
				deltaY = clipTab.deltaY
				clipTab.deltaY = 0
				posY = clipTab.positionY-20-deltaY
				children = @menu\getChildren!
				for child in *children
					if child.clip == clip
						child.parent\removeChild child
					else
						child.positionY += deltaY if child.positionY < posY
				@clipExpands[clip] = nil
				with @scrollArea.viewSize
					@scrollArea.viewSize = CCSize .width,.height-deltaY
		clipTab.deltaY = 0
		clipTab.position += @scrollArea.offset
		clipTab.enabled = false
		clipTab.isCheckMode = @_isSelecting
		clipTab\slots "Checked",@clipItemChecked
		@menu\addChild clipTab
		clipTab.opacity = 0
		clipTab\perform CCSequence {
			CCDelay (index or 0)*0.1
			oOpacity 0.3,0.5
		}
		clipTab

	_setCheckMode: (isSelecting)=>
		return if isSelecting == @_isSelecting
		@_isSelecting = isSelecting
		@modeBtn.color = ccColor3(isSelecting and 0xff0088 or 0x00ffff)
		show = (index)-> CCSequence {
			CCDelay 0.1*index
			CCShow!
			oScale 0,0,0
			oScale 0.3,1,1,oEase.OutBack
		}
		hide = (index)-> CCSequence {
			CCDelay 0.1*index
			oScale 0.3,0,0,oEase.InBack
			CCHide!
		}
		if isSelecting
			@addBtn\perform show 0
			@delBtn\perform show 1
			@groupBtn\perform show 2
			@delGroupBtn\perform show 3
			@hint.positionX = @panel.width-(@panel.width-300)/2
		else
			@addBtn\perform hide 3
			@delBtn\perform hide 2
			@groupBtn\perform hide 1
			@delGroupBtn\perform hide 0
			@hint.positionX = @panel.width-(@panel.width-60)/2
		@menu\eachChild (child)->
			if not child.clip
				child.isCheckMode = isSelecting
			else
				child.enabled = not isSelecting

	show: =>
		@\perform CCSequence {
			CCShow!
			oOpacity 0.3,0.6,oEase.OutQuad
		}
		@closeBtn.scaleX = 0
		@closeBtn.scaleY = 0
		@closeBtn\perform oScale 0.3,1,1,oEase.OutBack
		@panel.opacity = 0
		@panel.scaleX = 0
		@panel.scaleY = 0
		@panel\perform CCSequence {
			CCSpawn {
				oOpacity 0.3,1,oEase.OutQuad
				oScale 0.3,1,1,oEase.OutBack
			}
			CCCall ->
				@scrollArea.touchEnabled = true
				@menu.enabled = true
				@opMenu.enabled = true
				editor\updateSprites!
		}

	hide: =>
		@\_setCheckMode false
		@scrollArea.touchEnabled = false
		@menu.enabled = false
		@opMenu.enabled = false
		@closeBtn\perform oScale 0.3,0,0,oEase.InBack
		@panel\perform CCSpawn {
			oOpacity 0.3,0,oEase.OutQuad
			oScale 0.3,0,0,oEase.InBack
		}
		@\perform CCSequence {
			oOpacity 0.3,0,oEase.OutQuad
			CCHide!
			CCCall -> @\emit "Hide"
		}
