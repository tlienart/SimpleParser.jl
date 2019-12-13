@testset "Pattern" begin
    p1 = Pattern{1}(:BACKSLASH, r_empty, [' '])
    @test p1.name == :BACKSLASH
    @test p1.rule === r_empty
    @test p1.rule('a')
    @test p1.followed_by == [' ']
    @test p1.not_followed_by == Char[]

    p2 = Pattern(:NEWCOMMAND, raw"\newcommand", ['{'])
    len = length("\\newcommand")
    @test typeof(p2) == Pattern{len}
    @test p2.rule === r_string(raw"\newcommand")
    @test p2.rule(raw"\newcommand")
    @test p2.followed_by == ['{']

    p3 = Pattern{0}(:COMMAND, (p, s) -> gr_isletter(p, s, extras=['_']))
    @test p3.rule(raw"\comm_a", 1) == 6
    @test p3.rule(raw"\_b", 1) == 0
end

@testset "gr_isletter" begin
    r = (p, s) -> gr_isletter(p, s; extras=['_'], allow_extra_first=false)
    a = "\\blah"
    @test r(a, 1) == length("blah")
    b = "\\blah_hello"
    @test r(b, 1) == length("blah_hello")
    c = "blah \\blah etc"
    @test r(c, 6) == length("blah")
    d = "\\_hello"
    @test r(d, 1) == 0
end
