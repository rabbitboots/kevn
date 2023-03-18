-- KEVN ("Key Equals Value, Newline") -- a simple INI-like parser for Lua.
-- See README.md for more info.

--[[
MIT License

Copyright (c) 2023 RBTS

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
--]]


local kevn = {}


function errArgBadType(n, expected, val)
	error("argument #" .. n .. ": bad type (expected " .. expected .. ", got " .. type(val) .. ")", 2)
end


function errNoLineFeeds(n)
	error("argument #" .. n .. ": string cannot contain line feeds (newlines).", 2)
end


function kevn.str2Table(str, fn_group, fn_key)

	local tbl = {}

	-- Assertions
	-- [[
	if type(str) ~= "string" then errArgBadType(1, "string", str)
	elseif fn_group and type(fn_group) ~= "function" then errArgBadType(2, "function", fn_group)
	elseif fn_key and type(fn_key) ~= "function" then errArgBadType(3, "function", fn_key) end
	--]]

	local current_group
	local current_group_id = ""
	local line_n = 1 -- for error messages

	for line in string.gmatch(str, "\n?([^\n]*)") do

		local byte1 = string.byte(line, 1)

		-- Skip comments, empty lines and whitespace-only lines
		if #line > 0 and string.find(str, "%S") and byte1 ~= 59 then -- 59 == ';'
			-- Group declaration
			if byte1 == 91 then -- '['
				local group_id = string.match(line, "^([^%]]*)]%s*$", 2)
				local group_id_conv = group_id

				if fn_group then
					local result
					result, group_id_conv = fn_group(tbl, group_id)
					if not result then
						-- group_id_conv == error string
						return false, "LINE " .. line_n .. ": " .. group_id_conv or "(fn_group callback failed)"
					end
				end

				if group_id_conv == nil then
					return false, "LINE " .. line_n .. ": failed to parse group ID: |" .. line .. "|"

				elseif tbl[group_id_conv] then
					return false, "LINE " .. line_n .. ": duplicate group: |" .. group_id .. "|"

				else
					tbl[group_id_conv] = {}
					current_group_id = group_id_conv
					current_group = tbl[current_group_id]
				end

			-- Key-Value pair
			else
				local key, value = string.match(line, "^([^=]*)=(.*)$")
				local key_conv, value_conv = key, value

				if fn_key then
					local result
					result, key_conv, value_conv = fn_key(tbl, current_group_id, key, value)
					if not result then
						-- key_conv == error string
						return false, "LINE " .. line_n .. ": " .. key_conv or "(fn_key callback failed)"
					end
				end

				if key_conv == nil or value_conv == nil then
					return false, "LINE " .. line_n .. ": failed to parse key-value pair: |" .. line .. "|"

				else
					-- The default / global / header group is an empty string. It's only generated if a
					-- key-value pair is found before any group declaration, or if the file explicitly
					-- declares it at the top with "[]".
					if notcurrent_group then
						current_group_id = ""
						current_group = {}
						tbl[current_group_id] = current_group
					end

					if current_group[key_conv] then
						return false, "LINE " .. line_n .. ": duplicate key: |" .. key .. "|"
					end

					current_group[key_conv] = value_conv
				end
			end
		end

		line_n = line_n + 1
	end

	return tbl
end


local function parseGroup(temp, grp)

	for k, v in pairs(grp) do
		kevn.appendKey(temp, k, v)
	end
	temp[#temp + 1] = ""
end


function kevn.table2Str(tbl)

	local temp = {}
	local default_group = tbl[""]

	if default_group then
		parseGroup(temp, default_group)
	end

	for k, v in pairs(tbl) do
		if k ~= "" then
			kevn.appendGroupID(temp, k)
			parseGroup(temp, v)
		end
	end

	local str = table.concat(temp, "\n")
	return str
end


function kevn.appendGroupID(temp, group_id)

	-- Assertions
	-- [[
	if type(temp) ~= "table" then errArgBadType(1, "table", temp)
	elseif type(group_id) ~= "string" then errArgBadType(2, "string", group_id)
	elseif string.find(group_id, "]", 1, true) then error("group IDs cannot contain ']' characters.")
	elseif string.find(group_id, "\n", 1, true) then errNoLineFeeds(2) end
	--]]

	temp[#temp + 1] = "[" .. group_id .. "]"
end


function kevn.appendKey(temp, key, value)

	-- Assertions
	-- [[
	if type(temp) ~= "table" then errArgBadType(1, "table", temp)
	elseif type(key) ~= "string" then errArgBadType(2, "string", key)
	elseif string.find(key, "=") then error("keys cannot contain '=' characters.")
	elseif string.find(key, "^;") then error("keys cannot contain ';' as their first character.")
	elseif string.find(key, "\n", 1, true) then errNoLineFeeds(2)
	elseif type(value) ~= "string" then errArgBadType(3, "string", value)
	elseif string.find(value, "\n", 1, true) then errNoLineFeeds(3) end
	--]]

	temp[#temp + 1] = key .. "=" .. value
end



function kevn.appendComment(temp, comment)

	-- Assertions
	-- [[
	if type(temp) ~= "table" then errArgBadType(1, "table", temp)
	elseif type(comment) ~= "string" then errArgBadType(2, "string", comment) end
	--]]

	-- In Lua 5.1, 'string.gmatch(comment, "\n?([^\n]*)")' reads an additional empty-string
	-- match at the end. :(

	local i = 1;
	while i <= #comment do
		local j = string.find(comment, "\n", i, true) or #comment + 1
		temp[#temp + 1] = "; " .. string.sub(comment, i, j - 1)
		i = j + 1
	end
end


function kevn.appendEmpty(temp, n)

	-- Assertions
	-- [[
	if type(temp) ~= "table" then errArgBadType(1, "table", temp)
	elseif n and type(n) ~= "number" then errArgBadType(2, "number", n) end
	--]]

	n = n or 1
	n = math.max(1, math.floor(n))

	for i = 1, n do
		temp[#temp + 1] = ""
	end
end


return kevn
