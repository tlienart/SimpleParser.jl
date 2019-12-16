"""
context(parent, position)

Return an informative message of the context of a position and where the
position is, this is useful when throwing error messages.
"""
function context(par::AS, pos::Int)
    # context string
    lidx = lastindex(par)
    if pos > 20
        head = max(1, prevind(par, pos-20))
    else
        head = 1
    end
    if pos <= lidx-20
        tail = min(lidx, nextind(par, pos+20))
    else
        tail = lidx
    end
    prepend  = ifelse(head > 1, "...", "")
    postpend = ifelse(tail < lidx, "...", "")

    ctxt = prepend * subs(par, head, tail) * postpend

    # line number
    lines  = split(par, "\n", keepempty=false)
    nlines = length(lines)
    ranges = zeros(Int, nlines, 2)
    cs = 0
    for (i, l) in enumerate(lines[1:end-1])
        tmp = [nextind(par, cs), nextind(par, lastindex(l) + cs)]
        ranges[i, :] .= tmp
        cs = tmp[2]
    end
    ranges[end, :] = [nextind(par, cs), lidx]

    lno = findfirst(i -> ranges[i,1] <= pos <= ranges[i,2], 1:nlines)

    # Assemble to form a message
    mess = """
    Context:
    \t$(strip(ctxt)) (near line $lno)
    \t$(" "^(pos-head+length(prepend)))^---
    """
    return mess
end
