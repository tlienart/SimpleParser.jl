struct Token
    name::Symbol
    ss::SubString
end

function tokenize(s::AbstractString, d::Dict{Char,Vector{Pattern}})
    eosidx = lastindex(s)
    pos    = 0
    tokens = Token[]
    next::Union{Nothing,NamedTuple} = next_char(s, pos)
    while true
        # if EOS, break
        next.eos && break
        # otherwise update position and check
        # if there are patterns starting with that char
        pos = next.pos
        if next.char in keys(d)
            pos = check_patterns!(tokens, d[next.char], s, pos, eosidx)
        end
        next = next_char(s, pos)
    end
    return tokens
end

function check_patterns!(tokens::Vector{Token}, pats::Vector{Pattern},
                         s::AS, pos::Int, eosidx::Int)
    # check against pattern, in order, first match wins
    for pat in pats

        n = nchars(pat)
        # fixed length pattern
        if n > 0
            tail = nextind(s, pos, n-1)
            # check tail is still in the text
            tail <= eosidx || continue
            # retrieve candidate
            cand = subs(s, pos, tail)
            # check match
            if pat.rule(cand)
                # there may be additional "is_followed" or
                # "is_not_followed" rule
                if !isempty(pat.followed_by) || !isempty(pat.not_followed_by)
                    next = next_char(s, tail)
                    cond = (isempty(pat.followed_by) ||
                            next.char ∈ pat.followed_by) &&
                           (isempty(pat.not_followed_by) ||
                            next.char ∉ pat.not_followed_by)
                    cond || continue
                end
                push!(tokens, Token(pat.name, cand))
                pos = tail
                break
            end
        # greedy pattern
        else
            n = pat.rule(s, pos)
            if n > 0
                tail = nextind(s, pos, n)
                cand = subs(s, pos, tail)
                push!(tokens, Token(pat.name, cand))
                pos = tail
                break
            end
        end
    end
    return pos
end
