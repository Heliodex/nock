-- PLAN

-- Every PLAN value is either a pin x:<i>,
type Pin<I> = { tag: "pin", i: I }
local function pin<I>(i: I): Pin<I> return { tag = "pin", i = i } end
-- a law x:{n a b},
type Law<N, A, B> = { tag: "law", n: N, a: A, b: B }
local function law<N, A, B>(n: N, a: A, b: B): Law<N, A, B>
	return { tag = "law", n = n, a = a, b = b }
end
-- an app x:(f g),
-- Apps are left-heavy, (f a b c) = (((f a) b) c)
type App<F, G> = { tag: "app", f: F, g: G }
local function app<F, G>(f: F, g: G): App<F, G>
	return { tag = "app", f = f, g = g }
end
-- a nat x:@,
type Nat = { tag: "nat", _: number }
local function nat(n: number): Nat return { tag = "nat", _ = n } end
local function inc(n: Nat): Nat return nat(n._ + 1) end
local function dec(n: Nat): Nat return nat(n._ - 1) end
-- or a black hole x:<>.
type BlackHole = { tag: "blackhole" }
local function blackhole(): BlackHole return { tag = "blackhole" } end

type PLAN = Pin<PLAN> | Law<PLAN, PLAN, PLAN> | App<PLAN, PLAN> | Nat | BlackHole

-- Black holes only exist during evaluation.

-- (o <- x) mutates o in place, updating its value to equal x.
-- Unmatched patterns diverge.
-- Run F[x] to normalize a value, to "evaluate".

local B, E, F, P, N, A, L, W

-- C (reCursion on naturals)
local function C(z: PLAN, p: PLAN, n: PLAN): PLAN
	-- C[z,p,n] = if n=0 then z else p (n-1)
	if n.tag == "nat" and n._ == 0 then return z end

	error "?"
end

-- S (Saturate)
local function S(o: PLAN): PLAN
	-- S[o:(f x y)]       = (S[(f x)] y)
	if o.tag == "app" and o.f.tag == "app" then
		local to: App<App<PLAN, PLAN>, PLAN> = o

		local f = to.f.f
		local x = to.f.g
		local y = to.g

		return app(S(app(f, x)), y)
	end
	-- S[o:(<{n a b}> y)] = o
	if o.tag == "app" and o.f.tag == "pin" and o.f.i.tag == "law" then
		return o
	end
	-- S[o:(<f> x)]       = S[(f x)]
	if o.tag == "app" and o.f.tag == "pin" then
		local to: App<Pin<PLAN>, PLAN> = o

		local f = to.f.i
		local x = to.g

		return S(app(f, x))
	end
	-- S[o]               = o
	return o
end

