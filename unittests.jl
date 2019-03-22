## to add.
using Test
using Random
include("main.jl")
@testset "System Setup" begin
    Random.seed!(993)
    P = ZikaParameters();
    h = Array{Human}(undef, P.grid_size_human);
    setup_humans(h);
    setup_human_demographics(h, P);
    
    _t1 = findall(x -> x.age < 0, h)
    _t2 = findall(x -> (x.gender != MALE && x.gender != FEMALE), h)
    @test length(_t1) == 0
    @test length(_t2) == 0

    _ctr1 = setup_preimmunity(h, ZikaParameters(preimmunity=0))
    _ctr2 = setup_preimmunity(h, ZikaParameters(preimmunity=1))
    @test _ctr1 == 0
    @test _ctr2 == 10000

    # scenario: testing pregnant setup
    _t1 = sum(setup_pregnant_women(h, P)) ## get total number of preg women  
    _t2 = length(filter(x -> x.ispregnant == true, h))
    @test _t1 == _t2

    ## scenario testing initial latent
    _t1 = setup_rand_initial_latent(h, P)    
    _t2 = length(findall(x -> x.health == LAT, h))
    @test _t1 == P.inital_latent
    @test _t2 == _t1     

    ## scenario: preexisting immunity
    Random.seed!(993)
    P = ZikaParameters(preimmunity = 0.08)
    h = Array{Human}(P.grid_size_human)
    setup_humans(h)                      ## initializes the empty array
    setup_preimmunity(h , P)
    @test length(findall(x -> x.protectionlvl == 1.0, h)) > 0
end

@testset "Vaccination" begin
    Random.seed!(993)
    P = ZikaParameters(coverage_general = 0.10, coverage_pregnant = 0.80, coverage_reproductionAge =  0.60)
    h = Array{Human}(undef, P.grid_size_human);
    setup_humans(h);
    setup_human_demographics(h, P);    
    setup_preimmunity(h, P)
    setup_pregnant_women(h, P)
    g, p = setup_vaccination(h, P)    
    @test g == 2094  ## hard coded because of seed fix. 
    @test p == 91
    _t2 = length(filter(x -> x.gender == FEMALE && x.ispregnant == true, h)) ## pregnant women       
    _t3 = round(100*p/_t2; digits=2)  ## get percentage of vaccinated pregnant women
    @test _t3 == 74.59
end

@testset "Sexual Interaction Setup" begin
    Random.seed!(993)
    P = ZikaParameters(coverage_general = 0.10, coverage_pregnant = 0.80, coverage_reproductionAge =  0.60)
    h = Array{Human}(undef, P.grid_size_human);
    setup_humans(h);
    setup_human_demographics(h, P);    
    s = setup_sexualinteractionthree(h)

    _t1 = length(filter(x -> x.partner > 0, h)) ## this will be twice the size cuz males get paired with females
    _t2 = length(filter(x -> x.partner > 0 && x.gender == MALE, h)) ## this will be twice the size cuz males get paired with females
    _t3 = length(filter(x -> x.partner > 0 && x.gender == FEMALE, h)) ## this will be twice the size cuz males get paired with females
    @test _t1÷2 == 3554 
    @test _t2 == _t3
    @test _t2 == length(s) 
    @test _t3 == length(s)
    @test length(filter(i -> h[i].partner > 0, s)) == 3554 ## check if everyone from "s" has a partner. 
end

@testset "Mosq Setup" begin
  ## current season
  current_season = SUMMER   #current season
  Random.seed!(993)
  ## before running the main setups, make sure distributions are setup, make these variables global
  sdist_lifetimes, wdist_lifetimes = distribution_hazard_function(P)  #summer/winter mosquito lifetimes
  m = create_mosquito(current_season)
  @test m.statetime == 999
  @test m.timeinstate == 0
  @test m.infectionfrom == 0
  @test m.numberofbites == 7
  @test sum(m.bitedistribution) == m.numberofbites

  Random.seed!(993)
  mosqs  = Array{Mosq}(undef, P.grid_size_mosq)
  setup_mosquitos(mosqs, current_season)    ## setup the mosquito array, including bite distribution
  setup_mosquito_random_age(mosqs, P)       ## assign age and age of death to mosquitos
  _t1 = length(filter(x -> x.age > 0, mosqs))
  @test _t1 == length(mosqs)
end

@testset "Daily functions (Preg)" begin
    Random.seed!(993)
    P = ZikaParameters(coverage_pregnant = 1) ## no coverage for anyone else, only preg women.
    h = Array{Human}(undef, P.grid_size_human);
    setup_humans(h);
    setup_human_demographics(h, P);
    setup_preimmunity(h, P)
    n = setup_pregnant_women(h, P)
    gv, pv = setup_vaccination(h, P)   

    p = findall(x -> x.ispregnant == true, h)
    v = findall(x -> x.isvaccinated == true, h)
    ## force a pregnancy_and_vaccination
    h[p[1]].timeinpregnancy = 269
    pregnancy_and_vaccination(h, P) ## should have an extra pregnant woman (and should be vaccinated)
    _t1 = findall(x -> x.ispregnant == true, h)
    _t2 = findall(x -> x.isvaccinated == true, h)
    @test p == v
    @test length(_t1) == length(p) + 1
    @test length(_t2) == length(v) + 1
end


@testset "Disease functions" begin
    Random.seed!(993)
    P = ZikaParameters(coverage_pregnant = 1) ## no coverage for anyone else, only preg women.
    h = Array{Human}(undef, P.grid_size_human);
    setup_humans(h);
    setup_human_demographics(h, P);
    setup_preimmunity(h, P)
    _t1 = setup_rand_initial_latent(h, P)    
    i = findfirst(x -> x.health == LAT, h)
    @test h[i].timeinstate == 0 
    @test h[i].statetime > 3
    @test h[i].statetime <= P.h_latency_max
    h[i].timeinstate = h[i].statetime ## so that he moves next step.
    h[i].protectionlvl = 1 ## should force to asymptomatic
    increase_timestate(h[i], P)
    make_human_asymptomatic(h[i], P)
    @test h[i].health == ASYMP    
    @test h[i].statetime <= P.h_symptomatic_max

end