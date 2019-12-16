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

TOKS = Dict{Char,Vector{TokenPattern}}(
    # Other entries
    '<'  => [ TokenPattern(:O_COMMENT, "<!--") ],   # P: comment        ✓
    '-'  => [ TokenPattern(:C_COMMENT, "-->") ],    # .
    '~'  => [ TokenPattern(:ESCAPE, "~~~") ],       # P: escape         ✓
    '('  => [ TokenPattern{1}(:O_BRACKET_1, ∅) ],   # P: bracket_1      ✓
    ')'  => [ TokenPattern{1}(:C_BRACKET_1, ∅) ],   # .
    '['  => [ TokenPattern{1}(:O_BRACKET_2, ∅) ],   # P: bracket_2      ✓
    ']'  => [ TokenPattern{1}(:C_BRACKET_2, ∅) ],   # .
    '{'  => [ TokenPattern{1}(:O_BRACKET_3, ∅) ],   # P: bracket_3      ✓
    '}'  => [ TokenPattern{1}(:C_BRACKET_3, ∅) ],   # .
    '\t' => [ TokenPattern{1}(:TAB_1,       ∅) ],   # S                 ✓
    ' '  => [
        TokenPattern(:TAB_4, "    "),               # S                 ✓
        TokenPattern(:TAB_2, "  "),                 # S                 ✓
        ],
    '\$' => [
        TokenPattern(:MATH_B, "\$\$"),              # P: math_b         ✓
        TokenPattern{1}(:MATH_A, ∅),                # P: math_a         ✓
        ],
    '\\' => [
        TokenPattern{1}(:BACKSLASH, ∅, SPACE_CHARS),# S                 ✓
        TokenPattern(:BACKSLASH_2, "\\\\"),         # S                 ✓
        TokenPattern{2}(:ESC_CHAR,  r_esc_char),    # S                 ✓
        TokenPattern(:O_MATH_C,     "\\["),         # P: math_c         ✓
        TokenPattern(:C_MATH_C,     "\\]"),         # .
        TokenPattern(:NEWCOMMAND,   "\\newcommand", ['{']),
        TokenPattern(:O_MATH_ALIGN, "\\begin{align}"),    # P: math_align✓
        TokenPattern(:C_MATH_ALIGN, "\\end{align}"),      # .
        TokenPattern(:O_MATH_EQ,    "\\begin{equation}"), # P: math_eq  ✓
        TokenPattern(:C_MATH_EQ,    "\\end{equation}"),   # .
        TokenPattern(:O_MATH_EQA,   "\\begin{eqnarray}"), # P: math_eqa ✓
        TokenPattern(:C_MATH_EQA,   "\\end{eqnarray}"),   # .
        TokenPattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
        ],
    '@'  => [
        TokenPattern(:DEF, "@def", [' ']),          # S ~ SB            ✓
        TokenPattern(:C_DIV,    "@@", SPACE_CHARS), # P: div            ✓
        TokenPattern{0}(:O_DIV, gr_isdiv)           # .
        ],
    '#'  => [
        TokenPattern(:H1, "#",      [' ']),         # S ~ SB            ✓
        TokenPattern(:H2, "##",     [' ']),         # S ~ SB            ✓
        TokenPattern(:H3, "###",    [' ']),         # S ~ SB            ✓
        TokenPattern(:H4, "####",   [' ']),         # S ~ SB            ✓
        TokenPattern(:H5, "#####",  [' ']),         # S ~ SB            ✓
        TokenPattern(:H6, "######", [' ']),         # S ~ SB            ✓
        ],
    '&'  => [ TokenPattern{0}(:HTML_ENTITY, gr_isentity) ], # S         ✓
    '_'  => [
        TokenPattern(:O_MATH_I, "_\$>_"),           # P: math_i         ✓
        TokenPattern(:C_MATH_I, "_\$<_")            # .
        ],
    '`'  => [
        TokenPattern(:CODE_1, "`",  Char[], ['`']), # P: code_1         ✓
        TokenPattern(:CODE_2, "``", Char[], ['`']), # P: code_2         ✓
        TokenPattern(:CODE_3, "```",   SPACE_CHARS),# P: code_3         ✓
        TokenPattern(:CODE_5, "`````", SPACE_CHARS),# P: code_5         ✓
        TokenPattern{0}(:O_CODE_3, gr_iscode3),     # P: code_3l        ✓
        TokenPattern{0}(:O_CODE_5, gr_iscode5)      # P: code_5l        ✓
        ],
) # end of dict

tok = s -> tokenize(s, TOKS)

SINGLES = [:SOS, :EOS,
           :ESC_CHAR, :LINE_RETURN, :TAB_1, :TAB_2, :TAB_4,
           :BACKSLASH, :BACKSLASH_2, :H1, :H2, :H3, :H4, :H5, :H6,
           :DEF]

blk1! = t -> find_singleblocks!(t, SINGLES)

