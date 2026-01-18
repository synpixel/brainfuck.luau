local process = require("@lune/process")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local translator = require("../translator")

local FILE_PATH = process.args[1]
if not FILE_PATH then
	error("cli needs file path")
end

local file = fs.readFile(FILE_PATH)
local code = translator.translate(file)
local bytecode = luau.compile(code, { optimizationLevel = 2 })
luau.load(bytecode, { codegenEnabled = true })()
