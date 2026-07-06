local function compile(src: string): string
	local cursor = 0

	local function advance(): string
		local char = string.sub(src, cursor + 1, cursor + 1)
		cursor += 1
		return char
	end

	local function enumerate(char: string): number
		local initial = char
		local count = 0
		while char == initial do
			char = advance()
			count += 1
		end
		cursor -= 1
		return count
	end

	local dst = ""
	local function writeln(str: string)
		dst ..= str .. "\n"
	end

	writeln("--!native")
	writeln("--!optimize 2")

	writeln('local io = require("@std/io")')

	writeln("local mem = buffer.create(30e3)")
	writeln("local ptr = 0")

	local function mem_read(): string
		return "buffer.readu8(mem, ptr)"
	end

	local function mem_write(value: string): string
		return `buffer.writeu8(mem, ptr, {value})`
	end

	while cursor < #src do
		local inst = advance()

		if inst == ">" then
			local offset = enumerate(">")
			writeln(`ptr += {offset}`)
		elseif inst == "<" then
			local offset = enumerate("<")
			writeln(`ptr -= {offset}`)
		elseif inst == "+" then
			local increment = enumerate("+")
			writeln(mem_write(`{mem_read()} + {increment}`))
		elseif inst == "-" then
			local decrement = enumerate("-")
			writeln(mem_write(`{mem_read()} - {decrement}`))
		elseif inst == "." then
			writeln(`io.write(string.char({mem_read()}))`)
		elseif inst == "," then
			writeln(mem_write("string.byte(io.read())"))
		elseif inst == "[" then
			writeln(`while {mem_read()} > 0 do`)
		elseif inst == "]" then
			writeln("end")
		end
	end

	return dst
end

return compile
