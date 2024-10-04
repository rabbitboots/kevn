-- KEVN
-- v2.0.0


--[[
MIT License

Copyright (c) 2023 - 2024 RBTS

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


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local _argType = require(PATH .. "pile_arg_check").type


M.lang = {
	err_bad_ln = "syntax error",
	err_bad_esc = "invalid escape sequence",
	err_dupe_grp = "duplicate group",
	err_dupe_key = "duplicate key in group",
	err_enc_not_str = "group IDs, keys and values must be strings",
	err_str_1_char = "group IDs and keys must contain at least one character"
}
local lang = M.lang


local _unesc_err
local function _hof_esc(s) return tostring("\\" .. string.format("%02x", s:byte())) end
local function _hof_unesc(s)
	local n = tonumber(s, 16)
	if not n then
		_unesc_err = true
		return
	end
	return string.char(n)
end
local function _unesc(s) return s:gsub("\\(..)", _hof_unesc) end


function M.decode(s)
	_argType(1, s, "string")

	_unesc_err = nil
	s = s:gsub("\r\n", "\n")
	local grps, ln, this_grp = {}, 1
	for line in s:gmatch("([^\n]*)\n?") do
		if line:find("^[^;]") and line:find("%S") then
			local grp_id = line:match("^%[([^%]]+)]%s*$")
			if grp_id then
				grp_id = _unesc(grp_id)
				if grps[grp_id] then return nil, lang.err_dupe_grp, ln end
				grps[grp_id] = {}
				this_grp = grps[grp_id]
			else
				local k, v = line:match("^([^=]+)=(.*)$")
				if not k then return nil, lang.err_bad_ln, ln end
				if not this_grp then
					grps[""] = {}
					this_grp = grps[""]
				end
				k, v = _unesc(k), _unesc(v)
				if this_grp[k] then return nil, lang.err_dupe_key, ln end
				this_grp[k] = v
			end
		end
		if _unesc_err then return nil, lang.err_bad_esc, ln end
		ln = ln + 1
	end
	return grps
end


local function _parseGroup(t, grp, lf)
	local srt = {}
	for k, v in pairs(grp) do
		if type(k) ~= "string" then error(lang.err_enc_not_str) end
		srt[#srt + 1] = k
	end
	table.sort(srt)
	for i, k in ipairs(srt) do
		M.addItem(t, k, grp[k])
	end
	if lf then
		t[#t + 1] = ""
	end
end


function M.encode(tbl)
	_argType(1, tbl, "table")

	local tmp, def_grp = {}, tbl[""]
	if def_grp then _parseGroup(tmp, def_grp, true) end

	local srt = {}
	for k in pairs(tbl) do
		if type(k) ~= "string" then error(lang.err_enc_not_str) end
		if k ~= "" then
			srt[#srt + 1] = k
		end
	end
	table.sort(srt)
	for i, k in ipairs(srt) do
		M.addGroupID(tmp, k)
		_parseGroup(tmp, tbl[k], i < #srt)
	end

	return table.concat(tmp, "\n")
end


function M.addGroupID(t, gid)
	_argType(1, t, "table")
	_argType(2, gid, "string")
	if #gid == 0 then error(lang.err_str_1_char) end

	gid = gid:gsub("[\r\n%]\\]", _hof_esc)
	t[#t + 1] = "[" .. gid .. "]"
end


function M.addItem(t, k, v)
	_argType(1, t, "table")
	_argType(2, k, "string")
	_argType(3, v, "string")
	if #k == 0 then error(lang.err_str_1_char) end

	local k1 = k:sub(1, 1)
	k = k:gsub("[\r\n=\\]", _hof_esc)
	if k1 == ";" then k = "\\3b" .. k:sub(2)
	elseif k1 == "[" then k = "\\5b" .. k:sub(2) end
	v = v:gsub("[\r\n\\]", _hof_esc)
	t[#t + 1] = k .. "=" .. v
end


return M
