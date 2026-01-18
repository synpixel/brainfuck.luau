local function readCharAt(str: string, cursor: number): string
	return string.sub(str, cursor, cursor)
end

local function translate(file: string): string
	file = string.gsub(file, "[^><%+%-%.,%[%]]", "")

	local output = ""

	output ..= 'local stdio = require("@lune/stdio")\n'

	output ..= "local memory = buffer.create(30e3)\n"
	output ..= "local pointer = 0\n"

	output ..= 'local stdoutBuffer = ""\n'
	output ..= "local previousChar: number?\n"

	output ..= 'local stdinBuffer = ""\n'
	output ..= "local stdinCursor = 1\n"

	output ..= "local function read(): number\n"
	output ..= "return buffer.readu8(memory, pointer)\n"
	output ..= "end\n"

	output ..= "local function write(value: number)\n"
	output ..= "buffer.writeu8(memory, pointer, value)\n"
	output ..= "end\n"

	output ..= "local function put()\n"
	output ..= "local value = read()\n"
	output ..= "if previousChar ~= value then\n"
	output ..= "stdio.write(stdoutBuffer)\n"
	output ..= 'stdoutBuffer = ""\n'
	output ..= "end\n"
	output ..= "previousChar = value\n"
	output ..= "stdoutBuffer ..= string.char(value)\n"
	output ..= "end\n"

	output ..= "local function take()\n"
	output ..= "if stdinCursor > #stdinBuffer then\n"
	output ..= "stdinBuffer ..= string.sub(stdio.readLine(), 1, -2)\n"
	output ..= "end\n"
	output ..= "local char = string.sub(stdinBuffer, stdinCursor, stdinCursor)\n"
	output ..= "stdinCursor += 1\n"
	output ..= "local value = string.byte(char)\n"
	output ..= "write(value or 0)\n"
	output ..= "end\n"

	local cursor = 1

	while cursor <= #file do
		local char = readCharAt(file, cursor)
		cursor += 1

		if char == ">" then
			local total = 0
			while char == ">" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			output ..= `pointer += {total}\n`
		elseif char == "<" then
			local total = 0
			while char == "<" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			output ..= `pointer -= {total}\n`
		elseif char == "+" then
			local total = 0
			while char == "+" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			output ..= `write(read() + {total})\n`
		elseif char == "-" then
			local total = 0
			while char == "-" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			output ..= `write(read() - {total})\n`
		elseif char == "." then
			output ..= "put()\n"
		elseif char == "," then
			output ..= "take()\n"
		elseif char == "[" then
			output ..= "while read() > 0 do\n"
		elseif char == "]" then
			output ..= "end\n"
		end
	end

	output ..= "if #stdoutBuffer > 0 then\n"
	output ..= "stdio.write(stdoutBuffer)\n"
	output ..= "end\n"

	return output
end

return {
	translate = translate,
}
