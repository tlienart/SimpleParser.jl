@testset "tokenize" begin
    pats = Dict(
        '\\' => [
            Pattern{1}(:BACKSLASH, r_empty, [' ', '\0']),
            Pattern{2}(:ESC_CHAR,  r_empty, [' ', '\0']),
            Pattern(:NEWCOMMAND, raw"\newcommand", ['{']),
            Pattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
            ],
        )

    s1 = "a \\ b"
    tokens = tokenize(s1, pats)
    @test length(tokens) == 1
    @test tokens[1].name == :BACKSLASH
    @test tokens[1].ss == "\\"

    s2 = "a\\b"
    tokens = tokenize(s2, pats)
    @test length(tokens) == 1
    @test tokens[1].name == :ESC_CHAR
    @test tokens[1].ss == "\\b"

    s3 = "a\\newcommand{} b"
    tokens = tokenize(s3, pats)
    @test length(tokens) == 1
    @test tokens[1].name == :NEWCOMMAND
    @test tokens[1].ss == "\\newcommand"

    s4 = "a\\com b"
    tokens = tokenize(s4, pats)
    @test length(tokens) == 1
    @test tokens[1].name == :COMMAND
    @test tokens[1].ss == "\\com"

    s5 = "a\\ \\b \\com \\newcommand{} c"
    tokens = tokenize(s5, pats)
    @test length(tokens) == 4
    @test tokens[1].name == :BACKSLASH
    @test tokens[2].name == :ESC_CHAR
    @test tokens[3].name == :COMMAND
    @test tokens[4].name == :NEWCOMMAND

    s6 = "a\\"
    tokens = tokenize(s6, pats)
    @test tokens[1].name == :BACKSLASH

    # NOTE and not newcommand because '{' missing (corner case)
    s7 = "a\\newcommand"
    tokens = tokenize(s7, pats)
    @test tokens[1].name == :COMMAND
end
