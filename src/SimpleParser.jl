module SimpleParser

export Pattern, Token
export next_char, nchars, tokenize
export r_empty, r_string,
       gr_isletter
export EOS, SPACE_CHARS, NUM_CHARS

const AS = AbstractString

const EOS         = '\0'
const SPACE_CHARS = [' ', '\n', '\t', '\v', '\f', '\r', '\u85', '\ua0', EOS]
const NUM_CHARS   = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']

include("pattern.jl")
include("utils.jl")
include("token.jl")

end # module