# NOTE: ordering matters here (first go over environments which deactivate
# the tokens inside them to avoid issues)
# XXX in math environment, should allow ( and ] (should not check them and
# just ignore those tokens
PAIRS = [
    # PAIR        name        o tok         c tok        bal?   deact?
    BlockPattern(:COMMENT,   :O_COMMENT,   :C_COMMENT,   false, true),
    BlockPattern(:ESCAPE,    :ESCAPE,      :ESCAPE,      false, true),
    # code
    BlockPattern(:CODE_5L,   :O_CODE_5,    :CODE_5,      false, true),
    BlockPattern(:CODE_3L,   :O_CODE_3,    :CODE_3,      false, true),
    BlockPattern(:CODE_5,    :CODE_5,      :CODE_5,      false, true),
    BlockPattern(:CODE_3,    :CODE_3,      :CODE_3,      false, true),
    BlockPattern(:CODE_2,    :CODE_2,      :CODE_2,      false, true),
    BlockPattern(:CODE_1,    :CODE_1,      :CODE_1,      false, true),
    # maths
    BlockPattern(:MATH_A,    :MATH_A,      :MATH_A,      false, true),
    BlockPattern(:MATH_B,    :MATH_B,      :MATH_B,      false, true),
    BlockPattern(:MATH_C,    :O_MATH_C,    :C_MATH_C,    false, true),
    BlockPattern(:MATH_I,    :O_MATH_I,    :C_MATH_I,    false, true),
    BlockPattern(:MATH_ALIGN,:O_MATH_ALIGN,:C_MATH_ALIGN,false, true),
    BlockPattern(:MATH_EQ,   :O_MATH_EQ,   :C_MATH_EQ,   false, true),
    BlockPattern(:MATH_EQA,  :O_MATH_EQA,  :C_MATH_EQA,  false, true),
    # brackets
    BlockPattern(:BRACKET_1, :O_BRACKET_1, :C_BRACKET_1, true,  false),
    BlockPattern(:BRACKET_2, :O_BRACKET_2, :C_BRACKET_2, true,  false),
    BlockPattern(:BRACKET_3, :O_BRACKET_3, :C_BRACKET_3, true,  false),
    # div
    BlockPattern(:DIV,       :O_DIV,       :C_DIV,       true,  false),
] # end of vector

blkp! = t -> find_pairblocks!(t, PAIRS)

blk = t -> (a = blk1!(t); vcat(a, blkp!(t)))

tb = blk ∘ tok

LINES = Dict{Symbol,Symbol}(
    :TAB_1 => :L_INDENT_1,
    :TAB_2 => :L_INDENT_2,
    :TAB_4 => :L_INDENT_4,
    :DEF   => :L_MD_DEF,
    :H1    => :L_H1,
    :H2    => :L_H2,
    :H3    => :L_H3,
    :H4    => :L_H4,
    :H5    => :L_H5,
    :H6    => :L_H6,
)

blkl! = b -> find_lineblocks!(b, LINES)

tbl = blkl! ∘ tb

SUPER = [
    # ----------------------------------------------------------------
    # md defs: starts with :L_MD_DEF then any number of indented lines
    # (not necessarily matching indentations)
    SuperBlockPattern(:S_MD_DEF, :L_MD_DEF, :L_INDENT_1),
    SuperBlockPattern(:S_MD_DEF, :L_MD_DEF, :L_INDENT_2),
    SuperBlockPattern(:S_MD_DEF, :L_MD_DEF, :L_INDENT_4),
    SuperBlockPattern(:S_MD_DEF, :MD_DEF,   :L_INDENT_1),
    SuperBlockPattern(:S_MD_DEF, :MD_DEF,   :L_INDENT_2),
    SuperBlockPattern(:S_MD_DEF, :MD_DEF,   :L_INDENT_4),
    # ----------------------------------------------------------------
    # indented blocks: starts with :L_INDENT_K then any number of matching
    # indented lines
    SuperBlockPattern(:INDENT_1, :L_INDENT_1, :L_INDENT_1),
    SuperBlockPattern(:INDENT_1, :INDENT_1,   :L_INDENT_1),
    SuperBlockPattern(:INDENT_2, :L_INDENT_2, :L_INDENT_2),
    SuperBlockPattern(:INDENT_2, :INDENT_2,   :L_INDENT_2),
    SuperBlockPattern(:INDENT_4, :L_INDENT_4, :L_INDENT_4),
    SuperBlockPattern(:INDENT_4, :INDENT_4,   :L_INDENT_4),
]

sblk = b -> find_superblocks(b, SUPER)

tbs = sblk ∘ tbl

ptbs  = s -> (filter!(e -> e.name ∉ [:LINE_RETURN, :SOS, :EOS], tbs(s)))
ptbss = s -> sort(ptbs(s); by=from)

# NOTE: at this point, a number of blocks are taken possibly multiple times!
