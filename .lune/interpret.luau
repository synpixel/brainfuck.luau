local process = require("@lune/process")
local fs = require("@lune/fs")
local interpreter = require("../interpreter")

local FILE_PATH = process.args[1]
if not FILE_PATH then
	error("cli needs file path")
end

local file = fs.readFile(FILE_PATH)
local bytecode = interpreter.compile(file)
interpreter.load(bytecode)
