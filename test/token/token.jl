@testset "tokenize" begin
    pats = Dict(
        '\\' => [
            TokenPattern{1}(:BACKSLASH, r_empty, [' ', '\0']),
            TokenPattern{2}(:ESC_CHAR,  r_empty, [' ', '\0']),
            TokenPattern(:NEWCOMMAND, raw"\newcommand", ['{']),
            TokenPattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
            ],
        )

    s1 = "a \\ b"
    tokens = tokenize(s1, pats)
    @test length(tokens) == 2
    @test tokens[1].name == :SOS
    @test tokens[1].ss   == "a"
    @test tokens[2].name == :BACKSLASH
    @test tokens[2].ss == "\\"

    @test from(tokens[2]) == 3
    @test to(tokens[2]) == 3
    @test SimpleParser.str(tokens[2]) === s1
    @test SimpleParser.subs(tokens[2]) == "\\"

    s2 = "a\\b"
    tokens = tokenize(s2, pats)
    @test length(tokens) == 2
    @test tokens[1].name == :SOS
    @test tokens[2].name == :ESC_CHAR
    @test tokens[2].ss == "\\b"

    s3 = "a\\newcommand{} b"
    tokens = tokenize(s3, pats)
    @test length(tokens) == 2
    @test tokens[2].name == :NEWCOMMAND
    @test tokens[2].ss == "\\newcommand"

    s4 = "a\\com b"
    tokens = tokenize(s4, pats)
    @test length(tokens) == 2
    @test tokens[2].name == :COMMAND
    @test tokens[2].ss == "\\com"

    s5 = "a\\ \\b \\com \\newcommand{} c"
    tokens = tokenize(s5, pats)
    @test length(tokens) == 5
    @test tokens[2].name == :BACKSLASH
    @test tokens[3].name == :ESC_CHAR
    @test tokens[4].name == :COMMAND
    @test tokens[5].name == :NEWCOMMAND

    s6 = "a\\"
    tokens = tokenize(s6, pats)
    @test tokens[2].name == :BACKSLASH

    # NOTE and not newcommand because '{' missing (corner case)
    s7 = "a\\newcommand"
    tokens = tokenize(s7, pats)
    @test tokens[2].name == :COMMAND
end
