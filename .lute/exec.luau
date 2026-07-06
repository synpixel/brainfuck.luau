local process = require("@std/process")
local fs = require("@std/fs")
local luau = require("@std/luau")
local io = require("@std/io")
local compile = require("../compile")

local SRC_PATH = process.args[2]
if not SRC_PATH then
	error("Missing source path")
end

local function require_override(path: string)
	if path == "@std/io" then
		return io
	end
	error("unknown require")
end

local src = fs.readFileToString(SRC_PATH)
local dst = compile(src)
local bytecode = luau.compile(dst)
luau.load(bytecode, nil, {
	buffer = buffer,
	string = string,
	require = require_override,
})()
