local process = require("@std/process")
local fs = require("@std/fs")
local compile = require("../compile")

local SRC_PATH = process.args[2]
if not SRC_PATH then
	error("Missing source path")
end

local DST_PATH = process.args[3]
if not DST_PATH then
	error("Missing destination path")
end

local src = fs.readFileToString(SRC_PATH)
local dst = compile(src)
fs.writeStringToFile(DST_PATH, dst)
