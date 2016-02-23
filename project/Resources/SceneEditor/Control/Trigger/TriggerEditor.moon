Dorothy!
TriggerEditorView = require "View.Control.Trigger.TriggerEditor"
ExprEditor = require "Control.Trigger.ExprEditor"
TriggerItem = require "Control.Trigger.TriggerItem"
SelectionPanel = require "Control.Basic.SelectionPanel"
InputBox = require "Control.Basic.InputBox"
MessageBox = require "Control.Basic.MessageBox"
import CompareTable,Path from require "Data.Utils"
import Expressions,ToEditText from require "Data.TriggerDef"

TriggerScope = Class
	__initc:=>
		@scrollArea = nil
		@panel = nil
		@triggerBtn = nil
		@changeTrigger = (button)->
			if @triggerBtn
				@triggerBtn.checked = false
				@panel\removeChild @triggerBtn.exprEditor,false
			@triggerBtn = if button and button.checked then button else nil
			if @triggerBtn
				if not @triggerBtn.exprEditor
					{width:panelW,height:panelH} = @panel
					exprEditor = with ExprEditor {
							x:panelW/2+105
							y:panelH/2
							width:panelW-210
							height:panelH-20
						}
						\loadExpr @triggerBtn.file
					@triggerBtn.exprEditor = exprEditor
					@triggerBtn\slot "Cleanup",->
						parent = exprEditor.parent
						if parent
							parent\removeChild exprEditor
						else
							exprEditor\cleanup!
				@panel\addChild @triggerBtn.exprEditor

	__init:(menu,path,prefix)=>
		@_menu = menu
		@_path = path
		@_prefix = prefix
		@_currentGroup = ""
		@_groups = nil
		@_groupOffset = {}
		@items = {}
		@files = {}
		@updateItems!
		@currentGroup = "Default"
		@_menu\slot "Cleanup",->
			for _,item in pairs @items
				if item.parent
					item.parent\removeChild item
				else
					item\cleanup!

	updateItems:=>
		defaultFolder = @_path.."Default"
		oContent\mkdir defaultFolder unless oContent\exist defaultFolder
		@_groups = Path.getFolders @_path
		table.sort @_groups
		files = Path.getAllFiles @_path,"trigger"
		for i = 1,#files
			files[i] = @_prefix..files[i]
		filesToAdd,filesToDel = CompareTable @files,files
		@files = files
		for file in *filesToAdd
			appendix = Path.getFilename file
			group = file\sub #@_prefix+1,-#appendix-2
			item = with TriggerItem {
					text:Path.getName file
					width:190
					height:35
				}
				.file = file
				.group = group
				\slot "Tapped",@@changeTrigger
			@items[file] = item
		for file in *filesToDel
			item = @items[file]
			if @@triggerBtn == item
				@@triggerBtn = nil
			if item.parent
				item.parent\removeChild item
			else
				item\cleanup!
			@items[file] = nil
		@currentGroup = @_currentGroup

	currentGroup:property => @_currentGroup,
		(group)=>
			@_groupOffset[group] = @@scrollArea.offset
			@_currentGroup = group
			groupItems = for _,item in pairs @items
				continue if item.group ~= group
				item
			table.sort groupItems,(itemA,itemB)-> itemA.text < itemB.text
			with @_menu
				\removeAllChildrenWithCleanup false
				for item in *groupItems
					\addChild item
				@@scrollArea.offset = oVec2.zero
				@@scrollArea.viewSize = \alignItems!
				@@scrollArea.offset = @_groupOffset[@_currentGroup] if @_currentGroup

	groups:property => @_groups
	prefix:property => @_prefix
	path:property => @_path
	menu:property => @_menu

