local process = require("@lune/process")
local fs = require("@lune/fs")
local brainfuck = require("../brainfuck")

local FILE_PATH = process.args[1]
if not FILE_PATH then
	error("cli needs file path")
end

local file = fs.readFile(FILE_PATH)
local bytecode = brainfuck.compile(file)
brainfuck.load(bytecode)
