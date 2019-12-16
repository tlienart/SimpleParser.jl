@testset "next_char" begin
    a = "Blah jμΛIα etc"
    @test next_char(a, 0) == (char='B', pos=1, eos=false)
    @test next_char(a, lastindex(a)) == (char='\0', pos=0, eos=true)
    @test next_char(a, 7) == (char='Λ', pos=9, eos=false)
    @test next_char(a, 9) == (char='I', pos=11, eos=false)

    b = SubString(a, 6, 12)
    @test next_char(b, 0) == (char='j', pos=1, eos=false)
    @test next_char(b, lastindex(b)) == (char='\0', pos=0, eos=true)
    @test next_char(b, 2) == (char='Λ', pos=4, eos=false)
end

@testset "subs,str" begin
    S = SimpleParser
    s = "hello abc"
    @test S.subs(s, 1) == "h"
    @test S.subs(s, 1:2) == "he"
    @test S.subs(s, 1, 5) == "hello"
    @test S.subs(s) == s
    @test S.subs(s) !== s

    ss = S.subs(s)
    @test ss isa SubString

    @test S.str(ss) === s
    @test S.str(s) === s

    ss = S.subs(s, 5:7)
    @test from(ss) == 5
    @test to(ss) == 7
end