-- I (index
local function I(f: PLAN, e: PLAN, n: PLAN): PLAN
	-- I(f, (e x), 0) = x
	if e.tag == "app" and n.tag == "nat" and n._ == 0 then
		local te: App<PLAN, PLAN> = e

		local x = te.g

		return x
	end
	-- I(f, e,     0) = e
	if n.tag == "nat" and n._ == 0 then return e end
	-- I(f, (e x), n) = I(f, e, n-1)
	if e.tag == "app" then
		local te: App<PLAN, PLAN> = e

		local x = te.g

		return I(f, x, nat(N(n)._ - 1))
	end
	-- I(f, e,     n) = f
	return f
end

-- R (Run a law)
local function R(n: PLAN, e: PLAN, a: PLAN): PLAN
	-- 	R(n,e,b:@) | b≤n = I(b,e,(n-b))         # if b=0 Self, otherwise Var b
	if a.tag == "nat" and N(a)._ <= n._ then
		return I(a, e, nat(N(n)._ - a._))
	end
	-- R(n,e,(0 f x))   = (R(n,e,f) R(n,e,x))  # Apply f x
	if
		a.tag == "app"
		and a.f.tag == "app"
		and a.f.f.tag == "nat"
		and a.f.f._ == 0
	then
		local ta: App<App<PLAN, PLAN>, PLAN> = a

		local f = ta.f.g
		local x = ta.g

		return app(R(n, e, f), R(n, e, x))
	end
	-- R(n,e,(1 v b))   = L(n,e,v,b)           # let v in b
	if
		a.tag == "app"
		and a.f.tag == "app"
		and a.f.f.tag == "nat"
		and a.f.f._ == 1
	then
		local ta: App<App<PLAN, PLAN>, PLAN> = a

		local v = ta.f.g
		local b = ta.g

		return L(n, e, v, b)
	end
	-- R(n,e,(2 x))     = x                    # Literal x
	if a.tag == "app" and a.f.tag == "nat" and a.f._ == 2 then
		local ta: App<Nat, PLAN> = a

		local x = ta.g

		return x
	end
	-- R(n,e,x)         = x                    # Literal x (fallback, incl b>n)
	return a
end

-- X (function eXecution)
local function X(f: PLAN, e: PLAN): PLAN
	-- X[0, (_ n a b)]     = W[N[n],N[a],F[b]]
	if
		f.tag == "nat"
		and f._ == 0
		and e.tag == "app"
		and e.f.tag == "app"
		and e.f.f.tag == "app"
	then
		local te: App<App<App<PLAN, PLAN>, PLAN>, PLAN> = e

		local n = te.f.f.g
		local a = te.f.g
		local b = te.g

		return W(N(n), N(a), F(b))
	end
	-- X[1, (_ p l a n x)] = P[p,l,a,n,E[x]]
	if
		f.tag == "nat"
		and f._ == 1
		and e.tag == "app"
		and e.f.tag == "app"
		and e.f.f.tag == "app"
		and e.f.f.f.tag == "app"
		and e.f.f.f.f.tag == "app"
	then
		local te: App<App<App<App<App<PLAN, PLAN>, PLAN>, PLAN>, PLAN>, PLAN> =
			e

		local p = te.f.f.f.f.g
		local l = te.f.f.f.g
		local a = te.f.f.g
		local n = te.f.g
		local x = te.g

		return P(p, l, a, n, E(x))
	end
	-- X[2, (_ z p x)]     = C[z,p,N[x]]
	if
		f.tag == "nat"
		and f._ == 2
		and e.tag == "app"
		and e.f.tag == "app"
		and e.f.f.tag == "app"
	then
		local te: App<App<App<PLAN, PLAN>, PLAN>, PLAN> = e

		local z = te.f.f.g
		local p = te.f.g
		local x = te.g

		return C(z, p, N(x))
	end
	-- X[3, (_ x)]         = N[x]+1
	if f.tag == "nat" and f._ == 3 and e.tag == "app" then
		local te: App<PLAN, PLAN> = e

		local x = te.g

		return inc(N(x))
	end
	-- X[4, (_ x)]         = <F[x]>
	if f.tag == "nat" and f._ == 4 and e.tag == "app" then
		local te: App<PLAN, PLAN> = e

		local x = te.g

		return pin(F(x))
	end
	-- X[(f x), e]         = X[f,e]
	if f.tag == "app" then
		local te: App<PLAN, PLAN> = f

		local ff = te.f

		return X(ff, e)
	end
	-- X[<p>, e]           = X[p,e]
	if f.tag == "pin" then
		local te: Pin<PLAN> = f

		local p = te.i

		return X(p, e)
	end
	-- X[{n a b}, e]       = B[a,a,e,b,b]
	if f.tag == "law" then
		local te: Law<PLAN, PLAN, PLAN> = f

		local a = te.a
		local b = te.b

		return B(a, a, e, b, b)
	end

	error(`unmatched pattern in X: {f} {e}`)
end

-- B (Build law environment)
function B(a: PLAN, n: PLAN, e: PLAN, b: PLAN, x: PLAN): PLAN
	-- B[a,n,e,b,(1 _ k)] = B[a,n+1,(e <>),b,k]
	if
		x.tag == "app"
		and x.f.tag == "app"
		and x.f.f.tag == "nat"
		and x.f.f._ == 1
	then
		local tx: App<App<PLAN, PLAN>, PLAN> = x

		local k = tx.g

		return B(a, inc(N(n)), app(e, blackhole()), b, k)
	end
	-- B[a,n,e,b,x]       = L[a,n,e,b]
	return L(a, n, e, b)
end

-- E (Evaluate)
function E(o: PLAN): PLAN
	-- 	E(o:@)     = o
	if o.tag == "nat" then return o end
	-- E(o:<x>)   = o
	if o.tag == "pin" then return o end
	-- E(o:(f x)) =
	--    E(f)
	--    when A(f)=1
	--        o <- X(o,o)
	--        E(o)
	--    o
	if o.tag == "app" then
		local to: App<PLAN, PLAN> = o

		local f = to.f

		E(f)

		local af = A(f)
		if af.tag == "nat" and af._ == 1 then
			o = X(o, o)
			E(o)
		end

		return o
	end
	-- E(o:{n a b}) =
	--     if a!=0 then o else
	--        o <- <>
	--        o <- R(0,o,b)
	--        E(o)
	if o.tag == "law" then
		local to: Law<PLAN, PLAN, PLAN> = o

		local a = to.a
		local b = to.b

		if a.tag ~= "nat" or a._ ~= 0 then return o end
		o = blackhole()
		o = R(nat(0), o, b)
		return E(o)
	end

	error(`unmatched pattern in E: {o}`)
end

-- F (Force normalize)
function F(o: PLAN): PLAN
	-- F(o) =
	--     E(o)
	--     when o:(f x)
	--          F(f); F(x)
	--     o
	E(o)

	if o.tag == "app" then
		local to: App<PLAN, PLAN> = o

		local f = to.f
		local x = to.g

		F(f)
		F(x)
	end

	return o
end

-- P (Pattern match)
function P(p: PLAN, l: PLAN, a: PLAN, n: PLAN, x: PLAN): PLAN
	-- P(p,l,a,n,(f x))   = (a f x)
	if x.tag == "app" then
		local tx: App<PLAN, PLAN> = x

		local xf = tx.f
		local xx = tx.g

		return app(app(a, xf), xx)
	end
	-- P(p,l,a,n,<x>)     = (p x)
	if x.tag == "pin" then
		local tx: Pin<PLAN> = x

		local xi = tx.i

		return app(p, xi)
	end
	-- P(p,l,a,n,{n a b}) = (l n a b)
	if x.tag == "law" then
		local tx: Law<PLAN, PLAN, PLAN> = x

		local xn = tx.n
		local xa = tx.a
		local xb = tx.b

		return app(app(app(l, xn), xa), xb)
	end
	-- P(p,l,a,n,x:@}     = (n x)
	if x.tag == "nat" then return app(n, x) end

	error(`unmatched pattern in P: {p} {l} {a} {n} {x}`)
end

-- N (cast to Nat)
function N(o: PLAN): Nat
	-- N(o) = E(o); if o:@ then o else 0
	E(o)

	if o.tag == "nat" then return o end
	return nat(0)
end

-- A (Arity)
function A(f: PLAN): PLAN
	-- A((f x))     = A(f)-1
	if f.tag == "app" then
		local tf: App<PLAN, PLAN> = f

		local ff = tf.f

		return dec(N(A(ff)))
	end
	-- A(<p>)       = A(p)
	if f.tag == "pin" then
		local tf: Pin<PLAN> = f

		local p = tf.i

		return A(p)
	end
	-- A({n a b})   = a
	if f.tag == "law" then
		local tf: Law<PLAN, PLAN, PLAN> = f

		local a = tf.a

		return a
	end
	-- A(n:@)       = I(1, (3 5 3), n)
	if f.tag == "nat" then
		return I(nat(1), app(app(nat(3), nat(5)), nat(3)), f)
	end

	error(`unmatched pattern in A: {f}`)
end

-- L (Let-binding)
function L(n: PLAN, e: PLAN, v: PLAN, b: PLAN): PLAN
	-- L(n,e,v,b) =
	--     x := <>
	--     f := (e x)
	--     x <- R(n+1,f,v)
	--     R(n+1,f,b)
	local x = blackhole()
	local n1 = inc(N(n))
	local f = app(e, x)
	x = R(n1, f, v)
	return R(n1, f, b)
end

-- W (Write law)
function W(n: PLAN, a: PLAN, b: PLAN): PLAN
	-- W[n,a,b] | n>0 = {n,a,b}
	if N(n)._ <= 0 then error "n must be greater than 0 in W[n,a,b]" end
	return law(n, a, b)
end
