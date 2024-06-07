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
local VerticalCollapsibleSection = require(StudioComponents.VerticalCollapsibleSection)
local Checkbox = require(StudioComponents.Checkbox)

local Title = require(StudioComponents.Title)

local Fusion = require(Packages.Fusion)

local New = Fusion.New
local Computed = Fusion.Computed
local Value = Fusion.Value
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate
local Observer = Fusion.Observer

local function saveToScript(scriptName: string, scriptParent: Instance, source: string)
	local ExportScript: ModuleScript = (scriptParent:FindFirstChild(scriptName) :: ModuleScript) or Instance.new("ModuleScript", scriptParent)
	ExportScript.Name = scriptName
	ExportScript.Source = source
end

local function loadFromScript(scriptName: string, scriptParent: Instance): string?
	local ExportScript: ModuleScript = (scriptParent:FindFirstChild(scriptName) :: ModuleScript)
	if not ExportScript then
		return nil
	else
		return ExportScript.Source
	end
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

	Plugin.Unloading:Connect(widgetsEnabledObserver:onChange(function()
		enableButton:SetActive(widgetsEnabled:get(false))
	end))

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

	local IDLInput = Value("")

	local ServerOutput = Value("")
	local ClientOutput = Value("")

	local Diagnostics = Value("")
	local DiagnosticsExists = Computed(function()
		return Diagnostics:get() ~= ""
	end)

	local Busy = Value(false)
	local Success = Value()

	local Ready = Computed(function()
		return not Busy:get()
	end)

	local ExportOutput = Value(false)
	local ClientExportLocation = Value("ZapClient")
	local ServerExportLocation = Value("ZapServer")

	local SaveSettings = Value(false)

	Plugin.Unloading:Connect(widgetsEnabledObserver:onChange(function()
		if widgetsEnabled:get(false) then
			local loaded = loadFromScript("__ZappySettings", ServerStorage)
			if loaded then
				local parsedSettings: {
					IDL: string,
					ExportOutput: boolean,
					ServerExportLocation: string,
					ClientExportLocation: string
				} = HttpService:JSONDecode(loaded)
				SaveSettings:set(true)

				IDLInput:set(parsedSettings.IDL)
				ExportOutput:set(parsedSettings.ExportOutput)
				ServerExportLocation:set(parsedSettings.ServerExportLocation)
				ClientExportLocation:set(parsedSettings.ClientExportLocation)
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
				Text = "Auto-export output",
				Value = ExportOutput
			},

			Label {
				Text = "Client export location",
				Visible = ExportOutput,
			},
			TextInput {
				PlaceholderText = "in game.ReplicatedStorage",
				Visible = ExportOutput,
				Text = ClientExportLocation,
				[Fusion.Out "Text"] = ClientExportLocation
			},

			Label {
				Text = "Server export location",
				Visible = ExportOutput,
			},
			TextInput {
				PlaceholderText = "in game.ServerScriptService",
				Visible = ExportOutput,
				Text = ServerExportLocation,
				[Fusion.Out "Text"] = ServerExportLocation
			},

			Checkbox {
				Text = "Save settings on successful generation",
				Value = SaveSettings
			},

			MainButton {
				Text = Computed(function()
					return if Busy:get() then "Generating..." else "Generate"
				end),
				--Enabled = Ready,-- causes permament discolouration
				Active = Ready,

				Size = UDim2.new(1, 0, 0, 30),
				Activated = function()
					Busy:set(true)

					-- give the UI a chance to update
					task.wait()

					local A,B,C = xpcall(Zap, function(err) return debug.traceback(err, 2) end, IDLInput:get())
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
					end

					if (not DiagnosticsExists:get()) then

						if ExportOutput:get() then
							saveToScript(ServerExportLocation:get(), ServerScriptService, output.server)
							saveToScript(ClientExportLocation:get(), ReplicatedStorage, output.client)
						end

						if SaveSettings:get() then
							local zappySettings = {
								IDL = IDLInput:get(),
								ExportOutput = ExportOutput:get(),
								ServerExportLocation = ServerExportLocation:get(),
								ClientExportLocation = ClientExportLocation:get()
							}
							local exported = HttpService:JSONEncode(zappySettings)

							saveToScript("__ZappySettings", ServerStorage, exported)

						end
					end

					Busy:set(false)
				end,
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
					TextInput {
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
					TextInput {
						Text = ServerOutput,
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