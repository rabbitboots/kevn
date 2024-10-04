-- Test: KEVN
-- v2.0.0


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


require(PATH .. "test.strict")


local errTest = require(PATH .. "test.err_test")
local inspect = require(PATH .. "test.inspect")
local kevn = require(PATH .. "kevn")


local hex = string.char


local cli_verbosity
for i = 0, #arg do
	if arg[i] == "--verbosity" then
		cli_verbosity = tonumber(arg[i + 1])
		if not cli_verbosity then
			error("invalid verbosity value")
		end
	end
end


local self = errTest.new("KEVN", cli_verbosity)


self:registerFunction("kevn.decode()", kevn.decode)


-- [===[
self:registerJob("kevn.decode()", function(self)
	self:expectLuaError("arg #1 bad type", kevn.decode, 123)

	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("bad group declaration: incomplete", kevn.decode, "\n[???\n")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
		self:isEqual(ln, 2)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("bad group declaration: trailing text", kevn.decode, "\n[trailing_group_text]!?\n")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
		self:isEqual(ln, 2)
	end
	--]====]

	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("bad item declaration: empty key", kevn.decode, "\n=bar\n")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
		self:isEqual(ln, 2)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("bad item declaration: no '='", kevn.decode, "\nfoo\n")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
		self:isEqual(ln, 2)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("empty values permitted", kevn.decode, "\nfoo=\n")
		self:print(3, ret, err, ln)
		self:isType(ret, "table")
		self:isEqual(ret[""].foo, "")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("empty input = empty output", kevn.decode, "")
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)
		self:isType(ret, "table")
		self:isEvalFalse(next(ret))
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("duplicate groups", kevn.decode, "[g]\n[g]")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("duplicate keys in a group", kevn.decode, "[g]\na=b\na=c\n")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] group declaration", kevn.decode, "[grp]")
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)
		self:isType(ret["grp"], "table")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("trailing whitespace after group declaration permitted", kevn.decode, "[grp]   \n")
		self:print(3, ret, err, ln)
		self:isType(ret, "table")
		self:isType(ret["grp"], "table")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] item declaration", kevn.decode, "zoop=bar")
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)
		self:isEqual(ret[""].zoop, "bar")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] skip comment lines", kevn.decode, ";foo\na=b\n;baz")
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)
		self:isEqual(ret[""].a, "b")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] unescape bytes in '\\xx' notation", kevn.decode, "[\\5d]\n\\3d=\\0a")
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)
		self:isType(ret["]"], "table")
		self:isEqual(ret["]"]["="], "\n")
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] bad escape sequence (group ID)", kevn.decode, "[\\zz]bad=escape")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] bad escape sequence (in key)", kevn.decode, "\\zz=bad_escape")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
	end
	--]====]


	-- [====[
	do
		local ret, err, ln = self:expectLuaReturn("[+] bad escape sequence (in value)", kevn.decode, "dir=C:\\DOS")
		self:print(3, ret, err, ln)
		self:isEvalFalse(ret)
	end
	--]====]


	-- [====[
	do
		local str = [[
a_key_in=the default group
a=b

[foobar]
foo=bar
;for=bach
baz=bop
a=b

doop=1

[esc\40pe]
\41=\42
]]
		local ret, err, ln = self:expectLuaReturn("[+] test with all features", kevn.decode, str)
		self:print(3, ret, err, ln)
		self:isEvalTrue(ret)

		self:isType(ret[""], "table")
		self:isEqual(ret[""].a_key_in, "the default group")
		self:isEqual(ret[""].a, "b")

		self:isType(ret["foobar"], "table")
		self:isEqual(ret["foobar"].foo, "bar")
		self:isEqual(ret["foobar"].baz, "bop")
		self:isEqual(ret["foobar"].a, "b")
		self:isEqual(ret["foobar"].doop, "1")

		self:isType(ret["esc@pe"], "table")
		self:isEqual(ret["foobar"].a, "b")
	end

	--]====]
end
)
--]===]


-- [===[
self:registerJob("kevn.encode()", function(self)
	self:expectLuaError("arg #1 bad type", kevn.encode, 123)

	-- [====[
	do
		local rv = self:expectLuaReturn("empty table == empty string", kevn.encode, {})
		self:isEqual(rv, "")
	end
	--]====]


	-- [====[
	do
		self:expectLuaError("bad type for group ID", kevn.encode, {[33]={}})
		self:expectLuaError("bad type for key", kevn.encode, {grp={[false]="bar"}})
		self:expectLuaError("bad type for value", kevn.encode, {grp={foo=true}})
	end
	--]====]


	-- [====[
	do
		local rv = self:expectLuaReturn("escape characters in group ID", kevn.encode, {["[]"]={}})
		print("|"..rv.."|")
		self:isEqual(rv, "[[\\5d]")
	end
	--]====]
end
)
--]===]


-- [===[
self:registerJob("kevn.addGroupID()", function(self)
	self:expectLuaError("arg #1 bad type", kevn.addGroupID, 123, "foo")
	self:expectLuaError("arg #2 bad type", kevn.addGroupID, {}, function() end)

	self:expectLuaError("group name is an empty string", kevn.addGroupID, {}, "")

	-- The rest of kevn.addGroupID() is tested in kevn.encode().
end
)
--]===]


-- [===[
self:registerJob("kevn.addItem()", function(self)
	self:expectLuaError("arg #1 bad type", kevn.addItem, false, "foo", "bar")
	self:expectLuaError("arg #2 bad type", kevn.addItem, {}, function() end, "bar")
	self:expectLuaError("arg #3 bad type", kevn.addItem, {}, "foo", function() end)

	self:expectLuaError("key name is an empty string", kevn.addItem, {}, "", "bar")

	-- [====[
	do
		local t = {}
		self:expectLuaReturn("only escape ';' in keys if it's the first character", kevn.addItem, t, ";;", "")
		self:isEqual(t[1], "\\3b;=")
	end
	--]====]


	-- [====[
	do
		local t = {}
		self:expectLuaReturn("only escape '[' in keys if it's the first character", kevn.addItem, t, "[[", "")
		self:isEqual(t[1], "\\5b[=")
	end
	--]====]

	-- The rest of kevn.addItem() is tested in kevn.encode().
end
)
--]===]


self:runJobs()
