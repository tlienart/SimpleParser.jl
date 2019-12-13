const ∅ = r_empty

r_esc_char(s::AbstractString) = s[2] in ['*', '_', '`', '@', '{', '}', '\$']

function gr_isdiv(parent::AbstractString, start::Int)
    nchars, pos = 0, start
    # check initial match of (@)`@`
    next = next_char(parent, pos)
    next.char == '@' || return 0
    pos = next.pos
    # then greedy match until space or invalid char
    nchars = gr_isletter(parent, pos, extras=['_', '-', NUM_CHARS...])
    nchars > 0 || return 0
    return nchars + 1 # include '@'
end

function gr_isentity(parent::AbstractString, start::Int)
    # either format &nbsp; or &#000;
    nchars, pos = 0, start
    complete = false
    next = next_char(parent, pos)
    if next.char == '#'
       nchars += 1
       pos = next.pos
       # match while number, stop when anything else, if ';' mark complete
       while true
           next = next_char(parent, pos)
           if next.char == ';'
               complete = true
               nchars += 1
               break
           elseif next.char ∈ NUM_CHARS
               nchars += 1
               pos = next.pos
           else
               break
           end
       end
    elseif isletter(next.char)
       nchars += 1
       pos = next.pos
       # match while letter, stop when anything else, if ';' mark complete
       while true
           next = next_char(parent, pos)
           if next.char == ';'
               complete = true
               nchars += 1
               break
           elseif isletter(next.char)
               nchars += 1
               pos = next.pos
           else
               break
           end
       end
    end
    complete && return nchars
    return 0
end

function gr_iscode(par::AbstractString, start::Int, nticks::Int)
    nchars, pos = 0, start
    # check nticks-1 chas
    pos = nextind(par, pos, nticks)
    keep_going = pos < lastindex(par) &&
                SimpleParser.subs(par, start, prevind(par, pos)) == '`'^nticks
    keep_going || return 0
   if isletter(par[pos])
       nchars = gr_isletter(par, pos, extras=['_', '-', NUM_CHARS...])
       nchars += nticks
   end
   return nchars
end
gr_iscode3 = (p, s) -> gr_iscode(p, s, 3)
gr_iscode5 = (p, s) -> gr_iscode(p, s, 5)

# NOTE: in JuDoc there should be precedence of commands
# so for instance \E will get recognised as ESC_CHAR but when
# processed, it should first be considered as a command `\E` if a
# definition exists and then an escaped char otherwise.

TOKS = Dict{Char,Vector{Pattern}}(
    '<'  => [ Pattern(:O_COMMENT, "<!--") ],
    '-'  => [ Pattern(:C_COMMENT, "-->") ],
    '~'  => [ Pattern(:ESCAPE, "~~~") ],
    '('  => [ Pattern{1}(:O_BRACKET_1, ∅) ],
    ')'  => [ Pattern{1}(:C_BRACKET_1, ∅) ],
    '['  => [ Pattern{1}(:O_BRACKET_2, ∅) ],
    ']'  => [ Pattern{1}(:C_BRACKET_2, ∅) ],
    '{'  => [ Pattern{1}(:O_BRACKET_3, ∅) ],
    '}'  => [ Pattern{1}(:C_BRACKET_3, ∅) ],
    '\n' => [ Pattern{1}(:LINE_RETURN, ∅) ],
    '\t' => [ Pattern{1}(:TAB_1,       ∅) ],
    ' '  => [
        Pattern(:TAB_4, "    "),
        Pattern(:TAB_2, "  "),
        ],
    '\$' => [
        Pattern(:MATH_B, "\$\$"),
        Pattern{1}(:MATH_A, ∅),
        ],
    '\\' => [
        Pattern{1}(:BACKSLASH, ∅, SPACE_CHARS),
        Pattern(:BACKSLASH_2, "\\\\"),
        Pattern{2}(:ESC_CHAR,  r_esc_char),
        Pattern(:O_MATH_C,     "\\["),
        Pattern(:C_MATH_C,     "\\]"),
        Pattern(:NEWCOMMAND,   "\\newcommand", ['{']),
        Pattern(:O_MATH_ALIGN, "\\begin{align}"),
        Pattern(:C_MATH_ALIGN, "\\end{align}"),
        Pattern(:O_MATH_EQ,    "\\begin{equation}"),
        Pattern(:C_MATH_EQ,    "\\end{equation}"),
        Pattern(:O_MATH_EQA,   "\\begin{eqnarray}"),
        Pattern(:C_MATH_EQA,   "\\end{eqnarray}"),
        Pattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
        ],
    '@'  => [
        Pattern(:MD_DEF, "@def", [' ']),
        Pattern(:C_DIV,    "@@", SPACE_CHARS),
        Pattern{0}(:O_DIV, gr_isdiv)
        ],
    '#'  => [
        Pattern(:H1, "#",      [' ']),
        Pattern(:H2, "##",     [' ']),
        Pattern(:H3, "###",    [' ']),
        Pattern(:H4, "####",   [' ']),
        Pattern(:H5, "#####",  [' ']),
        Pattern(:H6, "######", [' ']),
        ],
    '&'  => [ Pattern{0}(:HTML_ENTITY, gr_isentity) ],
    '_'  => [
        Pattern(:O_MATH_I, "_\$>_"),
        Pattern(:C_MATH_I, "_\$<_")
        ],
    '`'  => [
        Pattern(:CODE_1, "`",  Char[], ['`']),
        Pattern(:CODE_2, "``", Char[], ['`']),
        Pattern(:CODE_3, "```", SPACE_CHARS),
        Pattern(:CODE_5, "`````", SPACE_CHARS),
        Pattern{0}(:O_CODE_3, gr_iscode3),
        Pattern{0}(:O_CODE_5, gr_iscode5)
        ],
) # end of dict

tok = s -> tokenize(s, TOKS)
