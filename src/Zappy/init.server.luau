--[[
	MIT License
	
	Copyright (c) 2024 Ultrasonic54321
	Copyright (c) 2022 Yasu Yoshida

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local VisibilityCheckDispatcher = game:GetService("VisibilityCheckDispatcher")

local Plugin = plugin

assert(plugin, "This script must be run as a plugin!")

local Components = script.Parent.Components
local Packages = script.Parent.Packages
local Zap = require(script.zap)

local PluginComponents = Components:FindFirstChild("PluginComponents")
local Widget = require(PluginComponents.Widget)
local Toolbar = require(PluginComponents.Toolbar)
local ToolbarButton = require(PluginComponents.ToolbarButton)

local StudioComponents = Components:FindFirstChild("StudioComponents")
local MainButton = require(StudioComponents.MainButton)
local ScrollFrame = require(StudioComponents.ScrollFrame)
local Label = require(StudioComponents.Label)
local TextInput = require(StudioComponents.TextInput)
local TextInputAccented = require(StudioComponents.TextInputAccented)
local TextInputHighlighted = require(StudioComponents.TextInputHighlighted)
local VerticalCollapsibleSection = require(StudioComponents.VerticalCollapsibleSection)
local Checkbox = require(StudioComponents.Checkbox)

local Highlighter = require(Packages.Highlighter)
local Trove = require(Packages.Trove)
local Fusion = require(Packages.Fusion)

local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Observer = Fusion.Observer

local function saveToScript(scriptName: string, scriptParent: Instance, source: string): ModuleScript
	local ExportScript: ModuleScript = (scriptParent:FindFirstChild(scriptName) :: ModuleScript) or Instance.new("ModuleScript", scriptParent)
	ExportScript.Name = scriptName
	ExportScript.Source = source
	return ExportScript
end

local function saveStringToScript(scriptName: string, scriptParent: Instance, source: string)
	saveToScript(scriptName, scriptParent, `return [[{source}]]`)
end


local function loadFromScript(scriptName: string, scriptParent: Instance): string?
	local ExportScript: ModuleScript = (scriptParent:FindFirstChild(scriptName) :: ModuleScript)
	if not ExportScript then
		return nil
	else
		return ExportScript.Source
	end
end

local function loadStringFromScript(scriptName: string, scriptParent: Instance): string?
	local loadedScript = loadFromScript(scriptName, scriptParent)
	if not loadedScript then
		return nil
	end

	do
		local s, _output = pcall(HttpService.JSONDecode, HttpService, loadedScript)

		-- loadedScript would be just raw JSON so just return it
		-- this is needed because of how older versions of the plugin saved settings
		if s then
			--consumers still expect a string, so don't return parsed script
			return loadedScript
			--return _output 
		end
	end

	do
		local s, output = pcall(require, (scriptParent[scriptName] :: ModuleScript):Clone())
		if s and typeof(output) == "string" then
			return output
		end
	end

	return nil
end

do --creates the Zappy plugin
	local pluginToolbar = Toolbar {
		Name = "Zappy"
	}

	local widgetsEnabled = Value(false)
	local enableButton = ToolbarButton {
		Toolbar = pluginToolbar,

		ClickableWhenViewportHidden = true,
		Name = "Zappy",
		ToolTip = "Show or hide the Zappy panel",
		Image = "rbxassetid://17532741556",

		[OnEvent "Click"] = function()
			widgetsEnabled:set(not widgetsEnabled:get())
		end,
	}

	local widgetsEnabledObserver = Observer(widgetsEnabled)

	local trove = Trove.new()

	trove:Add(widgetsEnabledObserver:onChange(function()
		enableButton:SetActive(widgetsEnabled:get(false))
	end))

	Plugin.Unloading:Connect(function()
		trove:Destroy()
	end)

	local function ZappyWidget(children)
		return Widget {
			Id = game:GetService("HttpService"):GenerateGUID(),
			Name = "Zappy",

			InitialDockTo = Enum.InitialDockState.Float,
			InitialEnabled = false,
			ForceInitialEnabled = false,
			FloatingSize = Vector2.new(360, 300),
			MinimumSize = Vector2.new(286, 200),

			Enabled = widgetsEnabled,
			[OnChange "Enabled"] = function(isEnabled)
				widgetsEnabled:set(isEnabled)
			end,

			[Children] = ScrollFrame {
				ZIndex = 1,
				Size = UDim2.fromScale(1, 1),

				CanvasScaleConstraint = Enum.ScrollingDirection.X,

				UILayout = New "UIListLayout" {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 7),
				},

				UIPadding = New "UIPadding" {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
				},

				[Children] = children
			}
		}
	end

	local function NestedElement(children: { GuiObject })
		local centeredChildren = {}
		for _, element in children do
			element.Position = UDim2.fromScale(0.5, 0.5)
			element.AnchorPoint = Vector2.new(0.5, 0.5)
			element.Size = UDim2.new(0.9, 0, 0, 30)
			table.insert(centeredChildren, element)
		end
		return New "Frame" {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			[Children] = centeredChildren,
		}
	end

	local function SmallDescriptionLabel(text: string)
		return Label {
			Text = text,
			Size = UDim2.new(1, 0, 0, 14),
		}
	end

	local IDLInput = Value("")

	local ServerOutput = Value("")
	local ClientOutput = Value("")
	local ExportOutput = Value(false)

	local ClientExportScriptName = Value("ZapClient")
	local ServerExportScriptName = Value("ZapServer")
	local ToolingExportScriptName = Value("RemoteName.profiler")

	local ClientExportInstance = Value()
	local ServerExportInstance = Value()
	local ToolingExportInstance = Value()

	local CurrentSelectionName = Value()

	local function onClientTaggedInstancesChange(_taggedInstance: Instance)
		local clientTaggedInstances = CollectionService:GetTagged("ZAPPY_CLIENT_PARENT_INSTANCE")

		ClientExportInstance:set(
			if #clientTaggedInstances == 0 then ReplicatedStorage
			elseif #clientTaggedInstances == 1 then clientTaggedInstances[1] 
			else nil
		)
	end

	trove:Connect(CollectionService:GetInstanceAddedSignal("ZAPPY_CLIENT_PARENT_INSTANCE"), onClientTaggedInstancesChange)
	trove:Connect(CollectionService:GetInstanceRemovedSignal("ZAPPY_CLIENT_PARENT_INSTANCE"), onClientTaggedInstancesChange)

	-- update client and server export instances every duration bc Fusion v0.2 state management is really annoying?
	-- (yes, it is)
	task.spawn(function()
		while task.wait(0.125) do
			local serverTaggedInstances: { Instance } = CollectionService:GetTagged("ZAPPY_SERVER_PARENT_INSTANCE")
			local toolingTaggedInstances: { Instance } = CollectionService:GetTagged("ZAPPY_TOOLING_PARENT_INSTANCE")

			local selectedInstances = game:GetService("Selection"):Get()



			ServerExportInstance:set(
				if #serverTaggedInstances == 0 then ServerScriptService
				elseif #serverTaggedInstances == 1 then serverTaggedInstances[1]
				else nil
			)

			ToolingExportInstance:set(
				if #toolingTaggedInstances == 0 then ReplicatedStorage
				elseif #toolingTaggedInstances == 1 then toolingTaggedInstances[1]
				else nil
			)

			CurrentSelectionName:set(
				if selectedInstances and #selectedInstances == 1 then selectedInstances[1]:GetFullName()
				else ""
			)
		end
	end)

	local CurrentClientExportInstanceText = Computed(function()
		return "Client Export Location: " .. (
			if ClientExportInstance:get() ~= nil then `{ClientExportInstance:get():GetFullName()}["{ClientExportScriptName:get()}"]` 
			else "(unset; please set with 'Set ClientExportInstance' button)"
		)
	end)
	local CurrentServerExportInstanceText = Computed(function()
		return "Server Export Location: " .. (
			if ServerExportInstance:get() ~= nil then `{ServerExportInstance:get():GetFullName()}["{ServerExportScriptName:get()}"]` 
			else "(unset; please set with 'Set ServerExportInstance' button)"
		)
	end)
	local CurrentToolingExportInstanceText = Computed(function()
		return "Tooling Export Location: " .. (
			if ToolingExportInstance:get() ~= nil then `{ToolingExportInstance:get():GetFullName()}["{ToolingExportScriptName:get()}"]` 
			else "(unset; please set with 'Set ServerExportInstance' button)"
		)
	end)

	local ClientExportButtonHovering = Value(false)
	local ClientExportButtonColor = Computed(function()
		return if ClientExportButtonHovering:get() == true then Color3.fromHex("#544096")
		else Color3.fromHex("#44337c")
	end)
	local ServerExportButtonHovering = Value(false)
	local ServerExportButtonColor = Computed(function()
		return if ServerExportButtonHovering:get() == true then Color3.fromHex("#2aac7a")
		else Color3.fromHex("#288360")
	end)
	local ToolingExportButtonHovering = Value(false)
	local ToolingExportButtonColor = Computed(function()
		return if ToolingExportButtonHovering:get() == true then Color3.fromHex("#366e83")
		else Color3.fromHex("#294f5d")
	end)

	local Diagnostics = Value("")
	local DiagnosticsExists = Computed(function()
		return Diagnostics:get() ~= ""
	end)

	local ToolingOutput = Value("")
	local ToolingExists = Computed(function()
		return ToolingOutput:get() ~= ""
	end)

	local Busy = Value(false)

	local Ready = Computed(function()
		return not Busy:get()
	end)

	local NoWarnings = Value(false)
	local SaveSettings = Value(false)

	local ReparentExportedScriptsWhenOutputPathChanges = Value(false)

	Plugin.Unloading:Connect(widgetsEnabledObserver:onChange(function()
		if widgetsEnabled:get(false) then
			local loaded = loadStringFromScript("__ZappySettings", ServerStorage)
			if loaded then
				local parsedSettings: {
					IDL: string,
					NoWarnings: boolean?,
					ExportOutput: boolean,
					ServerExportScriptName: string,
					ClientExportScriptName: string,
					ToolingExportScriptName: string?
				} = HttpService:JSONDecode(loaded)
				SaveSettings:set(true)

				IDLInput:set(parsedSettings.IDL)
				ExportOutput:set(parsedSettings.ExportOutput)
				ServerExportScriptName:set(parsedSettings.ServerExportScriptName)
				ClientExportScriptName:set(parsedSettings.ClientExportScriptName)
				if parsedSettings.ToolingExportScriptName ~= nil then
					ToolingExportScriptName:set(parsedSettings.ToolingExportScriptName)
				end
				if parsedSettings.NoWarnings ~= nil then
					NoWarnings:set(parsedSettings.NoWarnings)
				end
			end
		end
	end))

	ZappyWidget {
		[Children] = {
			Label {
				Text = "Input"
			},			
			TextInput {
				PlaceholderText = "Your IDL here",
				ClearTextOnFocus = false,
				MultiLine = true,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextEditable = Ready,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Code,

				Text = IDLInput,
				[Fusion.Out "Text"] = IDLInput
			},
			Checkbox {
				Text = "Disable warnings",
				Value = NoWarnings
			},
			Checkbox {
				Text = "Save settings on successful generation",
				Value = SaveSettings
			},
			Checkbox {
				Text = "Auto-export output",
				Value = ExportOutput
			},
			VerticalCollapsibleSection {
				Text = "Output Settings",
				Visible = ExportOutput,
				[Children] = {
					Checkbox {
						Text = "Reparent previously exported ModuleScripts when output path changes",
						Value = ReparentExportedScriptsWhenOutputPathChanges,
					},
					VerticalCollapsibleSection {
						Text = "Client Output",
						Visible = ExportOutput,
						[Children] = {
							Label {
								Text = CurrentClientExportInstanceText,
								Visible = ExportOutput,
							},
							NestedElement {
								TextInput {
									PlaceholderText = "Script Name",
									Visible = ExportOutput,
									Text = ClientExportScriptName,
									[Fusion.Out "Text"] = ClientExportScriptName,
								}
							},
							SmallDescriptionLabel "Set custom client output path",
							NestedElement {
								New "TextButton" {
									Name = "ClientExportLocationPickerButton",
									RichText = true,
									Text = Computed(function()
										return if CurrentSelectionName:get() ~= "" 
											then `Change {ClientExportScriptName:get()}.Parent to: <b>{CurrentSelectionName:get()}</b>` 
											else `Select instance to set as {ClientExportScriptName:get()}.Parent`
									end),
									Visible = ExportOutput,
									BackgroundColor3 = ClientExportButtonColor, -- purple for client
									TextColor3 = Color3.fromRGB(240, 240, 240),
									Size = UDim2.new(0.9, 0, 0, 30),
									[OnEvent "Activated"] = function()
										if CurrentSelectionName:get() ~= "" then
											local selectedInstance = game:GetService("Selection"):Get()[1]
											if selectedInstance then
												local oldClientLocations = CollectionService:GetTagged("ZAPPY_CLIENT_PARENT_INSTANCE")
												for _, location in oldClientLocations do
													location:RemoveTag("ZAPPY_CLIENT_PARENT_INSTANCE")
													if ReparentExportedScriptsWhenOutputPathChanges:get() == true then
														-- we only want to reparent objects of the previous parent; it's possible users could have multiple locations
														-- they want to export specific code to, so if we use CollectionService:GetTagged() to move all scripts
														-- we would break that workflow
														for _, child in location:GetChildren() do 
															if child:HasTag("ZAPPY_CLIENT_SCRIPT") then
																child.Parent = selectedInstance
															end
														end
													end
												end
												selectedInstance:AddTag("ZAPPY_CLIENT_PARENT_INSTANCE")
												ClientExportInstance:set(selectedInstance)
											end
										end
									end,
									[OnEvent "MouseEnter"] = function()
										ClientExportButtonHovering:set(true)
									end,
									[OnEvent "MouseLeave"] = function()
										ClientExportButtonHovering:set(false)
									end,
									[Children] = {
										New "UICorner" {
											CornerRadius = UDim.new(0, 6)
										},
									},
								},
							},
						},
					},
					VerticalCollapsibleSection {
						Text = "Server Output",
						Visible = ExportOutput,
						[Children] = {
							Label {
								Text = CurrentServerExportInstanceText,
								Visible = ExportOutput,
							},
							NestedElement {
								TextInput {
									PlaceholderText = "Script Name",
									Visible = ExportOutput,
									Text = ServerExportScriptName,
									[Fusion.Out "Text"] = ServerExportScriptName
								},
							},
							SmallDescriptionLabel "Set custom server output path",
							NestedElement {
								New "TextButton" {
									Name = "ServerExportLocationPickerButton",
									RichText = true,
									Text = Computed(function()
										return if CurrentSelectionName:get() ~= "" 
											then `Change {ServerExportScriptName:get()}.Parent to: <b>{CurrentSelectionName:get()}</b>` 
											else `Select instance to set as {ServerExportScriptName:get()}.Parent`
									end),
									Size = UDim2.new(0.9, 0, 0, 30),
									Visible = ExportOutput,
									BackgroundColor3 = ServerExportButtonColor, -- green for server
									TextColor3 = Color3.fromRGB(240, 240, 240),
									[OnEvent "Activated"] = function()
										if CurrentSelectionName:get() ~= "" then
											local selectedInstance = game:GetService("Selection"):Get()[1]
											if selectedInstance then
												local oldServerLocations = CollectionService:GetTagged("ZAPPY_SERVER_PARENT_INSTANCE")
												for _, location in oldServerLocations do
													location:RemoveTag("ZAPPY_SERVER_PARENT_INSTANCE")
													if ReparentExportedScriptsWhenOutputPathChanges:get() == true then
														-- we only want to reparent objects of the previous parent; it's possible users could have multiple locations
														-- they want to export specific code to, so if we use CollectionService:GetTagged() to move all scripts
														-- we would break that workflow
														for _, child in location:GetChildren() do 
															if child:HasTag("ZAPPY_SERVER_SCRIPT") then
																child.Parent = selectedInstance
															end
														end
													end
												end
												selectedInstance:AddTag("ZAPPY_SERVER_PARENT_INSTANCE")
												ServerExportInstance:set(selectedInstance)
											end
										end
									end,
									[OnEvent "MouseEnter"] = function()
										ServerExportButtonHovering:set(true)
									end,
									[OnEvent "MouseLeave"] = function()
										ServerExportButtonHovering:set(false)
									end,
									[Children] = {
										New "UICorner" {
											CornerRadius = UDim.new(0, 6)
										},
									},
								},
							},
						},
					},
					VerticalCollapsibleSection {
						Text = "Tooling Output",
						Visible = ExportOutput,
						[Children] = {
							Label {
								Text = CurrentToolingExportInstanceText,
								Visible = ExportOutput,
							},
							NestedElement {
								TextInput {
									PlaceholderText = "Script Name",
									Visible = ExportOutput,
									Text = ToolingExportScriptName,
									[Fusion.Out "Text"] = ToolingExportScriptName
								},
							},
							SmallDescriptionLabel "Set custom tooling output path",
							NestedElement {
								New "TextButton" {
									Name = "ToolingExportLocationPickerButton",
									RichText = true,
									Text = Computed(function()
										return if CurrentSelectionName:get() ~= "" 
											then `Change {ToolingExportScriptName:get()}.Parent to: <b>{CurrentSelectionName:get()}</b>` 
											else `Select instance to set as {ToolingExportScriptName:get()}.Parent`
									end),
									Size = UDim2.new(0.9, 0, 0, 30),
									Visible = ExportOutput,
									BackgroundColor3 = ToolingExportButtonColor,
									TextColor3 = Color3.fromRGB(240, 240, 240),
									[OnEvent "Activated"] = function()
										if CurrentSelectionName:get() ~= "" then
											local selectedInstance = game:GetService("Selection"):Get()[1]
											if selectedInstance then
												local oldToolingLocations = CollectionService:GetTagged("ZAPPY_TOOLING_PARENT_INSTANCE")
												for _, location in oldToolingLocations do
													location:RemoveTag("ZAPPY_TOOLING_PARENT_INSTANCE")
													if ReparentExportedScriptsWhenOutputPathChanges:get() == true then
														-- we only want to reparent objects of the previous parent; it's possible users could have multiple locations
														-- they want to export specific code to, so if we use CollectionService:GetTagged() to move all scripts
														-- we would break that workflow
														for _, child in location:GetChildren() do 
															if child:HasTag("ZAPPY_TOOLING_SCRIPT") then
																child.Parent = selectedInstance
															end
														end
													end
												end
												selectedInstance:AddTag("ZAPPY_TOOLING_PARENT_INSTANCE")
												ToolingExportInstance:set(selectedInstance)
											end
										end
									end,
									[OnEvent "MouseEnter"] = function()
										ToolingExportButtonHovering:set(true)
									end,
									[OnEvent "MouseLeave"] = function()
										ToolingExportButtonHovering:set(false)
									end,
									[Children] = {
										New "UICorner" {
											CornerRadius = UDim.new(0, 6)
										},
									},
								},
							},
						},
					},
				},
			},		

			MainButton {
				Text = Computed(function()
					return if Busy:get() then "Generating..." else "Generate"
				end),
				--Enabled = Ready,-- causes permanent discolouration
				Active = Ready,

				Size = UDim2.new(1, 0, 0, 30),
				Activated = function()
					Busy:set(true)

					-- give the UI a chance to update
					task.wait()

					local A,B,C = xpcall(Zap, function(err) return debug.traceback(err, 2) end, IDLInput:get(), NoWarnings:get())
					if C then
						A,B = B,C
					end
					local success, output = A,B

					if (not success) or (typeof(output) ~= "table") then
						warn("Zap error:\n"..output)
						ClientOutput:set("")
						ServerOutput:set("")
						Diagnostics:set(output)
					else
						ClientOutput:set(output.client)
						ServerOutput:set(output.server)
						Diagnostics:set(output.diagnostics)
						ToolingOutput:set(output.tooling)
					end

					if not ((ServerOutput:get()=="") or (ClientOutput:get()=="")) then
						if ExportOutput:get() then
							if ServerExportInstance:get() ~= nil and ClientExportInstance:get() ~= nil then
								local clientScript = saveToScript(ClientExportScriptName:get(), ClientExportInstance:get(), output.client)
								clientScript:AddTag("ZAPPY_CLIENT_SCRIPT")
								local serverScript = saveToScript(ServerExportScriptName:get(), ServerExportInstance:get(), output.server)
								serverScript:AddTag("ZAPPY_SERVER_SCRIPT")
							else
								warn("Zappy: Output not saved; Server Export Parent Instance and/or Client Export Parent Instance have not been set.")
							end
							if ToolingExists:get() then
								local toolingScript = saveToScript(ToolingExportScriptName:get(), ToolingExportInstance:get() or ReplicatedStorage, output.tooling)
								toolingScript:AddTag("ZAPPY_TOOLING_SCRIPT")
							end
						end

						if SaveSettings:get() then
							local zappySettings = {
								IDL = IDLInput:get(),
								NoWarnings = NoWarnings:get(),
								ExportOutput = ExportOutput:get(),
								ServerExportScriptName = ServerExportScriptName:get(),
								ClientExportScriptName = ClientExportScriptName:get(),
								ToolingExportScriptName = ToolingExportScriptName:get()
							}
							local exported = HttpService:JSONEncode(zappySettings)

							saveStringToScript("__ZappySettings", ServerStorage, exported)
						end
					end

					Busy:set(false)
				end,
				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, 6)
					}
				},
			},
			VerticalCollapsibleSection {

				Text = "Output",
				[Children] = {
					Label {
						Text = "Diagnostics",
						Visible = DiagnosticsExists
					},
					TextInputAccented {
						Visible = DiagnosticsExists,
						Text = Diagnostics,
						TextColorGuide = Computed(function()
							if (ServerOutput:get()=="") or (ClientOutput:get()=="") then
								return Enum.StudioStyleGuideColor.ErrorText
							else
								return Enum.StudioStyleGuideColor.WarningText
							end
						end),
						TextEditable = false,
						ClearTextOnFocus = false,
						MultiLine = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextXAlignment = Enum.TextXAlignment.Left,
						Font = Enum.Font.Code,
					},

					Label {
						Text = "Client"
					},
					TextInputHighlighted {
						Text = ClientOutput,
						TextEditable = false,
						ClearTextOnFocus = false,
						MultiLine = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextXAlignment = Enum.TextXAlignment.Left,
						Font = Enum.Font.Code,
					},


					Label {
						Text = "Server"
					},
					TextInputHighlighted {
						Text = ServerOutput,
						TextEditable = false,
						ClearTextOnFocus = false,
						MultiLine = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextXAlignment = Enum.TextXAlignment.Left,
						Font = Enum.Font.Code,
					},

					Label {
						Text = "Tooling",
						Visible = ToolingExists
					},
					TextInputHighlighted {
						Text = ToolingOutput,
						Visible = ToolingExists,
						TextEditable = false,
						ClearTextOnFocus = false,
						MultiLine = true,
						AutomaticSize = Enum.AutomaticSize.Y,
						TextXAlignment = Enum.TextXAlignment.Left,
						Font = Enum.Font.Code,
					},
				}
			}
		}
	}
end