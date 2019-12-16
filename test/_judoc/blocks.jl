@testset "block:jd:s1"  begin
    s = "Blah \\* \netc\t"
    t = s |> tok
    @test length(t) == 5
    b = t |> blk1!
    @test length(t) == 0
    @test length(b) == 5
    @test b[1].name == :SOS
    @test b[2].name == :ESC_CHAR
    @test b[3].name == :LINE_RETURN
    @test b[4].name == :TAB_1
    @test b[5].name == :EOS
    s = "Blah \\    \\\\"
    t = s |> tok
    b = t |> blk1!
    @test length(b) == 5
    @test b[2].name == :BACKSLASH
    @test b[3].name == :TAB_4
    @test b[4].name == :BACKSLASH_2
    # empty
    s = ""
    @test isempty(s |> tok)
    @test isempty(s |> tok |> blk1!)
end

@testset "block:jd:com" begin
    t = "A<!--B-->C" |> tok
    b = t |> blk
    @test length(b) == 3
    @test b[3].name == :COMMENT
    @test b[3].ss == "<!--B-->"
    @test content(b[3]) == "B"
    @test from(b[3]) == 2
    @test to(b[3]) == 9
    # no balance
    t = "A<!--B<!--C~~~-->D" |> tok
    b = t |> blk
    @test b[3].name == :COMMENT
    @test content(b[3]) == "B<!--C~~~"
    @test length(t) == 0
end

@testset "block:jd:esc" begin
    b = "A~~~B<!--C-->~~~D" |> tok |> blk
    @test b[3].name == :COMMENT
    @test b[4].name == :ESCAPE
    @test content(b[4]) == "B<!--C-->"
end

@testset "block:jd:([{" begin
    b = "A(B(C))" |> tok |> blk
    @test b[3].name == :BRACKET_1
    @test content(b[3]) == "B(C)"
    @test b[4].name == :BRACKET_1
    @test content(b[4]) == "C"
    b = "A(B[C{D}])" |> tb
    @test b[3].name == :BRACKET_1
    @test b[4].name == :BRACKET_2
    @test b[5].name == :BRACKET_3
    @test content(b[3]) == "B[C{D}]"
    @test content(b[4]) == "C{D}"
    @test content(b[5]) == "D"
    b = "A(B(C(D[E[F{G[H(I)]}]])))" |> tb
    # first all "(...)"
    for i in 2:5
        @test b[2-1+i].name == :BRACKET_1
    end
    # second all "[...]"
    for i in 2:4
        @test b[5+i].name == :BRACKET_2
    end
    # last all "{...}"
    @test b[10].name == :BRACKET_3
    @test content(b[3]) == "B(C(D[E[F{G[H(I)]}]]))"
    @test content(b[7]) == "E[F{G[H(I)]}]"
    @test content(b[10]) == "G[H(I)]"
end

@testset "block:jd:math" begin
    b = raw"A$B$C" |> tb
    @test b[3].name == :MATH_A
    @test content(b[3]) == "B"
    b = raw"A$$B$$C$D$E" |> tb
    @test b[3].name == :MATH_A
    @test content(b[3]) == "D"
    @test b[4].name == :MATH_B
    @test content(b[4]) == "B"
    b = raw"A\[B\]C" |> tb
    @test b[3].name == :MATH_C
    b = raw"A\begin{align}B\end{align}C" |> tb
    @test b[3].name == :MATH_ALIGN
    @test content(b[3]) == "B"
    b = raw"A\begin{equation}B\end{equation}C" |> tb
    @test b[3].name == :MATH_EQ
    @test content(b[3]) == "B"
    b = raw"A\begin{eqnarray}B\end{eqnarray}C" |> tb
    @test b[3].name == :MATH_EQA
    @test content(b[3]) == "B"
end

@testset "block:jd:code" begin
    b = raw"A`(B`C" |> tb
    @test b[3].name == :CODE_1
    @test content(b[3]) == "(B"
    b = raw"A``(`B``C" |> tb
    @test b[3].name == :CODE_2
    @test content(b[3]) == "(`B"
    b = raw"A``` (``B`C```" |> tb
    @test b[3].name == :CODE_3
    @test content(b[3]) == " (``B`C"
    b = raw"A````` ``` (``B`C`````" |> tb
    @test b[3].name == :CODE_5
    @test content(b[3]) == " ``` (``B`C"
    b = raw"A```b`` C```" |> tb
    @test b[3].name == :CODE_3L
    @test content(b[3]) == "`` C"
    @test b[3].otok.ss == "```b"
    b = raw"A`````b`` C`````" |> tb
    @test b[3].name == :CODE_5L
    @test content(b[3]) == "`` C"
    @test b[3].otok.ss == "`````b"
