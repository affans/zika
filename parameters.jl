using Parameters #module
using Distributions
using StatsBase

## MAIN SYSTEM PARAMETER
@with_kw immutable ZikaParameters @deftype Int64
    # general parameters
    sim_time = 730       ## time of simulation - 2 years in days
    grid_size_human = 100000
    grid_size_mosq = 500000
    inital_latent = 5    
    # mosquito parameters
    winterlifespan_max = 30
    winterlifespan_min = 0
    summerlifespan_max = 60
    summerlifespan_min = 0 

    # mosquito hazard function parameters
    aSummer::Float64 = 0.0018;
    bSummer::Float64 = 0.3228;
    sSummer::Float64 = 2.1460;
    aWinter::Float64 = 0.0018;
    bWinter::Float64 = 0.8496;
    sWinter::Float64 = 4.2920;
end

## Enums
@enum HEALTH SUSC=1 LAT=2 ASYMP=3 SYMP=4 SYMPISO=5 REC=6 DEAD=7 UNDEF=0
@enum GENDER MALE=1 FEMALE=2
@enum SEASON SUMMER=1 WINTER=2



## age distribution discrete for humans
function distribution_age()
    ProbBirthAge = Vector{Float64}(19)
    SumProbBirthAge = Vector{Float64}(19)
    AgeMin = Vector{Int64}(19)
    AgeMax = Vector{Int64}(19)

    ProbBirthAge[1]  = 9.12e-2; # 0–4 years
    ProbBirthAge[2]  = 9.05e-2; #// 5–9 years
    ProbBirthAge[3]  = 9.18e-2; #// 10–14
    ProbBirthAge[4]  = 9.31e-2; #// 15–19
    ProbBirthAge[5]  = 8.96e-2; #// 20–24
    ProbBirthAge[6]  = 8.10e-2 + 0.0865; #// 30–34  add to add to one. 
    ProbBirthAge[8]  = 6.52e-2; #// 35–39
    ProbBirthAge[9]  = 6.11e-2; #// 40–44
    ProbBirthAge[10] = 6.07e-2; #// 45–49
    ProbBirthAge[11] = 5.40e-2; #// 50–54
    ProbBirthAge[12] = 4.35e-2; #// 55–59
    ProbBirthAge[13] = 3.38e-2; #// 60–64
    ProbBirthAge[14] = 2.53e-2; #// 65–69
    ProbBirthAge[15] = 1.84e-2; #// 70–74
    ProbBirthAge[16] = 1.40e-2; ##// 80–84
    ProbBirthAge[18] = 0.02e-2; #// 85–89
    ProbBirthAge[19] = 0.01e-2; #// 90+

    for i=1:19
        SumProbBirthAge[i] = sum(ProbBirthAge[1:i])
    end
    
    AgeMin[1] = 1;
    AgeMax[1] = 4;

    AgeMin[2] = 5;
    AgeMax[2] = 9;

    AgeMin[3] = 10;
    AgeMax[3] = 14;

    AgeMin[4] = 15;
    AgeMax[4] = 19;

    AgeMin[5] = 20;
    AgeMax[5] = 24;

    AgeMin[6] = 25;
    AgeMax[6] = 29;

    AgeMin[7] = 30;
    AgeMax[7] = 34;

    AgeMin[8] = 35;
    AgeMax[8] = 39;

    AgeMin[9] = 40;
    AgeMax[9] = 44;

    AgeMin[10] = 45;
    AgeMax[10] = 49;

    AgeMin[11] = 50;
    AgeMax[11] = 54;

    AgeMin[12] = 55;
    AgeMax[12] = 59;

    AgeMin[13] = 60;
    AgeMax[13] = 64;

    AgeMin[14] = 65;
    AgeMax[14] = 69;

    AgeMin[15] = 70;
    AgeMax[15] = 74;

    AgeMin[16] = 75;
    AgeMax[16] = 79;

    AgeMin[17] = 80;
    AgeMax[17] = 84;

    AgeMin[18] = 85;
    AgeMax[18] = 89;

    AgeMin[19] = 90;
    AgeMax[19] = 100;

    return SumProbBirthAge, AgeMin, AgeMax
end

