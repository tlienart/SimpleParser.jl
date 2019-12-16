@testset "(super)block" begin
    pats = Dict(
        '\\' => [
            TokenPattern{1}(:BACKSLASH, r_empty, [' ', '\0']),
            TokenPattern{2}(:ESC_CHAR,  r_empty),
            TokenPattern(:NEWCOMMAND, raw"\newcommand", ['{']),
            TokenPattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
            ],
        )

    s1 = "a \\ b"
    tokens = tokenize(s1, pats)

    block = Block(tokens[2])
    @test from(block) == 3
    @test to(block) == 3
    @test content(block) == ""
    @test SimpleParser.str(block) === s1

    s2 = "a \\e\\e b"
    tokens = tokenize(s2, pats)

    block1 = Block(tokens[2])
    block2 = Block(tokens[3])
    sblock = SuperBlock(:EE, block1, block2)
    @test content(sblock) == ["", ""]
    @test sblock[1] === block1
    @test sblock[2] === block2
end
