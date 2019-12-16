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
    b.ctok === nothing && return subs("")
    s = str(b) # does not allocate
    cfrom = nextind(s, to(b.otok))
    cto   = prevind(s, from(b.ctok))
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

function SuperBlock(n::Symbol, b1::Block, bs::Block...)::SuperBlock
    s = str(b1)
    SuperBlock(n, subs(s, from(b1), to(bs[end])), [b1, bs...])
end

Base.getindex(b::SuperBlock, i::Int) = b.sub_blocks[i]

"""
content(superblock)

Return a vector with the content of each sub-block of the super block.
"""
content(b::SuperBlock)::Vector{SS} = content.(b.sub_blocks)


"""
BlockPattern

## Fields

* `name`:       Symbol to identify the block type,
* `oname`:      Symbol to identify opening-token,
* `cname`:      Vector of Symbol to identify closing-token(s),
* `balance`:    Whether to try to balance opening/closing tokens,
* `deactivate`: Whether to mark all tokens in range as inactive.
"""
struct BlockPattern
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

* `name`:   Symbol to identify the super block.
* `oname`:  Symbol to identify the first part of a super block pattern.
* `cname`:  Symbol to identify the second part of a super block pattern.
"""
struct SuperBlockPattern
    name::Symbol
    oname::Symbol
    cname::Symbol
end
