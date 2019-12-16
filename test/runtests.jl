using SimpleParser, Test

include("utils.jl")

include("error/error.jl")

include("token/pattern.jl")
include("token/token.jl")

include("block/block.jl")

# FULL CASES

include("_judoc/defs.jl")
include("_judoc/tokens.jl")
include("_judoc/blocks.jl")
