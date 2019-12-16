@testset "tok:jd:basics" begin
    # comments
    s = raw"A<!--B-->C"
    tokens = tokenize(s, TOKS)
    @test length(tokens) == 4
    @test tokens[2].name == :O_COMMENT
    @test tokens[3].name == :C_COMMENT
    @test tokens[2].ss == "<!--"
    @test tokens[3].ss == "-->"

    # escape
    s = raw"A~~~B~~~C"
    tokens = tokenize(s, TOKS)
    @test length(tokens) == 4
    @test tokens[2].name == tokens[3].name == :ESCAPE
    @test tokens[2].ss == tokens[3].ss == "~~~"

    # brackets
    s = raw"A(B)C[D]E{F}"
    tokens = tokenize(s, TOKS)
    @test length(tokens) == 8
    @test tokens[2].name == :O_BRACKET_1
    @test tokens[3].name == :C_BRACKET_1
    @test tokens[4].name == :O_BRACKET_2
    @test tokens[5].name == :C_BRACKET_2
    @test tokens[6].name == :O_BRACKET_3
    @test tokens[7].name == :C_BRACKET_3
    @test tokens[2].ss == "("
    @test tokens[3].ss == ")"
    @test tokens[4].ss == "["
    @test tokens[5].ss == "]"
    @test tokens[6].ss == "{"
    @test tokens[7].ss == "}"

    # line return
    s = "A\nB"
    tokens = tokenize(s, TOKS)
    @test length(tokens) == 3
    @test tokens[2].name == :LINE_RETURN
    @test tokens[2].ss == "\n"

    # Mixes
    t = "A\n~~~<!--B-->[C]D\\E" |> tok
    @test length(t) == 9
    @test t[2].name == :LINE_RETURN
    @test t[3].name == :ESCAPE
    @test t[4].name == :O_COMMENT
    @test t[5].name == :C_COMMENT
    @test t[6].name == :O_BRACKET_2
    @test t[7].name == :C_BRACKET_2
    @test t[8].name == :COMMAND
    t = "A\n\n\n" |> tok
    @test length(t) == 5
    @test all(e->e.name == :LINE_RETURN, t[2:end-1])
end

@testset "tok:jd:wsp" begin
    t = "\tB" |> tok
    @test t[2].name == :TAB_1
    t = "    B" |> tok
    @test t[2].name == :TAB_4
    t = "  B" |> tok
    @test t[2].name == :TAB_2
end

@testset "tok:jd:\\" begin
    t = raw"A \ B" |> tok
    @test length(t) == 3
    @test t[2].name == :BACKSLASH
    @test t[2].ss == "\\"

    t = raw"A \\ B" |> tok
    @test length(t) == 3
    @test t[2].name == :BACKSLASH_2
    @test t[2].ss == "\\\\"

    t = raw"A\B C" |> tok
    @test length(t) == 3
    @test t[2].name == :COMMAND

    t = raw"A\BC" |> tok
    @test length(t) == 3
    @test t[2].name == :COMMAND

    t = raw"A\*B" |> tok
    @test t[2].name == :ESC_CHAR
    t = raw"A\_B" |> tok
    @test t[2].name == :ESC_CHAR
    t = raw"A\`B" |> tok
    @test t[2].name == :ESC_CHAR
    t = raw"A\@B" |> tok
    @test t[2].name == :ESC_CHAR
    t = raw"A\{B\}" |> tok
    @test t[2].name == :ESC_CHAR
    @test t[3].name == :ESC_CHAR
    t = raw"A\$500" |> tok
    @test t[2].name == :ESC_CHAR

    t = raw"A\newcommand{\B}{C}" |> tok
    @test length(t) == 8
    @test t[2].name == :NEWCOMMAND
    @test t[3].name == :O_BRACKET_3
    @test t[4].name == :COMMAND
    @test t[5].name == :C_BRACKET_3
    @test t[6].name == :O_BRACKET_3
    @test t[7].name == :C_BRACKET_3

    t = raw"A\[B\]C" |> tok
    @test t[2].name == :O_MATH_C
    @test t[3].name == :C_MATH_C

    t = raw"A\begin{align}B\end{align}C" |> tok
    @test t[2].name == :O_MATH_ALIGN
    @test t[3].name == :C_MATH_ALIGN

    t = raw"A\begin{equation}B\end{equation}C" |> tok
    @test t[2].name == :O_MATH_EQ
    @test t[3].name == :C_MATH_EQ

    t = raw"A\begin{eqnarray}B\end{eqnarray}C" |> tok
    @test t[2].name == :O_MATH_EQA
    @test t[3].name == :C_MATH_EQA

    t = raw"A\somecom{B}C" |> tok
    @test t[2].name == :COMMAND
    @test t[2].ss == "\\somecom"
    @test t[3].name == :O_BRACKET_3
    @test t[4].name == :C_BRACKET_3
end

@testset "tok:jd:@" begin
    t = raw"@def B" |> tok
    @test t[2].name == :DEF

    t = raw"@@name-2 B@@" |> tok
    @test t[2].name == :O_DIV
    @test t[2].ss == "@@name-2"
    @test t[3].name == :C_DIV
end

@testset "tok:jd:#" begin
    t = raw"# ## ### #### ##### ###### " |> tok
    @test length(t) == 8
    @test t[2].name == :H1
    @test t[3].name == :H2
    @test t[4].name == :H3
    @test t[5].name == :H4
    @test t[6].name == :H5
    @test t[7].name == :H6
end

@testset "tok:jd:&" begin
    t = raw"&nbsp; &#00; &#2" |> tok
    @test length(t) == 4
    @test t[2].name == :HTML_ENTITY
    @test t[3].name == :HTML_ENTITY
    @test t[2].ss == "&nbsp;"
    @test t[3].ss == "&#00;"
end

@testset "tok:jd:\$" begin
    t = raw"A $B$ C $$D$$" |> tok
    @test length(t) == 6
    @test t[2].name == t[3].name == :MATH_A
    @test t[4].name == t[5].name == :MATH_B
end

@testset "tok:jd:`" begin
    t = raw"A`B" |> tok
    @test length(t) == 3
    @test t[2].name == :CODE_1
    t = raw"A`B`C``D``E" |> tok
    @test length(t) == 6
    @test t[2].name == t[3].name == :CODE_1
    @test t[4].name == t[5].name == :CODE_2
    t = raw"A``` B``` C ````` D `````" |> tok
    @test length(t) == 6
    @test t[2].name == t[3].name == :CODE_3
    @test t[4].name == t[5].name == :CODE_5
    t = raw"A```python B``` C `````julia D`````" |> tok
    @test length(t) == 6
    @test t[2].name == :O_CODE_3
    @test t[2].ss == "```python"
    @test t[3].name == :CODE_3
    @test t[4].name == :O_CODE_5
    @test t[4].ss == "`````julia"
    @test t[5].name == :CODE_5
end
