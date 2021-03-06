abstract type AbstractBlock <: AbstractElement end


"""
Block

Either a single token or a pair of tokens indicating a part of the text on
which an action must be taken.
"""
struct Block <: AbstractBlock
    name::Symbol
    ss::SS
    otok::Token
    ctok::Union{Nothing,Token}
end
Block(t)         = Block(t.name, t.ss, t, nothing)
Block(n, ot, ct) = Block(n, subs(str(ot), from(ot), to(ct)), ot, ct)

"""
content(block)

Return the substring corresponding to the range wedged between the block
opening token and its closing token.
"""
function content(b::Block)::SS
    isnothing(b.ctok) && return subs("")
    s = str(b) # does not allocate
    L = length(s)
    o = b.otok
    c = b.ctok
    cfrom = ifelse(o.name == :SOS, 1, nextind(s, to(o)))
    cto   = ifelse(c.name == :EOS, L, prevind(s, from(b.ctok)))
    return subs(s, cfrom, cto)
end


"""
SuperBlock

A sequence of Block that should be understood to work together.
"""
struct SuperBlock <: AbstractBlock
    name::Symbol
    ss::SS
    sub_blocks::Vector{Block}
end

function SuperBlock(n::Symbol, b1::Block, b2::Block)::SuperBlock
    s = str(b1)
    SuperBlock(n, subs(s, from(b1), to(b2)), [b1, b2])
end
function SuperBlock(n::Symbol, b1::SuperBlock, b2::Block)::SuperBlock
    s = str(b1)
    SuperBlock(n, subs(s, from(b1), to(b2)), [b1.sub_blocks..., b2])
end

Base.getindex(b::SuperBlock, i::Int) = b.sub_blocks[i]

"""
content(superblock)

Return a vector with the content of each sub-block of the super block.
"""
content(b::SuperBlock)::Vector{SS} = content.(b.sub_blocks)


abstract type AbstractBlockPattern end

"""
BlockPattern

## Fields

* `name`:       Symbol to identify the block type,
* `oname`:      Symbol to identify opening-token,
* `cname`:      Vector of Symbol to identify closing-token(s),
* `balance`:    Whether to try to balance opening/closing tokens,
* `deactivate`: Whether to mark all tokens in range as inactive.
"""
struct BlockPattern <: AbstractBlockPattern
    name::Symbol
    oname::Symbol
    cname::Vector{Symbol}
    balance::Bool
    deactivate::Bool # deactivate everything in the range
end
BlockPattern(n, o, c::Symbol, a...) = BlockPattern(n, o, [c], a...)


"""
SuperBlockPattern

Pair of two blocks that will go in  [`SuperBlock`](@ref).

## Fields

* `name`:     Symbol to identify the super block.
* `oname`:    Symbol to identify the first part of a super block pattern.
* `cname`:    Symbol to identify the second part of a super block pattern.
"""
struct SuperBlockPattern <: AbstractBlockPattern
    name::Symbol
    oname::Symbol
    cname::Symbol
end


"""
combine(b1, b2, patterns)

Given two adjacent block `b1` and `b2`, try to join them in a superblock that
would match a pattern in `patterns`.
"""
function combine(b1::AbstractBlock, b2::AbstractBlock,
                 pats::Vector{SuperBlockPattern})::Union{Nothing,SuperBlock}
    for pat in pats
        pat.oname == b1.name || continue
        b2.name == pat.cname || continue
        (from(b2) - to(b1)) ∈ [0, 1] || continue
        return SuperBlock(pat.name, b1, b2)
    end
    return nothing
end
