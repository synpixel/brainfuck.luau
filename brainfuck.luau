--!native
--!optimize 2

local stdio = require("@lune/stdio")

local RIGHT = 0
local LEFT = 1
local INCREMENT = 2
local DECREMENT = 3
local PUT = 4
local TAKE = 5
local LOOP_START = 6
local LOOP_STOP = 7

local function readCharAt(str: string, cursor: number): string
	return string.sub(str, cursor, cursor)
end

local function compile(file: string): buffer
	file = string.gsub(file, "[^><%+%-%.,%[%]]", "")

	local loopSection = buffer.create(4096)
	local codeSection = buffer.create(16384)
	local loopSectionOffset = 0
	local codeSectionOffset = 0

	local loopStack = buffer.create(256)
	local loopStackOffset = 0

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

			buffer.writeu8(codeSection, codeSectionOffset, RIGHT)
			buffer.writeu16(codeSection, codeSectionOffset + 1, total)
			codeSectionOffset += 3
		elseif char == "<" then
			local total = 0
			while char == "<" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			buffer.writeu8(codeSection, codeSectionOffset, LEFT)
			buffer.writeu16(codeSection, codeSectionOffset + 1, total)
			codeSectionOffset += 3
		elseif char == "+" then
			local total = 0
			while char == "+" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			buffer.writeu8(codeSection, codeSectionOffset, INCREMENT)
			buffer.writeu16(codeSection, codeSectionOffset + 1, total)
			codeSectionOffset += 3
		elseif char == "-" then
			local total = 0
			while char == "-" do
				char = readCharAt(file, cursor)
				cursor += 1
				total += 1
			end
			cursor -= 1

			buffer.writeu8(codeSection, codeSectionOffset, DECREMENT)
			buffer.writeu16(codeSection, codeSectionOffset + 1, total)
			codeSectionOffset += 3
		elseif char == "." then
			buffer.writeu8(codeSection, codeSectionOffset, PUT)
			codeSectionOffset += 1
		elseif char == "," then
			buffer.writeu8(codeSection, codeSectionOffset, TAKE)
			codeSectionOffset += 1
		elseif char == "[" then
			buffer.writeu16(loopStack, loopStackOffset, codeSectionOffset)
			loopStackOffset += 2

			buffer.writeu8(codeSection, codeSectionOffset, LOOP_START)
			codeSectionOffset += 1
		elseif char == "]" then
			loopStackOffset -= 2
			local startOffset = buffer.readu16(loopStack, loopStackOffset)
			local stopOffset = codeSectionOffset

			buffer.writeu8(codeSection, codeSectionOffset, LOOP_STOP)
			codeSectionOffset += 1

			buffer.writeu16(loopSection, loopSectionOffset, startOffset)
			buffer.writeu16(loopSection, loopSectionOffset + 2, stopOffset)
			loopSectionOffset += 4
		end
	end

	local bytecode = buffer.create(2 + loopSectionOffset + codeSectionOffset)
	buffer.writeu16(bytecode, 0, loopSectionOffset)
	buffer.copy(bytecode, 2, loopSection, 0, loopSectionOffset)
	buffer.copy(bytecode, 2 + loopSectionOffset, codeSection, 0, codeSectionOffset)
	return bytecode
end

local function load(bytecode: buffer)
	local len = buffer.len(bytecode)

	local loopSectionLength = buffer.readu16(bytecode, 0)
	local codeSectionOffset = 2 + loopSectionLength

	local offset = 2

	local loopStartToStopOffset: { [number]: number } = {}
	local loopStopToStartOffset: { [number]: number } = {}

	while offset < codeSectionOffset do
		local startOffset = buffer.readu16(bytecode, offset)
		local stopOffset = buffer.readu16(bytecode, offset + 2)
		offset += 4

		loopStartToStopOffset[startOffset] = stopOffset
		loopStopToStartOffset[stopOffset] = startOffset
	end

	local pointer = 0
	local memory = buffer.create(30e3)

	local stdinBuffer = ""
	local stdinCursor = 1

	local stdoutBuffer = ""
	local prevChar: number?

	while offset < len do
		local op = buffer.readu8(bytecode, offset)
		offset += 1

		if op == RIGHT then
			local total = buffer.readu16(bytecode, offset)
			offset += 2

			pointer += total
		elseif op == LEFT then
			local total = buffer.readu16(bytecode, offset)
			offset += 2

			pointer -= total
		elseif op == INCREMENT then
			local total = buffer.readu16(bytecode, offset)
			offset += 2

			local value = buffer.readu8(memory, pointer)
			buffer.writeu8(memory, pointer, value + total)
		elseif op == DECREMENT then
			local total = buffer.readu16(bytecode, offset)
			offset += 2

			local value = buffer.readu8(memory, pointer)
			buffer.writeu8(memory, pointer, value - total)
		elseif op == PUT then
			local value = buffer.readu8(memory, pointer)
			if prevChar ~= value then
				stdio.write(stdoutBuffer)
				stdoutBuffer = ""
			end
			prevChar = value
			stdoutBuffer ..= string.char(value)
		elseif op == TAKE then
			if stdinCursor > #stdinBuffer then
				stdinBuffer ..= string.sub(stdio.readLine(), 1, -2)
			end

			local char = readCharAt(stdinBuffer, stdinCursor)
			stdinCursor += 1

			local value = string.byte(char)
			buffer.writeu8(memory, pointer, value or 0)
		elseif op == LOOP_START then
			local value = buffer.readu8(memory, pointer)
			if value ~= 0 then
				continue
			end

			local stopOffset = loopStartToStopOffset[offset - codeSectionOffset - 1]
			offset = codeSectionOffset + stopOffset
		elseif op == LOOP_STOP then
			local value = buffer.readu8(memory, pointer)
			if value == 0 then
				continue
			end

			local startOffset = loopStopToStartOffset[offset - codeSectionOffset - 1]
			offset = codeSectionOffset + startOffset
		else
			error(`unknown operation: {op}`)
		end
	end

	if #stdoutBuffer > 0 then
		stdio.write(stdoutBuffer)
	end
end

return {
	compile = compile,
	load = load,
}