Class TriggerEditorView,
	__init:(args)=>
		{width:panelW,height:panelH} = @panel

		TriggerScope.scrollArea = @listScrollArea
		TriggerScope.panel = @panel

		@localScope = TriggerScope @localListMenu,
			editor.triggerLocalFullPath,
			editor.triggerLocalFolder

		@globalScope = TriggerScope @globalListMenu,
			editor.triggerGlobalFullPath,
			editor.triggerGlobalFolder

		@localBtn.checked = true
		scopeBtn = @localBtn
		changeScope = (button)->
			scopeBtn.checked = false unless scopeBtn == button
			button.checked = true unless button.checked
			scopeBtn = button
			if @localBtn.checked
				@localListMenu.visible = true
				@globalListMenu.visible = false
				@groupBtn.text = @localScope.currentGroup
				@listScrollArea.viewSize = @localListMenu\alignItems!
			else
				@localListMenu.visible = false
				@globalListMenu.visible = true
				@groupBtn.text = @globalScope.currentGroup
				@listScrollArea.viewSize = @globalListMenu\alignItems!
		@localBtn\slot "Tapped",changeScope
		@globalBtn\slot "Tapped",changeScope

		@listScrollArea\setupMenuScroll @localListMenu
		@listScrollArea\setupMenuScroll @globalListMenu
		@listScrollArea.viewSize = @localListMenu\alignItems!

		lastGroupListOffset = oVec2.zero
		@groupBtn\slot "Tapped",->
			scope = @localBtn.checked and @localScope or @globalScope
			groups = for group in *scope.groups
				continue if group == "Default" or group == scope.currentGroup
				group
			table.insert groups,1,"Default" if scope.currentGroup ~= "Default"
			table.insert groups,"<NEW>"
			table.insert groups,"<DEL>"
			with SelectionPanel {
					title:"Current Group"
					subTitle:scope.currentGroup
					width:180
					items:groups
					itemHeight:35
					fontSize:20
				}
				.scrollArea.offset = lastGroupListOffset
				.menu.children[#.menu.children-1].color = ccColor3 0x80ff00
				.menu.children.last.color = ccColor3 0xff0080
				\slot "Selected",(item)->
					lastGroupListOffset = .scrollArea.offset
					switch item
						when "<NEW>"
							with InputBox text:"New Group Name"
								\slot "Inputed",(result)->
									return unless result
									if not result\match("^[_%a][_%w]*$")
										MessageBox text:"Invalid Name!",okOnly:true
									elseif oContent\exist scope.prefix..result
										MessageBox text:"Group Exist!",okOnly:true
									else
										oContent\mkdir scope.path..result
										scope\updateItems!
										scope.currentGroup = result
										@groupBtn.text = result
						when "<DEL>"
							text = if scope.currentGroup == "Default"
								"Delete Triggers\nBut Keep Group\n#{scope.currentGroup}"
							else
								"Delete Group\n#{scope.currentGroup}\nWith Triggers"
							with MessageBox text:text
								\slot "OK",(result)->
									return unless result
									Path.removeFolder scope.path..scope.currentGroup.."/"
									scope\updateItems!
									scope.currentGroup = "Default"
									@groupBtn.text = scope.currentGroup
						else
							scope.currentGroup = item
							@groupBtn.text = item

		@newBtn\slot "Tapped",->
			with InputBox text:"New Trigger Name"
				\slot "Inputed",(result)->
					return unless result
					if not result\match("^[_%a][_%w]*$")
						MessageBox text:"Invalid Name!",okOnly:true
					else
						scope = @localBtn.checked and @localScope or @globalScope
						triggerFullPath = scope.path..scope.currentGroup.."/"..result..".trigger"
						if oContent\exist triggerFullPath
							MessageBox text:"Trigger Exist!",okOnly:true
						else
							oContent\saveToFile triggerFullPath,ToEditText Expressions.Trigger\Create result
							scope\updateItems!
							triggerFile = scope.prefix..scope.currentGroup.."/"..result..".trigger"
							for item in *scope.menu.children
								if item.file == triggerFile
									item\emit "Tapped",item
									break

		@addBtn\slot "Tapped",->
			MessageBox text:"Place Triggers In\nFolders Under\n/Logic/Trigger/Global/",okOnly:true

		@delBtn\slot "Tapped",->
			triggerBtn = TriggerScope.triggerBtn
			if triggerBtn
				with MessageBox text:"Delete Trigger\n#{triggerBtn.text}"
					\slot "OK",(result)->
						return unless result
						oContent\remove editor.gameFullPath..triggerBtn.file
						scope = @localBtn.checked and @localScope or @globalScope
						scope\updateItems!
			else
				MessageBox text:"No Trigger Selected!",okOnly:true

		@copyBtn.copying = false
		@copyBtn\slot "Tapped",->
			triggerBtn = TriggerScope.triggerBtn
			if not triggerBtn
				MessageBox text:"No Trigger Selected!",okOnly:true
				return
			scope = @localBtn.checked and @localScope or @globalScope
			@copyBtn.copying = not @copyBtn.copying
			@copyBtn.targetItem = editor.gameFullPath..triggerBtn.file
			if @copyBtn.copying
				@copyBtn.text = "Paste"
				@copyBtn.color = ccColor3 0xff0080
			else
				@copyBtn.text = "Copy"
				@copyBtn.color = ccColor3 0x00ffff
				triggerName = Path.getName @copyBtn.targetItem
				triggerFullPath = scope.path..scope.currentGroup.."/"..triggerName

		@closeBtn\slot "Tapped",->
			exprEditor\save ""
			@hide!

		@gslot "Scene.EditMenu.Delete",-> @show!

	show:=>
		@visible = true
		@closeBtn.scaleX = 0
		@closeBtn.scaleY = 0
		@closeBtn\perform oScale 0.3,1,1,oEase.OutBack
		@panel.opacity = 0
		@panel\perform CCSequence {
			oOpacity 0.3,1,oEase.OutQuad
			CCCall ->
				@listScrollArea.touchEnabled = true
				@localListMenu.enabled = true
				@globalListMenu.enabled = true
				@editMenu.enabled = true
				@opMenu.enabled = true
				for control in *editor.children
					control.visible = false if control ~= @
		}

	hide:=>
		for control in *editor.children
			control.visible = true if control ~= @
		@listScrollArea.touchEnabled = false
		@localListMenu.enabled = false
		@globalListMenu.enabled = false
		@editMenu.enabled = false
		@opMenu.enabled = false
		@closeBtn\perform oScale 0.3,0,0,oEase.InBack
		@panel\perform oOpacity 0.3,0,oEase.OutQuad
		@perform CCSequence {
			CCDelay 0.3
			CCHide!
		}
