-- Nock 4K

local debug = false

local function dprint(...: string)
	if debug then print(...) end
end

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

	if #chars == 2 then return err "empty cell" end

	table.remove(chars, 1)
	table.remove(chars, #chars)

	local spacecount = 0
	for _, c in chars do
		if c == " " then
			spacecount += 1
		end
	end

	if spacecount == 0 then return err "1 element in cell" end

	local current = {}
	local ns: { Noun } = {}
	local depth = 0

	for i = 1, #chars do
		local c = chars[i]
		if c == "[" then
			depth += 1
		elseif c == "]" then
			depth -= 1
		end

		if depth ~= 0 or c ~= " " then
			table.insert(current, c)
			continue
		end

		local res = stringn(table.concat(current, ""))
		if res.fail then return res end

		table.insert(ns, res.value)
		current = {}
	end

	if depth ~= 0 then return err "unmatched brackets" end

	if #current ~= 0 then
		local res = stringn(table.concat(current, ""))
		if res.fail then return res end

		table.insert(ns, res.value)
	end

	if #ns < 2 then return err "not enough elements in cell" end
	if #ns == 2 then return ok(cell(ns[1], ns[2])) end

	local ns1 = ns[1]
	table.remove(ns, 1)

	local sns: { string } = table.create(#ns, "")
	for i, v in ns do
		sns[i] = nstring(v)
	end

	local res = stringn(`[{table.concat(sns, " ")}]`)
	if res.fail then return res end

	return ok(cell(ns1, res.value))
end

-- operator functions
-- ?
local function wut(n: Noun): Atom
	-- dprint(`?{nstring(n)}`)

	-- ?[a b] -> 0
	if type(n) == "table" then return 0 end

	-- ?a -> 1
	return 1
end

-- +
local function lus(n: Noun): Result
	-- dprint(`+{nstring(n)}`)
	-- error "waht"

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
	-- dprint(`=[{nstring(a)} {nstring(b)}]`)

	-- =[a a] -> 0
	if btis(a, b) then return 0 end

	-- =[a b] -> 1
	return 1
end

-- /
local function fas(n1: Noun, n2: Noun): Result
	-- dprint(`/[{nstring(n1)} {nstring(n2)}]`)

	-- /[1 a] -> a
	if n1 == 1 then
		dprint "-- /[1 a] -> a"

		return ok(n2)
	end

	-- /[2 a b] -> a
	-- /[2 [a b]] -> a
	if n1 == 2 and type(n2) == "table" then
		dprint "-- /[2 a b] -> a"

		return ok(n2.n1)
	end

	-- /[3 a b] -> b
	-- /[3 [a b]] -> b
	if n1 == 3 and type(n2) == "table" then
		dprint "-- /[3 a b] -> b"

		return ok(n2.n2)
	end

	-- /[(a + a) b] -> /[2 /[a b]]
	-- /[(a + a + 1) b] -> /[3 /[a b]]
	if type(n1) == "number" then
		if n1 == 0 then return err "/[0 a] -> /[2 /[0 a]]" end
		if n1 == 2 and type(n2) == "number" then
			return err "/[2 n] -> /[2 /[1 n]] -> /[2 n]"
		end
		if n1 == 3 and type(n2) == "number" then
			return err "/[3 n] -> /[3 /[1 n]] -> /[3 n]"
		end

		-- /[(a + a) b] -> /[2 /[a b]]
		if n1 % 2 == 0 then
			dprint "-- /[(a + a) b] -> /[2 /[a b]]"

			local r2 = fas(n1 / 2, n2)
			if r2.fail then return r2 end

			return fas(2, r2.value)

		-- /[(a + a + 1) b] -> /[3 /[a b]]
		else
			dprint "-- /[(a + a + 1) b] -> /[3 /[a b]]"

			local r2 = fas((n1 - 1) / 2, n2)
			if r2.fail then return r2 end

			return fas(3, r2.value)
		end
	end

	-- /a -> /a
	return err "/a -> /a"
end

local function hax(n1: Noun, n2: Noun, n3: Noun): Result
	-- #[1 a b] -> a
	if n1 == 1 then
		dprint "-- #[1 a b] -> a"

		local a = n2

		return ok(a)
	end

	local b = n2
	local c = n3

	if type(n1) ~= "number" then
		-- #a -> #a
		return err "#a -> #a"
	end

	-- #[(a + a) b c] -> #[a [b /[(a + a + 1) c]] c]
	if n1 % 2 == 0 then
		dprint "-- #[(a + a) b c] -> #[a [b /[(a + a + 1) c]] c]"

		local a = n1 / 2

		local r2 = fas(a + a + 1, c)
		if r2.fail then return r2 end

		return hax(a, cell(r2.value, b), c)
	end
	
	-- #[(a + a + 1) b c] -> #[a [/[(a + a) c] b] c]
	dprint "-- #[(a + a + 1) b c] -> #[a [/[(a + a) c] b] c]"

	local a = (n1 - 1) / 2

	local r2 = fas(a + a, c)
	if r2.fail then return r2 end

	return hax(a, cell(b, r2.value), c)
end

-- Reduce by the first matching pattern; variables match any noun.
-- nock(a) -> *a
local function nock(s: Noun, f: Noun): Result
	-- dprint(`*[{nstring(n1)} {nstring(n2)}]`)

	if type(f) ~= "table" then return err "*a -> *a" end

	-- *[a [b c] d] -> [*[a b c] *[a d]]
	-- *[a [[b c] d]] -> [*[a [b c]] *[a d]]
	if type(f.n1) == "table" then
		dprint "-- *[a [b c] d] -> [*[a b c] *[a d]]"

		local r1 = nock(s, cell(f.n1.n1, f.n1.n2))
		if r1.fail then return r1 end

		local r2 = nock(s, f.n2)
		if r2.fail then return r2 end

		return ok(cell(r1.value, r2.value))
	end

	local op = f.n1

	-- *[a 0 b] -> /[b a]
	-- *[a [0 b]] -> /[b a]
	if op == 0 then
		dprint "-- *[a 0 b] -> /[b a]"

		return fas(f.n2, s)
	end

	-- *[a 1 b] -> b
	-- *[a [1 b]] -> b
	if op == 1 then
		dprint "-- *[a 1 b] -> b"

		return ok(f.n2)
	end

	-- *[a 2 b c] -> *[*[a b] *[a c]]
	-- *[a [2 [b c]]] -> *[*[a b] *[a c]]
	if op == 2 and type(f.n2) == "table" then
		dprint "-- *[a 2 b c] -> *[*[a b] *[a c]]"

		local r1 = nock(s, f.n2.n1)
		if r1.fail then return r1 end

		local r2 = nock(s, f.n2.n2)
		if r2.fail then return r2 end

		return nock(r1.value, r2.value)
	end

	-- *[a 3 b] -> ?*[a b]
	-- *[a [3 b]] -> ?*[a b]
	if op == 3 then
		dprint "-- *[a 3 b] -> ?*[a b]"

		local r1 = nock(s, f.n2)
		if r1.fail then return r1 end

		return ok(wut(r1.value))
	end

	-- *[a 4 b] -> +*[a b]
	-- *[a [4 b]] -> +*[a b]
	if op == 4 then
		dprint "-- *[a 4 b] -> +*[a b]"

		local r1 = nock(s, f.n2)
		if r1.fail then return r1 end

		return lus(r1.value)
	end

	-- *[a 5 b c] -> =[*[a b] *[a c]]
	-- *[a [5 [b c]]] -> =[*[a b] *[a c]]
	if op == 5 and type(f.n2) == "table" then
		dprint "-- *[a 5 b c] -> =[*[a b] *[a c]]"

		local r1 = nock(s, f.n2.n1)
		if r1.fail then return r1 end

		local r2 = nock(s, f.n2.n2)
		if r2.fail then return r2 end

		return ok(tis(r1.value, r2.value))
	end

	-- macro time

	-- *[a 6 b c d] -> *[a *[[c d] 0 *[[2 3] 0 *[a 4 4 b]]]]
	-- *[a [6 [b [c d]]]] -> *[a *[[c d] [0 *[[2 3] [0 *[a [4 [4 b]]]]]]]]
	if op == 6 and type(f.n2) == "table" and type(f.n2.n2) == "table" then
		dprint "-- *[a 6 b c d] -> *[a *[[c d] 0 *[[2 3] 0 *[a 4 4 b]]]]"

		local r1 = nock(s, cell(4, cell(4, f.n2.n1)))
		if r1.fail then return r1 end

		local r2 = nock(cell(2, 3), cell(0, r1.value))
		if r2.fail then return r2 end

		local r3 = nock(cell(f.n2.n2.n1, f.n2.n2.n2), cell(0, r2.value))
		if r3.fail then return r3 end

		return nock(s, r3.value)
	end

	-- *[a 7 b c] -> *[*[a b] c]
	-- *[a [7 [b c]]] -> *[*[a b] c]
	--
	-- (alternatively *[a 2 b 1 c] -> [*[a b] *[a 1 c]] -> *[*[a b] c])
	if op == 7 and type(f.n2) == "table" then
		dprint "-- *[a 7 b c] -> *[*[a b] c]"

		local r1 = nock(s, f.n2.n1)
		if r1.fail then return r1 end

		return nock(r1.value, f.n2.n2)
	end

	-- *[a 8 b c] -> *[[*[a b] a] c]
	-- *[a [8 [b c]]] -> *[[*[a b] a] c]
	if op == 8 and type(f.n2) == "table" then
		dprint "-- *[a 8 b c] -> *[[*[a b] a] c]"

		local r1 = nock(s, f.n2.n1)
		if r1.fail then return r1 end

		return nock(cell(r1.value, s), f.n2.n2)
	end

	-- *[a 9 b c] -> *[*[a c] 2 [0 1] 0 b]
	-- *[a [9 [b c]]] -> *[*[a c] [2 [[0 1] [0 b]]]]
	--
	-- (alternatively *[a 7 c 2 [0 1] 0 b] -> *[*[a c] 2 [0 1] 0 b])
	if op == 9 and type(f.n2) == "table" then
		dprint "-- *[a 9 b c] -> *[*[a c] 2 [0 1] 0 b]"

		local r1 = nock(s, f.n2.n2)
		if r1.fail then return r1 end

		return nock(r1.value, cell(2, cell(cell(0, 1), cell(0, f.n2.n1))))
	end

	-- *[a 10 [b c] d] -> #[b *[a c] *[a d]]
	-- *[a [10 [[b c] d]]] -> #[b [*[a c] *[a d]]]
	if op == 10 and type(f.n2) == "table" and type(f.n2.n1) == "table" then
		dprint "-- *[a 10 [b c] d] -> #[b *[a c] *[a d]]"

		local r1 = nock(s, f.n2.n1.n2)
		if r1.fail then return r1 end

		local r2 = nock(s, f.n2.n2)
		if r2.fail then return r2 end

		return hax(f.n2.n1.n1, r1.value, r2.value)
	end

	-- *[a 11 [b c] d] -> *[[*[a c] *[a d]] 0 3]
	-- *[a [11 [[b c] d]]] -> *[[*[a c] *[a d]] [0 3]]
	if op == 11 and type(f.n2) == "table" and type(f.n2.n1) == "table" then
		dprint "-- *[a 11 [b c] d] -> *[[*[a c] *[a d]] 0 3]"

		local r1 = nock(s, f.n2.n1.n2)
		if r1.fail then return r1 end

		local r2 = nock(s, f.n2.n2)
		if r2.fail then return r2 end

		return nock(cell(r1.value, r2.value), cell(0, 3))
	end

	-- *[a 11 b c] -> *[a c]
	-- *[a [11 [b c]]] -> *[a c]
	if op == 11 and type(f.n2) == "table" then
		dprint "-- *[a 11 b c] -> *[a c]"

		return nock(s, f.n2.n2)
	end

	-- *a -> *a
	return err "*a -> *a"
end

return {
	nstring = nstring,
	stringn = stringn,
	nock = nock,
}
