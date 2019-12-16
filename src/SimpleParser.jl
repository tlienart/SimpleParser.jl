module SimpleParser

export TokenPattern, Token,
       BlockPattern, Block,
       SuperBlockPattern, SuperBlock
# tokens
export EOS, SPACE_CHARS, NUM_CHARS
export from, to, content
export next_char, nchars, tokenize
export r_empty, r_string, gr_isletter
export find_singleblocks!, find_pairblocks!

const EOS         = '\0'
const SPACE_CHARS = [' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS]
const NUM_CHARS   = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']

const AS = AbstractString
const SS = SubString

abstract type AbstractElement end

include("utils.jl")

include("error/error.jl")
include("error/utils.jl")

include("token/token.jl")
include("token/find.jl")

include("block/block.jl")
include("block/find.jl")

end # module