end

@testset "block:jd:err" begin
    t = "<!--" |> tok
    mess = "Context:\n\t<!-- (near line 1)\n	^---\n"
    @test SimpleParser.context(t[1]) == mess
    if VERSION >= v"1.3.1"
        @test_throws SimpleParser.BlockError("Found opening token O_COMMENT but not a matching closing token (expected one of [:C_COMMENT])", mess) "<!--" |> tb
    else
        @test_throws SimpleParser.BlockError("Found opening token O_COMMENT but not a matching closing token (expected one of Symbol[:C_COMMENT])", mess) "<!--" |> tb
    end
end

@testset "block:jd:div" begin
    b = "@@b c@@" |> tb
    @test b[3].name == :DIV
    @test content(b[3]) == " c"
    b = "@@b @@c d@@ @@" |> tb
    @test b[3].name == :DIV
    @test b[4].name == :DIV
    @test content(b[3]) == " @@c d@@ "
    @test content(b[4]) == " d"
end

#
# === line and super blocks
#

@testset "sblock:jd:lbl" begin
    b = "    hello" |> tbl
    @test b[1].name == :L_INDENT_4
    @test content(b[1]) == "hello"

    b = "    hello\n    bye" |> tbl
    @test b[1].name == :L_INDENT_4
    @test content(b[1]) == "hello"
    @test b[2].name == :L_INDENT_4
    @test content(b[2]) == "bye"

    b = "@def v=5\n@def h=7" |> tbl
    @test b[1].name == :L_MD_DEF
    @test content(b[1]) == " v=5"
    @test b[2].name == :L_MD_DEF
    @test content(b[2]) == " h=7"

    c = """
        ab
        c
    e
      fg
      hi
    m
    @def h = 7
    @def g = "blah"
    """ |> tbl
    @test c[1].name == :EOS
    @test content(c[2]) == "ab"
    @test content(c[3]) == "c"
    @test content(c[4]) == "fg"
    @test content(c[5]) == "hi"
    @test content(c[6]) == " h = 7"
    @test content(c[7]) == " g = \"blah\""
end

@testset "sblock:jd:mdd" begin
    s = "@def v = 5" |> ptbs
    @test length(s) == 1
    @test s[1].name == :L_MD_DEF
    @test content(s[1]) == " v = 5"

    s = """
    A
    @def h = 3
    B
    """ |> ptbs
    @test s[1].name == :L_MD_DEF
    @test content(s[1]) == " h = 3"

    s = """
    A
    @def h = [1 2;
              3 4]
    B
    """ |> ptbss
    @test s[1].name == :S_MD_DEF
    e = strip(prod(l * "\n" for l in content(s[1])))
    @test e == "h = [1 2;\n      3 4]"
    @test Meta.parse(e) == :(h = [1 2; 3 4])
end

@testset "sblock:jd:mdd" begin
    s = "@def v = 5" |> ptbs
    @test length(s) == 1
    @test s[1].name == :L_MD_DEF
    @test content(s[1]) == " v = 5"

    s = """
    A
    @def h = 3
    B
    """ |> ptbs
    @test s[1].name == :L_MD_DEF
    @test content(s[1]) == " h = 3"

    s = """
    A
    @def h = [1 2;
              3 4]
    B
    """ |> ptbss
    @test s[1].name == :S_MD_DEF
    e = strip(prod(l * "\n" for l in content(s[1])))
    @test e == "h = [1 2;\n      3 4]"
    @test Meta.parse(e) == :(h = [1 2; 3 4])
end

@testset "sblock:jd:ind" begin
    s = """
    A
        B
        C
    D
      E
      F
    G
    """ |> ptbss
    @test s[1].name == :INDENT_4
    @test s[2].name == :INDENT_2
    @test content(s[1]) == ["B", "C"]
    @test content(s[2]) == ["E", "F"]
end
