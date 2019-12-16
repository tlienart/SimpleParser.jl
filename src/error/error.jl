abstract type ParserException <: Exception end

struct BlockError <: ParserException
    msg::String
    context::String
end

function Base.showerror(io::IO, be::BlockError)
    println(io, be.msg)
    print(io, be.context)
end
