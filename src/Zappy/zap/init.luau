--[[
(ngl original project was made by @hi.kitten but overtaken by @.ultrasonic)

with the contribution of

Fireboltofdeath
lemonade - Remuru
Gas - acomab

]]

-- this block of code was shamelessly kidnapped
-- https://github.com/gaymeowing/luauberries/blob/9bf76a3820822dbd59503b62ba5aa36051a608bf/libs/cross/init/init.luau#L12C1-L21C12
type Runtime = "Roblox" | "Lune" | "Unknown" | "Lute"

local RUNTIME: Runtime = if game and workspace then
		"Roblox"
	elseif string.find(_VERSION, "Lute") then
		"Lute"
	elseif string.find(_VERSION, "Lune") then
		"Lune"
	else
		"Unknown"

local init_zap = if (RUNTIME == "Roblox") then require("./zap/zapsynth") else require("zapsynth")
local memory


local wasm_imports = {
	["./zap_bg.js"] = {
		func_list = {
			__wbindgen_throw = function(ptr, len)
				if memory == nil then
					error("__wbindgen_throw was ran before memory was obtained")
				end
				error(buffer.readstring(memory.data, ptr, len))
			end
		}
	}
}

-- Unfortunately, if the init code needs __wbindgen_throw then there isn't much we can do. Because we cannot get the wasm memory before the init code runs.
-- Maybe it's a good idea to either move this stub into the generated wasynth code?
local zap = init_zap(wasm_imports)
memory = zap.memory_list.memory

local funcs = zap.func_list

local run = funcs.run
local free = funcs.__wbindgen_free
local code_free = funcs.__wbg_code_free
local return_free = funcs.__wbg_return_free

local malloc = funcs.__wbindgen_malloc

local get_return_code = funcs.__wbg_get_return_code
local get_code_client = funcs.__wbg_get_code_client
local get_code_server = funcs.__wbg_get_code_server
local get_output_code = funcs.__wbg_get_output_code
local get_code_tooling = funcs.__wbg_get_code_tooling



local function getCode(zap_code: string, no_warnings: boolean)
	-- Allocate space for the zap code in wasm memory and write the zap code to the buffer
	local zap_code_inmem = malloc(#zap_code, 1)
	buffer.writestring(memory.data, zap_code_inmem, zap_code, #zap_code)

	-- Call zap's run function with the pointer to the zap code
	local run_return = run(zap_code_inmem, #zap_code, if no_warnings then 1 else 0, 0)

	-- allocate a String for: diagnostics, client output code, server output code  | unsure why it's 16
	local string_alloc = malloc(16, 1)
	
	local output = {
		diagnostics = "",
		server = "",
		client = "",
		tooling = ""
	}
	
	do 
		local ptr, len = funcs.__wbg_get_return_diagnostics(run_return)

		local diagnostics = buffer.readstring(memory.data, ptr, len)

		free(ptr, len, 1)
		if #diagnostics ~= 0 then
			--[[
			just because something went wrong does not necessarily mean we need to
			abort here
			
			i've edited this part of the code to mimic the logic employed by the
			Zap playground (return diagnostics as well as any emitted output)
			]]
			--free(string_alloc, 16, 1)
			--return_free(run_return)
			
			output.diagnostics = diagnostics
			
			--return false, diagnostics
		end
	end


	-- Get the return's code field and the code's client/server field
	local code = get_return_code(run_return)
	if (code ~= 0) then
	
		local client_output = get_code_client(code)
		local server_output = get_code_server(code)
		local tooling_output = get_code_tooling(code)

		do
			local ptr, len = get_output_code(client_output)


			-- Read the output code string from the buffer and print it
			output.client = buffer.readstring(memory.data, ptr, len)

			free(ptr, len, 1)
			funcs.__wbg_output_free(client_output)
		end

		do
			local ptr, len = get_output_code(server_output)

			output.server = buffer.readstring(memory.data, ptr, len)

			free(ptr, len, 1)
			funcs.__wbg_output_free(server_output)
		end
		
		if tooling_output ~= 0 then
			do
				local ptr, len = get_output_code(tooling_output)

				-- Read the output code string from the buffer and print it
				output.tooling = buffer.readstring(memory.data, ptr, len)

				free(ptr, len, 1)
				funcs.__wbg_output_free(tooling_output)
			end
		end
		
		code_free(code)
	end

	free(string_alloc, 16, 1)
	return_free(run_return)

	return output
end

return getCode