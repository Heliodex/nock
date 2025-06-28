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
type Nat = { tag: "nat", n: number }
local function nat(n: number): Nat return { tag = "nat", n = n } end
-- or a black hole x:<>.
type BlackHole = { tag: "blackhole" }
local function blackhole(): BlackHole return { tag = "blackhole" } end

type PLAN = Pin<PLAN> | Law<PLAN, PLAN, PLAN> | App<PLAN, PLAN> | Nat | BlackHole

-- Black holes only exist during evaluation.

-- (o <- x) mutates o in place, updating its value to equal x.
-- Unmatched patterns diverge.
-- Run F[x] to normalize a value, to "evaluate".

-- X (function eXecution)
local function X(f: PLAN, e: PLAN): PLAN
	-- X[0, (_ n a b)]     = W[N[n],N[a],F[b]]
	if
		f.tag == "nat"
		and f.n == 0
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
		and f.n == 1
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
		and f.n == 2
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
	if f.tag == "nat" and f.n == 3 and e.tag == "app" then
		local te: App<PLAN, PLAN> = e

		local x = te.g

		return nat(N(x).n + 1)
	end
	-- X[4, (_ x)]         = <F[x]>
	if f.tag == "nat" and f.n == 4 and e.tag == "app" then
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
local function B(a: PLAN, n: PLAN, e: PLAN, b: PLAN, x: PLAN): PLAN
	-- B[a,n,e,b,(1 _ k)] = B[a,n+1,(e <>),b,k]
	if
		x.tag == "app"
		and x.f.tag == "app"
		and x.f.f.tag == "nat"
		and x.f.f.n == 1
	then
		local tx: App<App<PLAN, PLAN>, PLAN> = x

		local k = tx.g

		return B(a, nat(n.n + 1), app(e, blackhole()), b, k)
	end
	-- B[a,n,e,b,x]       = L[a,n,e,b]
	return L(a, n, e, b)
end

-- R (Run a law)
