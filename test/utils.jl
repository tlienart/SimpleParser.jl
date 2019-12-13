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
