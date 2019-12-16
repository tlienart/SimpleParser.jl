@testset "block:jd:s1"  begin
    s = "Blah \\* \netc\t"
    t = s |> tok
    @test length(t) == 4
    b = t |> blk1!
    @test length(t) == 0
    @test length(b) == 4
    @test b[1].name == :SOS
    @test b[2].name == :ESC_CHAR
    @test b[3].name == :LINE_RETURN
    @test b[4].name == :TAB_1
    s = "Blah \\    \\\\"
    t = s |> tok
    b = t |> blk1!
    @test length(b) == 4
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
    @test length(b) == 2
    @test b[2].name == :COMMENT
    @test b[2].ss == "<!--B-->"
    @test content(b[2]) == "B"
    @test from(b[2]) == 2
    @test to(b[2]) == 9
    # no balance
    t = "A<!--B<!--C~~~-->D" |> tok
    b = t |> blk
    @test b[2].name == :COMMENT
    @test content(b[2]) == "B<!--C~~~"
    @test length(t) == 0
end

@testset "block:jd:esc" begin
    b = "A~~~B<!--C-->~~~D" |> tok |> blk
    @test b[2].name == :COMMENT
    @test b[3].name == :ESCAPE
    @test content(b[3]) == "B<!--C-->"
end

@testset "block:jd:([{" begin
    b = "A(B(C))" |> tok |> blk
    @test b[2].name == :BRACKET_1
    @test content(b[2]) == "B(C)"
    @test b[3].name == :BRACKET_1
    @test content(b[3]) == "C"
    b = "A(B[C{D}])" |> tb
    @test b[2].name == :BRACKET_1
    @test b[3].name == :BRACKET_2
    @test b[4].name == :BRACKET_3
    @test content(b[2]) == "B[C{D}]"
    @test content(b[3]) == "C{D}"
    @test content(b[4]) == "D"
    b = "A(B(C(D[E[F{G[H(I)]}]])))" |> tb
    # first all "(...)"
    for i in 1:4
        @test b[2-1+i].name == :BRACKET_1
    end
    # second all "[...]"
    for i in 1:3
        @test b[5+i].name == :BRACKET_2
    end
    # last all "{...}"
    @test b[9].name == :BRACKET_3
    @test content(b[2]) == "B(C(D[E[F{G[H(I)]}]]))"
    @test content(b[6]) == "E[F{G[H(I)]}]"
    @test content(b[9]) == "G[H(I)]"
end

@testset "block:jd:math" begin
    b = raw"A$B$C" |> tb
    @test b[2].name == :MATH_A
    @test content(b[2]) == "B"
    b = raw"A$$B$$C$D$E" |> tb
    @test b[2].name == :MATH_A
    @test content(b[2]) == "D"
    @test b[3].name == :MATH_B
    @test content(b[3]) == "B"
    b = raw"A\[B\]C" |> tb
    @test b[2].name == :MATH_C
    b = raw"A\begin{align}B\end{align}C" |> tb
    @test b[2].name == :MATH_ALIGN
    @test content(b[2]) == "B"
    b = raw"A\begin{equation}B\end{equation}C" |> tb
    @test b[2].name == :MATH_EQ
    @test content(b[2]) == "B"
    b = raw"A\begin{eqnarray}B\end{eqnarray}C" |> tb
    @test b[2].name == :MATH_EQA
    @test content(b[2]) == "B"
end

@testset "block:jd:code" begin
    b = raw"A`(B`C" |> tb
    @test b[2].name == :CODE_1
    @test content(b[2]) == "(B"
    b = raw"A``(`B``C" |> tb
    @test b[2].name == :CODE_2
    @test content(b[2]) == "(`B"
    b = raw"A``` (``B`C```" |> tb
    @test b[2].name == :CODE_3
    @test content(b[2]) == " (``B`C"
    b = raw"A````` ``` (``B`C`````" |> tb
    @test b[2].name == :CODE_5
    @test content(b[2]) == " ``` (``B`C"
    b = raw"A```b`` C```" |> tb
    @test b[2].name == :CODE_3L
    @test content(b[2]) == "`` C"
    @test b[2].otok.ss == "```b"
    b = raw"A`````b`` C`````" |> tb
    @test b[2].name == :CODE_5L
    @test content(b[2]) == "`` C"
    @test b[2].otok.ss == "`````b"
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
    @test b[2].name == :DIV
    @test content(b[2]) == " c"
    b = "@@b @@c d@@ @@" |> tb
    @test b[2].name == :DIV
    @test b[3].name == :DIV
    @test content(b[2]) == " @@c d@@ "
    @test content(b[3]) == " d"
end
