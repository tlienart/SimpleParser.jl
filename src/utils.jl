"""
next_char(parent, cur_pos)

Given a parent string `parent` and a current valid string index `cur_pos`
(or 0), return the next symbol and its position provided we're not at
the end of the string (EOS).
A named tuple is returned with fields
* `symbol`: next symbol (`\0` if EOS).
* `pos`:    valid index for the position of the symbol (or 0 at EOS).
* `eos`:    boolean indicating whether it's the EOS.
"""
function next_char(parent::AS, cur_pos::Int)
    next_pos = nextind(parent, cur_pos)
    if next_pos <= lastindex(parent)
        return (char=parent[next_pos], pos=next_pos, eos=false)
    end
    # end of string reached
    return (char=EOS, pos=0, eos=true)
end


"""
str(s)

Return the string corresponding to `s`: `s` itself if it is a string, or the
parent string if `s` is a substring. Do not confuse with `String(s::SubString)` which casts `s` into its own object.

# Example

```julia-repl
julia> a = SubString("hello JuDoc", 3:8);
julia> JuDoc.str(a)
"hello JuDoc"
julia> String(a)
"llo Ju"
```
"""
str(s::String)::String    = s
str(s::SubString)::String = s.string


"""
subs(s, from, to)
subs(s, from)
subs(s, range)
subs(s)

Convenience functions to take a substring of a string.

# Example
```julia-repl
julia> JuDoc.subs("hello", 2:4)
"ell"
```
"""
subs(s::AS, from::Int, to::Int)::SubString    = SubString(s, from, to)
subs(s::AS, from::Int)::SubString             = subs(s, from, from)
subs(s::AS, range::UnitRange{Int})::SubString = SubString(s, range)
subs(s::AS) = SubString(s)
