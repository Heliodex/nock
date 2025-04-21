local main = require "./main"

local nstring = main.nstring
local stringn = main.stringn
local nock = main.nock

type Test = {
	input: string,
	output: string?,
	err: string?,
}

local tests: { Test } = {
	-- opcode 0
	{
		input = "[[[4 5] [6 14 15]] 0 1]",
		output = "[[4 5] [6 [14 15]]]",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 2]",
		output = "[4 5]",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 3]",
		output = "[6 [14 15]]",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 4]",
		output = "4",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 5]",
		output = "5",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 6]",
		output = "6",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 7]",
		output = "[14 15]",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 10]",
		err = "/[2 n] -> /[2 /[1 n]] -> /[2 n]",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 14]",
		output = "14",
	},
	{
		input = "[[[4 5] [6 14 15]] 0 15]",
		output = "15",
	},

	-- opcode 1
	{
		input = "[0 1 3]",
		output = "3",
	},
	{
		input = "[999 1 0]",
		output = "0",
	},

	{
		input = "[42 1 153 218]",
		output = "[153 218]",
	},

	-- opcode 2
	{
		input = "[77 2 [1 42] [1 1 153 218]]",
		output = "[153 218]",
	},
	{
		input = "[0 2 [1 0] [1 1 55]]",
		output = "55",
	},
}

for i, test in tests do
	print(`TEST {i}\n`)

	local input = stringn(test.input)
	if input.fail then
		print "FAIL"
		print("stringn", input.err)
		return
	end

	if type(input.value) ~= "table" then
		print "FAIL"
		print "invalid test: input is not a cell"
		return
	end

	local res = nock(input.value)
	if res.fail and test.err then
		if test.err ~= res.err then
			print "FAIL"
			print("expected", test.err)
			print("got", res.err)
			return
		end
	elseif not res.fail and test.output then
		local out = nstring(res.value)

		if test.output ~= out then
			print "FAIL"
			print("expected", test.output)
			print("got", out)
			return
		end
	else
		print "FAIL"

		if test.output and res.fail then
			print("expected output", test.output)
			print("got failure", res.err)
		elseif test.err and not res.fail then
			print("expected failure", test.err)
			print("got output", res.value)
		else
			print "invalid test"
		end
		return
	end

	print(test.output)
	print "PASS\n"
end