## random gender male/female distribution
function distribution_gender()
    ProbMale = Array{Float64}(100)
    ProbMale[1]  = ProbMale[2]  = ProbMale[3]  = ProbMale[4]  = 0.5115895;
    ProbMale[5]  = ProbMale[6]  = ProbMale[7]  = ProbMale[8]  = ProbMale[9]  = 0.5111110;
    ProbMale[10] = ProbMale[11] = ProbMale[12] = ProbMale[13] = ProbMale[14] = 0.5105338;
    ProbMale[15] = ProbMale[16] = ProbMale[17] = ProbMale[18] = ProbMale[19] = 0.5115023;
    ProbMale[20] = ProbMale[21] = ProbMale[22] = ProbMale[23] = ProbMale[24] = 0.5117474;
    ProbMale[25] = ProbMale[26] = ProbMale[27] = ProbMale[28] = ProbMale[29] = 0.5013474;
    ProbMale[30] = ProbMale[31] = ProbMale[32] = ProbMale[33] = ProbMale[34] = 0.4878720;
    ProbMale[35] = ProbMale[36] = ProbMale[37] = ProbMale[38] = ProbMale[39] = 0.4848614;
    ProbMale[40] = ProbMale[41] = ProbMale[42] = ProbMale[43] = ProbMale[44] = 0.4797498;
    ProbMale[45] = ProbMale[46] = ProbMale[47] = ProbMale[48] = ProbMale[49] = 0.4773869;
    ProbMale[50] = ProbMale[51] = ProbMale[52] = ProbMale[53] = ProbMale[54] = 0.4758785;
    ProbMale[55] = ProbMale[56] = ProbMale[57] = ProbMale[58] = ProbMale[59] = 0.4732524;
    ProbMale[60] = ProbMale[61] = ProbMale[62] = ProbMale[63] = ProbMale[64] = 0.4727012;
    ProbMale[65] = ProbMale[66] = ProbMale[67] = ProbMale[68] = ProbMale[69] = 0.4678313;
    ProbMale[70] = ProbMale[71] = ProbMale[72] = ProbMale[73] = ProbMale[74] = 0.4555384;
    ProbMale[75] = ProbMale[76] = ProbMale[77] = ProbMale[78] = ProbMale[79] = 0.4356684;
    ProbMale[80] = ProbMale[81] = ProbMale[82] = ProbMale[83] = ProbMale[84] = 0.4164767;
    ProbMale[85:end] = 0.0
    return ProbMale
end

## male/female sexual frequency
function distribution_sexfrequency()
    dist_men = [    [0.167, 0.334, 0.563, 0.792, 0.896, 1],     # 15 - 24    
                    [0.109,	0.572,	0.7575,	0.943,	0.9725,	1], # 25 - 29                   
                    [0.201,	0.674,	0.808,	0.942,	0.971,	1], # 30 - 39
                    [0.254,	0.764,	0.8635,	0.963,	0.9815,	1], # 40 - 49                   
                    [0.456,	0.839,	0.914,	0.989,	0.9945,	1], # 50 - 55  
                    [0.551, 0.905, 0.9525, 1, 1, 1],            # 60 - 69
                    [0.784, 0.934, 0.963, 0.992, 0.996, 1]]         # 70+                     
    dist_women = [  [0.265,	0.412,	0.5885,	0.765,	0.8825,	1],     # 15 - 24    
                    [0.151,	0.628,	0.804,	0.98,	0.99,	1], # 25 - 29                   
                    [0.228,	0.73,	0.8395,	0.949,	0.9745,	1], # 30 - 39
                    [0.298,	0.764,	0.868,	0.972,	0.9855,	1], # 40 - 49                   
                    [0.457,	0.819,	0.9035,	0.988,	0.9935,	1], # 50 - 59
                    [0.579,	0.938,	0.969,	1,	1,	1],            # 60 - 69
                    [0.789,	0.972,	0.979,	0.986,	0.993,	1]]         # 70+ 
    ## return distribution as tuple
  
    # since this is manually input, check if the length of all the inner vectors are the same
    #map(x -> length(x), wfd)√
    return dist_men, dist_women
end

## the hazard function for mosquito age death, returns both winter and summer distributions
function distribution_hazard_function()
    
    
    ## parameters for the hazard distribution passed in through the global P variable   
    ## store them in local variables   
    summerlifespan = P.summerlifespan_max
    winterlifespan = P.winterlifespan_max
    
    
    summer_hazard = zeros(summerlifespan)
    summer_hazard_cum = zeros(summerlifespan)
    summer_SurS = zeros(summerlifespan)
    summer_PDFS = zeros(summerlifespan)
    winter_hazard = zeros(winterlifespan)
    winter_hazard_cum = zeros(winterlifespan)
    winter_SurS = zeros(winterlifespan)
    winter_PDFS = zeros(winterlifespan)

    KS = zeros(summerlifespan)
    KW = zeros(winterlifespan)

    ## hazard functions
    hazard_summer(t) = P.aSummer*exp(P.bSummer*(t-1))/(1+P.aSummer*P.sSummer*(exp(P.bSummer*(t-1))-1)/P.bSummer)
    hazard_winter(t) = P.aWinter*exp(P.bWinter*(t-1))/(1+P.aWinter*P.sWinter*(exp(P.bWinter*(t-1))-1)/P.bWinter);
    for t=1:summerlifespan
        KS[t], E = quadgk(hazard_summer, 0, t)   ## returns a tuple, E is the error
        summer_SurS[t] = exp(-KS[t])
        summer_PDFS[t] = hazard_summer(t)*summer_SurS[t]            
    end
    for t=1:winterlifespan
        KW[t], E = quadgk(hazard_winter, 0, t)   ## returns a tuple, E is the error
        winter_SurS[t] = exp(-KW[t])
        winter_PDFS[t] = hazard_winter(t)*winter_SurS[t]
    end
 
    ## get the cumlative and..
    ## make them add to one since the integration is done numerically, and we might be off by 0.001 or so
    sc = cumsum(summer_PDFS)
    sw = cumsum(winter_PDFS)
    sc[end] = 1
    sw[end] = 1
    
    ## RETURNS THE DISTRIBUTION BASED ON THE SEASON
    return sc, sw
end
