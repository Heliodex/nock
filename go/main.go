// Nock 4K
package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

// An atom is a natural number.
type Atom uint64

func (a Atom) String() string {
	return fmt.Sprintf("%d", a)
}

func atom(a uint64) Noun {
	at := Atom(a)

	return Noun{Atom: &at}
}

// A cell is an ordered pair of nouns.
type Cell [2]Noun

func (c Cell) String() string {
	return fmt.Sprintf("[%s %s]", c[0].String(), c[1].String())
}

func cell(a, b Noun) Noun {
	c := Cell{a, b}

	return Noun{Cell: &c}
}

// A noun is either an atom or a cell.
type Noun struct {
	Atom *Atom
	Cell *Cell
}

func (n Noun) String() string {
	if n.Atom != nil {
		return n.Atom.String()
	} else if n.Cell != nil {
		return n.Cell.String()
	}
	return "nil"
}

// [a b c] -> [a [b c]]

func stringcell(chars []byte) (Noun, error) {
	var current []byte
	var ns []Noun
	var depth int

	for _, c := range chars {
		if c == '[' {
			depth++
		} else if c == ']' {
			depth--
		}

		if depth != 0 || c != ' ' {
			// current.WriteByte(c
			current = append(current, c)
			continue
		}

		res, err := stringn(string(current))
		if err != nil {
			return Noun{}, err
		}

		ns = append(ns, res)
		current = nil
	}

	if depth != 0 {
		return Noun{}, errors.New("unmatched brackets")
	}

	if len(current) != 0 {
		res, err := stringn(string(current))
		if err != nil {
			return Noun{}, err
		}

		ns = append(ns, res)
	}

	if len(ns) < 2 {
		return Noun{}, errors.New("1 element in cell")
	}

	if len(ns) == 2 {
		return cell(ns[0], ns[1]), nil
	}

	ns1, ns := ns[0], ns[1:]

	sns := make([]string, len(ns))
	for i, n := range ns {
		sns[i] = n.String()
	}

	res, err := stringcell([]byte(strings.Join(sns, " ")))
	if err != nil {
		return Noun{}, err
	}

	return cell(ns1, res), nil
}

func stringn(s string) (Noun, error) {
	// check if s is a number

	if n, err := strconv.ParseUint(s, 10, 64); err == nil {
		return atom(n), nil
	}

	// [a b] -> cell(a, b)
	if s[0] != '[' || s[len(s)-1] != ']' {
		return Noun{}, errors.New("not cell or atom")
	}

	if len(s) == 2 {
		return Noun{}, errors.New("empty cell")
	}

	chars := []byte(s[1 : len(s)-1])

	var spacecount int
	for _, c := range chars {
		if c == ' ' {
			spacecount++
		}
	}

	if spacecount == 0 {
		return Noun{}, errors.New("1 element in cell")
	}

	return stringcell(chars)
}

// operator functions
// ?
func wut(n Noun) Noun {
	fmt.Printf("?%s\n", n)

	// ?[a b] -> 0
	if n.Cell != nil {
		return atom(0)
	}

	// ?a -> 1
	return atom(1)
}

// +
func lus(n Noun) (Noun, error) {
	fmt.Printf("+%s\n", n)

	// +a -> 1 + a
	if n.Atom != nil {
		return atom(1 + uint64(*n.Atom)), nil
	}

	// +[a b] -> +[a b]
	return Noun{}, errors.New("+[a b] -> +[a b]")
}

// =
func btis(a, b Noun) bool {
	if a.Atom != nil && b.Atom != nil {
		return true
	}

	if a.Cell != nil && b.Cell != nil {
		return btis(a.Cell[0], b.Cell[0]) && btis(a.Cell[1], b.Cell[1])
	}

	return false
}

func tis(a, b Noun) Noun {
	fmt.Printf("=[%s %s]\n", a, b)

	// =[a a] -> 0
	if btis(a, b) {
		return atom(0)
	}

	// =[a b] -> 1
	return atom(1)
}

// /
func fas(n1, n2 Noun) (Noun, error) {
	fmt.Printf("/[%s %s]\n", n1, n2)

	// /[1 a] -> a
	if n1.Atom != nil && *n1.Atom == 1 {
		fmt.Println("-- /[1 a] -> a")

		return n2, nil
	}

	// /[2 a b] -> a
	// /[2 [a b]] -> a
	if n1.Atom != nil && *n1.Atom == 2 && n2.Cell != nil {
		fmt.Println("-- /[2 a b] -> a")

		return n2.Cell[0], nil
	}

	// /[3 a b] -> b
	// /[3 [a b]] -> b
	if n1.Atom != nil && *n1.Atom == 3 && n2.Cell != nil {
		fmt.Println("-- /[3 a b] -> b")

		return n2.Cell[1], nil
	}

	// /[(a + a) b] -> /[2 /[a b]]
	// /[(a + a + 1) b] -> /[3 /[a b]]
	if n1.Atom != nil {
		n1a := *n1.Atom

		if n1a == 0 {
			return Noun{}, errors.New("/[0 a] -> /[2 /[0 a]]")
		}

		if n1a == 2 {
			return Noun{}, errors.New("/[2 a] -> /[2 /[1 a]] -> /[2 a]")
		}

		if n1a == 3 {
			return Noun{}, errors.New("/[3 a] -> /[3 /[1 a]] -> /[3 a]")
		}

		// /[(a + a) b] -> /[2 /[a b]]
		if n1a%2 == 0 {
			fmt.Println("-- /[(a + a) b] -> /[2 /[a b]]")

			r2, err := fas(atom(uint64(n1a)/2), n2)
			if err != nil {
				return Noun{}, err
			}

			return fas(atom(2), r2)
		}

		// /[(a + a + 1) b] -> /[3 /[a b]]
		fmt.Println("-- /[(a + a + 1) b] -> /[3 /[a b]]")

		r2, err := fas(atom(uint64(n1a-1)/2), n2)
		if err != nil {
			return Noun{}, err
		}

		return fas(atom(3), r2)
	}

	// /a -> /a
	return Noun{}, errors.New("/a -> /a")
}

func main() {
	fmt.Println(
		Cell{atom(1), atom(2)},
	)

	n, err := stringn("[1 2 3]")
	if err != nil {
		panic(err)
	}

	fmt.Println(n)
}
