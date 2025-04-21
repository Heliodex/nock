-- An atom is a natural number.
type Atom = number

-- A cell is an ordered pair of nouns.
type Cell = { n1: Noun, n2: Noun }

local function cell(n1: Noun, n2: Noun): Cell return { n1 = n1, n2 = n2 } end

-- A noun is an atom or a cell.
type Noun = Atom | Cell

-- useful result thing
type Result = {
	fail: false,
	value: Noun,
} | {
	fail: true,
	err: string,
}

local function ok(value: Noun): Result return { fail = false, value = value } end

-- Represents logical bottom states
local function err(e: string): Result return { fail = true, err = e } end

-- stringification baby
local function nstring(n: Noun): string
	if type(n) == "number" then
		return tostring(n)
	elseif type(n) == "table" then
		return `[{nstring(n.n1)} {nstring(n.n2)}]`
	end
	return `?{type(n)}?`
end

-- [a b c] -> [a [b c]]
local function stringn(s: string): Result
	local n = tonumber(s)
	if n and n >= 0 and math.floor(n) == n then return ok(n) end

	-- [a b] -> cell(a, b)
	local chars = string.split(s, "")

	if chars[1] ~= "[" or chars[#chars] ~= "]" then
		return err "not cell or atom"
	end

	table.remove(chars, 1)
	table.remove(chars, #chars)

	if #chars == 0 then return err "empty cell" end

	local spacecount = 0
	for _, c in chars do
		if c == " " then
			spacecount += 1
		end
	end

	if spacecount == 0 then return err "1 element in cell" end

	local current = ""
	local ns: { Noun } = {}
	local depth = 0

	for i = 1, #chars do
		local c = chars[i]
		if c == "[" then
			depth += 1
		elseif c == "]" then
			depth -= 1
		end

		if depth == 0 and c == " " then
			local res = stringn(current)
			if res.fail then return res end

			table.insert(ns, res.value)
			current = ""
			continue
		end

		current ..= c
	end

	if depth ~= 0 then return err "unmatched brackets" end

	if current ~= "" then
		local res = stringn(current)
		if res.fail then return res end

		table.insert(ns, res.value)
	end

	if #ns < 2 then return err "not enough elements in cell" end
	if #ns == 2 then return ok(cell(ns[1], ns[2])) end

	local ns1 = ns[1]
	table.remove(ns, 1)

	local sns = {}
	for _, v in ns do
		table.insert(sns, nstring(v))
	end

	local res = stringn(`[{table.concat(sns, " ")}]`)
	if res.fail then return res end

	return ok(cell(ns1, res.value))
end

-- operator functions
-- ?
local function wut(n: Noun): Atom
	print(`?{nstring(n)}`)

	-- ?[a b] -> 0
	if type(n) == "table" then return 0 end

	-- ?a -> 1
	return 1
end

-- +
local function lus(n: Noun): Result
	print(`+{nstring(n)}`)

	-- +a -> 1 + a
	if type(n) == "number" then return ok(1 + n) end

	-- +[a b] -> +[a b]
	return err "+[a b] -> +[a b]"
end

-- =
local function btis(a: Noun, b: Noun): boolean
	if type(a) == "number" and type(b) == "number" and a == b then
		return true
	end

	if type(a) == "table" and type(b) == "table" then
		return btis(a.n1, b.n1) and btis(a.n2, b.n2)
	end

	return false
end

local function tis(a: Noun, b: Noun): Atom
	print(`=[{nstring(a)} {nstring(b)}]`)

	-- =[a a] -> 0
	if btis(a, b) then return 0 end

	-- =[a b] -> 1
	return 1
end

-- /
local function fas(n1: Noun, n2: Noun): Result
	print(`/[{nstring(n1)} {nstring(n2)}]`)

	-- /[1 a] -> a
	if n1 == 1 then
		print "-- /[1 a] -> a"

		local a = n2

		return ok(a)
	end

	-- /[2 a b] -> a
	-- /[2 [a b]] -> a
	if n1 == 2 and type(n2) == "table" then
		print "-- /[2 a b] -> a"

		local a = n2.n1

		return ok(a)
	end

	-- /[3 a b] -> b
	-- /[3 [a b]] -> b
	if n1 == 3 and type(n2) == "table" then
		print "-- /[3 a b] -> b"

		local b = n2.n2

		return ok(b)
	end

	-- /[(a + a) b] -> /[2 /[a b]]
	-- /[(a + a + 1) b] -> /[3 /[a b]]
	if type(n1) == "number" then
		local b = n2

		if n1 == 0 then return err "/[0 a] -> /[2 /[0 a]]" end
		if n1 == 2 and type(b) == "number" then
			return err "/[2 n] -> /[2 /[1 n]] -> /[2 n]"
		end
		if n1 == 3 and type(b) == "number" then
			return err "/[3 n] -> /[3 /[1 n]] -> /[3 n]"
		end

		-- /[(a + a) b] -> /[2 /[a b]]
		if n1 % 2 == 0 then
			print "-- /[(a + a) b] -> /[2 /[a b]]"

			local a = n1 / 2
			print(`== /[{n1} b] -> /[2 /[{a} b]]`)

			local r2 = fas(a, b)
			if r2.fail then return r2 end

			return fas(2, r2.value)
		end

		-- /[(a + a + 1) b] -> /[3 /[a b]]
		if n1 % 2 == 1 then
			print "-- /[(a + a + 1) b] -> /[3 /[a b]]"

			local a = (n1 - 1) / 2
			print(`== /[{n1} b] -> /[3 /[{a} b]]`)

			local r2 = fas(a, b)
			if r2.fail then return r2 end

			return fas(3, r2.value)
		end
	end

	-- /a -> /a
	return err "/a -> /a" -- as far as I can tell this never happens
end

-- Reduce by the first matching pattern; variables match any noun.
-- nock(a) -> *a
local function nock(n1: Noun, n2: Noun): Result
	print(`*[{nstring(n1)} {nstring(n2)}]`)

	-- *[a [b c] d] -> [*[a b c] *[a d]]
	-- *[a [[b c] d]] -> [*[a [b c]] *[a d]]
	if type(n2) == "table" and type(n2.n1) == "table" then
		print "-- *[a [b c] d] -> [*[a b c] *[a d]]"

		local a = n1
		local b = n2.n1.n1
		local c = n2.n1.n2
		local d = n2.n2

		local r1 = nock(a, cell(b, c))
		if r1.fail then return r1 end

		local r2 = nock(a, d)
		if r2.fail then return r2 end

		return ok(cell(r1.value, r2.value))
	end

	-- *[a 0 b] -> /[b a]
	-- *[a [0 b]] -> /[b a]
	if type(n2) == "table" and n2.n1 == 0 then
		print "-- *[a 0 b] -> /[b a]"

		local a = n1
		local b = n2.n2

		return fas(b, a)
	end

	-- *[a 1 b] -> b
	-- *[a [1 b]] -> b
	if type(n2) == "table" and n2.n1 == 1 then
		print "-- *[a 1 b] -> b"

		local b = n2.n2

		return ok(b)
	end

	-- *[a 2 b c] -> *[*[a b] *[a c]]
	-- *[a [2 [b c]]] -> *[*[a b] *[a c]]
	if type(n2) == "table" and n2.n1 == 2 and type(n2.n2) == "table" then
		print "-- *[a 2 b c] -> *[*[a b] *[a c]]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		local r2 = nock(a, c)
		if r2.fail then return r2 end

		return nock(r1.value, r2.value)
	end

	-- *[a 3 b] -> ?*[a b]
	-- *[a [3 b]] -> ?*[a b]
	if type(n2) == "table" and n2.n1 == 3 then
		print "-- *[a 3 b] -> ?*[a b]"

		local a = n1
		local b = n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		return ok(wut(r1.value))
	end

	-- *[a 4 b] -> +*[a b]
	-- *[a [4 b]] -> +*[a b]
	if type(n2) == "table" and n2.n1 == 4 then
		print "-- *[a 4 b] -> +*[a b]"

		local a = n1
		local b = n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		return lus(r1.value)
	end

	-- *[a 5 b c] -> =[*[a b] *[a c]]
	-- *[a [5 [b c]]] -> =[*[a b] *[a c]]
	if type(n2) == "table" and n2.n1 == 5 and type(n2.n2) == "table" then
		print "-- *[a 5 b c] -> =[*[a b] *[a c]]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		local r2 = nock(a, c)
		if r2.fail then return r2 end

		return ok(tis(r1.value, r2.value))
	end

	-- macro time

	-- *[a 6 b c d] -> *[a *[[c d] 0 *[[2 3] 0 *[a 4 4 b]]]]
	-- *[a [6 [b [c d]]]] -> *[a *[[c d] [0 *[[2 3] [0 *[a [4 [4 b]]]]]]]]
	if
		type(n2) == "table"
		and n2.n1 == 6
		and type(n2.n2) == "table"
		and type(n2.n2.n2) == "table"
	then
		print "-- *[a 6 b c d] -> *[a *[[c d] 0 *[[2 3] 0 *[a 4 4 b]]]]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2.n1
		local d = n2.n2.n2.n2

		local r1 = nock(a, cell(4, cell(4, b)))
		if r1.fail then return r1 end

		local r2 = nock(cell(2, 3), cell(0, r1.value))
		if r2.fail then return r2 end

		local r3 = nock(cell(c, d), cell(0, r2.value))
		if r3.fail then return r3 end

		return nock(a, r3.value)
	end

	-- *[a 7 b c] -> *[*[a b] c]
	-- *[a [7 [b c]]] -> *[*[a b] c]
	--
	-- (alternatively *[a 2 b 1 c] -> [*[a b] *[a 1 c]] -> *[*[a b] c])
	if type(n2) == "table" and n2.n1 == 7 and type(n2.n2) == "table" then
		print "-- *[a 7 b c] -> *[*[a b] c]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		return nock(r1.value, c)
	end

	-- *[a 8 b c] -> *[[*[a b] a] c]
	-- *[a [8 [b c]]] -> *[[*[a b] a] c]
	if type(n2) == "table" and n2.n1 == 8 and type(n2.n2) == "table" then
		print "-- *[a 8 b c] -> *[[*[a b] a] c]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2

		local r1 = nock(a, b)
		if r1.fail then return r1 end

		return nock(cell(r1.value, a), c)
	end

	-- *[a 9 b c] -> *[*[a c] 2 [0 1] 0 b]
	-- *[a [9 [b c]]] -> *[*[a c] [2 [[0 1] [0 b]]]]
	-- 
	-- (alternatively *[a 7 c 2 [0 1] 0 b] -> *[*[a c] 2 [0 1] 0 b])
	if type(n2) == "table" and n2.n1 == 8 and type(n2.n2) == "table" then
		print "-- *[a 9 b c] -> *[*[a c] 2 [0 1] 0 b]"

		local a = n1
		local b = n2.n2.n1
		local c = n2.n2.n2

		local r1 = nock(a, c)
		if r1.fail then return r1 end

		return nock(r1.value, cell(2, cell(cell(0, 1), cell(0, b))))
	end

	-- *a -> *a
	return err "*a -> *a"
end

return {
	nstring = nstring,
	stringn = stringn,
	nock = nock,
}
