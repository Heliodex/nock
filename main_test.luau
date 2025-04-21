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
	-- distribution
	{
		input = "[[[1 2] [3 4]] [[0 3] [4 0 5]]]",
		output = "[[3 4] 3]",
	},

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
	{
		input = "[[50 51] [0 [0 1]]]",
		err = "/a -> /a",
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
	{
		input = "[[[1 2] [3 4]] [1 7]]",
		output = "7",
	},
	{
		input = "[[[1 2] [3 4]] [1 [7 8 9]]]",
		output = "[7 [8 9]]",
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
	{
		input = "[[1 2] [2 [0 2] [1 [0 1]]]]",
		output = "1",
	},

	-- opcode 3
	{
		input = "[0 3 [1 [1 2]]]",
		output = "0",
	},
	{
		input = "[0 3 [1 56]]",
		output = "1",
	},
	{
		input = "[[[1 2] [3 4]] [3 0 1]]",
		output = "0",
	},
	{
		input = "[[[1 2] [3 4]] [3 0 4]]",
		output = "1",
	},

	-- opcode 4
	{
		input = "[0 4 [1 2]]",
		output = "3",
	},
	{
		input = "[0 4 [1 56]]",
		output = "57",
	},
	{
		input = "[2 4 [0 1]]",
		output = "3",
	},
	{
		input = "[56 4 [0 1]]",
		output = "57",
	},
	{
		input = "[5 4 [3 0 1]]",
		output = "2",
	},
	{
		input = "[0 4 [1 [5 5]]]",
		err = "+[a b] -> +[a b]",
	},

	-- opcode 5
	{
		input = "[77 5 [1 9] [1 9]]",
		output = "0",
	},
	{
		input = "[77 5 [1 8] [1 9]]",
		output = "1",
	},
	{
		input = "[77 5 [1 8] [1 [8 8]]]",
		output = "1",
	},
	{
		input = "[77 5 [1 [8 8]] [1 [8 8]]]",
		output = "0",
	},
	{
		input = "[[[1 2] [1 2]] [5 [0 2] [0 3]]]",
		output = "0",
	},
	{
		input = "[[[1 2] [3 4]] [5 [0 2] [0 3]]]",
		output = "1",
	},
	{
		input = "[[[1 2] [99 99]] [5 [0 5] [4 0 4]]]",
		output = "0",
	},

	-- opcode 6
	{
		input = "[42 6 [1 0] [4 0 1] [1 233]]",
		output = "43",
	},
	{
		input = "[42 6 [1 1] [4 0 1] [1 233]]",
		output = "233",
	},
	{
		input = "[42 6 [1 0] [1 232] [1 233]]",
		output = "232",
	},
	{
		input = "[42 6 [1 1] [1 232] [1 233]]",
		output = "233",
	},
	{
		input = "[42 6 [1 2] [1 232] [1 233]]",
		err = "/[2 n] -> /[2 /[1 n]] -> /[2 n]",
	},

	-- opcode 7
	{
		input = "[42 7 [4 0 1] [4 0 1]]",
		output = "44",
	},
	{
		input = "[42 7 [0 1] [4 0 1]]",
		output = "43",
	},
	{
		input = "[42 7 [0 1] [0 1]]", -- lmfao
		output = "42",
	},
	{
		input = "[42 7 [7 [7 [7 [4 0 1] [4 0 1]] 7 [4 0 1] [4 0 1]] [7 [7 [4 0 1] [4 0 1]] 7 [4 0 1] [4 0 1]]] 7 [7 [7 [4 0 1] [4 0 1]] 7 [4 0 1] [4 0 1]] 7 [7 [4 0 1] [4 0 1]] 7 [4 0 1] [4 0 1]]", -- am I a genius or what
		output = "58",
	},

	-- opcode 8
	{
		input = "[42 8 [4 0 1] [0 1]]",
		output = "[43 42]",
	},
	{
		input = "[42 8 [4 0 1] [4 0 3]]",
		output = "43",
	},

	-- opcode 10
	-- {
	-- 	input = "[0 10 [5 [0 1]] [0 1]]",
	-- 	output = "43",
	-- },

	-- other
	{
		input = "[42 [1 0] [0 1]]",
		output = "[0 42]",
	},
	{
		input = "[42 2 [[1 0] [0 1]] [1 [0 1]]]",
		output = "[0 42]",
	},
	{
		input = "[42 7 [[1 0] [0 1]] [0 1]]",
		output = "[0 42]",
	},
	{
		input = "[42 8 [1 0] [0 1]]",
		output = "[0 42]",
	},

	-- holy grail
	{
		input = "[1 8 [1 0] [8 [1 6 [5 [0 7] 4 0 6] [0 6] 9 2 [0 2] [4 0 6] 0 7] 9 2 0 1]]",
		output = "0",
	}, -- i tried this with s = 0, and it crashed. my entire. ship.
}

for i, test in tests do
	print(`TEST {i}\n`)

	local input = stringn(test.input)
	if input.fail then
		print "FAIL"
		print("stringn", input.err)
		return
	end

	local v = input.value
	if type(v) ~= "table" then
		print "FAIL"
		print "invalid test: input is not a cell"
		return
	end

	local res = nock(v.n1, v.n2)
	if res.fail and test.err then
		if test.err ~= res.err then
			print "FAIL"
			print("expected", test.err)
			print("got     ", res.err)
			return
		end
	elseif not res.fail and test.output then
		local out = nstring(res.value)

		if test.output ~= out then
			print "FAIL"
			print("expected", test.output)
			print("got     ", out)
			return
		end
	else
		print "FAIL"

		if test.output and res.fail then
			print("expected output", test.output)
			print("got failure    ", res.err)
		elseif test.err and not res.fail then
			print("expected failure", test.err)
			print("got output      ", res.value)
		else
			print "invalid test"
		end
		return
	end

	print(test.output or test.err)
	print "PASS\n"
end
