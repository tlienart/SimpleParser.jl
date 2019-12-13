"""
Pattern{N}

Pattern to find when tokenizing, `N` indicates the number of characters to
capture, `0` indicates a greedy pattern.
"""
struct Pattern{N}
    name::Symbol
    rule::Function
    followed_by::Vector{Char}
    not_followed_by::Vector{Char}
    function Pattern{N}(n, r, fb=Char[], nfb=Char[]) where N
        new{N}(n, r, fb, nfb)
    end
end

"""
nchars(pattern)

Number of characters in the pattern (if the pattern is understood as a Vector
of Char, then it's the length of that vector).
"""
nchars(::Pattern{N}) where N = N

r_empty         = s -> true
r_string(e::AS) = s -> s == e

# exact string Pattern
Pattern(n::Symbol, e::String, a...) = Pattern{length(e)}(n, r_string(e), a...)

"""
gr_isletter(parent, start; extras=Char[], allow_extra_first=false)

Greedy rule matching an uinterrupted sequence of letters also allowing chars
in `extras` as long as they appear after the first char (which must be a
letter). So for instance `a_b` would match provided  `extras=[`_`]` but `_ab`
would not. You can allow this behaviour by passing `allow_extra_first=true`.
"""
function gr_isletter(parent::AS, start::Int;
                     extras=Char[], allow_extra_first::Bool=false)
    nchars, pos = 0, start
    while true
        next = next_char(parent, pos)
        # check conditions
        take_char = !next.eos &&
                    isletter(next.char) ||
                    next.char ∈ extras &&
                    (!iszero(nchars) || allow_extra_first)
        take_char || break
        # increment char counter and position
        nchars += 1
        pos = next.pos
    end
    return nchars
end
