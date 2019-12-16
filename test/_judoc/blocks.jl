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