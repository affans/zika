using Parameters #module
@with_kw immutable ZikaParameters @deftype Int64
    sim_time = 730       ## time of simulation - 2 years in days
    grid_size_human = 100000
    grid_size_mosq = 500000
    inital_latent = 5    
end



## age distribution discrete
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
    
    AgeMin[1] = 0;
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


## debug
#a = ZikaParameters()