function err_block_unclosed(t::Token, bp::BlockPattern)
    msg = "Found opening token $(t.name) but not a matching " *
          "closing token (expected one of $(bp.cname))"
    throw(BlockError(msg, context(t)))
end

function find_singleblocks!(tokens::Vector{Token}, singles::Vector{Symbol}
                            )::Vector{Block}
    (isempty(tokens) || isempty(singles)) && return Block[]
    blocks   = Vector{Block}()
    inactive = zeros(Bool, length(tokens))
    for (i, t) in enumerate(tokens)
        t.name ∈ singles || continue
        push!(blocks, Block(t))
        inactive[i] = true
    end
    deleteat!(tokens, inactive)
    return blocks
end

function find_pairblocks!(tokens::Vector{Token}, bp::Vector{BlockPattern}
                          )::Vector{Block}
    (isempty(tokens) || isempty(bp)) && return Block[]
    ntokens  = length(tokens)
    inactive = zeros(Bool, ntokens)
    blocks   = Vector{Block}()
    for pat in bp
        for i in 1:ntokens
            inactive[i] && continue
            otok = tokens[i]
            otok.name == pat.oname || continue

            # look ahead for closing token either caring about
            # balance or not
            if pat.balance
                inbalance = 1
                j = i
                while (j < ntokens) && !iszero(inbalance)
                    j   += 1
                    cand = tokens[j]
                    inbalance += ifelse(cand.name == pat.oname, 1, 0)
                    inbalance -= ifelse(cand.name  ∈ pat.cname, 1, 0)
                end
                if inbalance > 0
                    err_block_unclosed(otok, pat)
                end
            else
                j = findfirst(j -> !inactive[j] && tokens[j].name ∈ pat.cname,
                              i+1:ntokens)
                if isnothing(j)
                    err_block_unclosed(otok, pat)
                else
                    j += i
                end
            end
            # recuperate closing token
            ctok = tokens[j]

            # add block to stack
            push!(blocks, Block(pat.name, otok, ctok))

            # if required, mark all tokens in the span as inactive
            # otherwise just the opening and closing token
            if pat.deactivate
                inactive[i:j] .= true
            else
                inactive[i] = inactive[j] = true
            end
        end
    end
    deleteat!(tokens, inactive)
    return blocks
end


# NOTE: needs to be called until there is no more as could
# aggregate super blocks
#
# -- also need use <= for from bc e.g. START could overlap
function find_superblocks(blocks::Vector{<:AbstractBlock},
                          sbp::Vector{SuperBlockPattern}
                          )::Vector{Union{Block,SuperBlock}}
    sb = Vector{Union{Block,SuperBlock}}()
    length(blocks) < 2 && return blocks
    cur = blocks[1]
    nextidx = 2
    while nextidx <= length(blocks)
        next = blocks[nextidx]
        cand = combine(cur, next, sbp)
        if isnothing(cand)
            push!(sb, cur)
            if cur isa SuperBlock && cur.sub_blocks[end].name == :LINE_RETURN
                cur = cur.sub_blocks[end]
                continue # no update for next
            else
                cur = blocks[nextidx]
            end
        else
            cur = cand
        end
        nextidx += 1
    end
    push!(sb, cur)
    # second pass to aggregate super blocks
    eltype(blocks) == Block && return find_superblocks(sb, sbp)
    return sb
end
