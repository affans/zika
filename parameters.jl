## Enums
@enum HEALTH SUSC=1 LAT=2 ASYMP=3 SYMP=4 SYMPISO=5 REC=6 DEAD=7 UNDEF=0
@enum GENDER MALE=1 FEMALE=2
@enum SEASON SUMMER=1 WINTER=-1


## MAIN SYSTEM PARAMETER
@with_kw immutable ZikaParameters @deftype Int64
    # general parameters
    sim_time = 364       ## time of simulation - 2 years in days
    grid_size_human = 10000
    grid_size_mosq = 50000
    inital_latent = 1 
    writerawfiles = 0  ## 0 for no, 1 for yes. if 1, main() writes simulation-i.dat
    country::String = "Argentina"

    # mosquito lifetime parameters
    winterlifespan_max = 30
    winterlifespan_min = 1
    summerlifespan_max = 60
    summerlifespan_min = 1 

    # mosquito hazard function parameters
    aSummer::Float64 = 0.0018;
    bSummer::Float64 = 0.3228;
    sSummer::Float64 = 2.1460;
    aWinter::Float64 = 0.0018;
    bWinter::Float64 = 0.8496;
    sWinter::Float64 = 4.2920;

    # disease dynamics- human and mosquitos
    h_latency_max = 8   
    h_latency_min = 4
    m_latency_max = 14
    m_latency_min = 7
    h_symptomatic_max = 6
    h_symptomatic_min = 3

    ## 40 - 80% probability of going to asymptomatic
    ProbLatentToASymptomaticMax::Float64 = 0.8
    ProbLatentToASymptomaticMin::Float64 = 0.4

    ## mosquito lifespan distribution parameters
    m_lognormal_latent_shape::Float64 = 2.28  ## mean 10
    m_lognormal_latent_scale::Float64 = 0.21 
    h_lognormal_latent_shape::Float64 = 1.72 ## mean 5.7
    h_lognormal_latent_scale::Float64 = 0.21 
    h_lognormal_symptomatic_shape::Float64 = 1.54  ## mean 4.7
    h_lognormal_symptomatic_scale::Float64 = 0.12     

    ##transmission probabilities -- don't really need two parameters    
    #prob_infection_MtoH::Float64 = 0.352
    #prob_infection_HtoM::Float64 = 0.352
    transmission::Float64 = 0.0
    ProbIsolationSymptomatic::Float64 = 0  ## if symptomatic, what is probability of isolation
    reduction_factor::Float64 = 0.1        ## asymptomatic reduction_factor?

    ## sexual interaction specific
    condom_reduction::Float64 = 0.0

    ## pregnancy 
    preg_percentage::Float64 = 0.05 # 5% of all eligible women (Gender=woman, 15<age<49)

    ## microcephaly risk - CDC / NEJM / Honein 2017 
    ## honein reports 4-6% for second trimester, 3-6% for third. 
    ## we calculated CDC secdond/third to be 4%
    ## to be consistent, we use 3-5% for risk of micro after 180 days in pregnancy
    # https://www.cdc.gov/mmwr/volumes/66/wr/mm6613e1.htm
    micro_trione_min::Float64 = 0.05  #0.0034
    micro_trione_max::Float64 = 0.14  ##0.019

    ##trimester two here refers to second/third trimester together
    micro_tritwo_min::Float64 = 0.03 #0.0028
    micro_tritwo_max::Float64 = 0.05 #0.0132

    ## vaccine parameters    
    coverage_general::Float64 = 0.0 # 0.10
    coverage_pregnant::Float64 = 0.0 #0.80
    coverage_reproductionAge::Float64 = 0.6 #0.6
    efficacy_min::Float64 = 0.60
    efficacy_max::Float64 = 0.90

    ## preexisting immunity 
    preimmunity::Float64 = 0.08  ## coverage of preimmunity
    preimmunity_protectionlvl::Float64 = 1.0
end



function age_distribution()
    a = JSON.parsefile("country_data.json", dicttype=Dict,  use_mmap=true)
    md = Dict{String, Array{Float64}}()
    fd = Dict{String, Array{Float64}}()
    for (i, d) in enumerate(a)        
        md["$(d["name"])"] = cumsum(convert(Array{Float64}, d["data"]["maleage"]))
        fd["$(d["name"])"] = cumsum(convert(Array{Float64}, d["data"]["femaleage"]))
        md["$(d["name"])"][end] = 1.0
        fd["$(d["name"])"][end] = 1.0
    end
    return md, fd
end


function fertility_distribution()
    a = JSON.parsefile("country_data.json", dicttype=Dict,  use_mmap=true)
    fd = Dict{String, Array{Float64}}()
    for (n, d) in enumerate(a)
        fd["$(d["name"])"] = d["data"]["fertility"]*0.75/1000       
    end
    return fd
end


function age_brackets() 
    AgeMin = Vector{Int64}(17)
    AgeMax = Vector{Int64}(17)

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
    AgeMax[15] = 100;

    return AgeMin, AgeMax
end


## male/female sexual frequency
function distribution_sexfrequency()
    dist_men = [    [0.167, 0.334, 0.563, 0.792, 0.896, 1],     # 15 - 24    
                    [0.109, 0.572, 0.7575, 0.943, 0.9725, 1], # 25 - 29                   
                    [0.201, 0.674, 0.808, 0.942, 0.971, 1], # 30 - 39
                    [0.254, 0.764, 0.8635, 0.963, 0.9815, 1], # 40 - 49                   
                    [0.456, 0.839, 0.914, 0.989, 0.9945, 1], # 50 - 55  
                    [0.551, 0.905, 0.9525, 1, 1, 1],            # 60 - 69
                    [0.784, 0.934, 0.963, 0.992, 0.996, 1]]         # 70+                     
    dist_women = [  [0.265, 0.412, 0.5885, 0.765, 0.8825, 1],     # 15 - 24    
                    [0.151, 0.628, 0.804, 0.98, 0.99, 1], # 25 - 29                   
                    [0.228, 0.73, 0.8395, 0.949, 0.9745, 1], # 30 - 39
                    [0.298, 0.764, 0.868, 0.972, 0.9855, 1], # 40 - 49                   
                    [0.457, 0.819, 0.9035, 0.988, 0.9935, 1], # 50 - 59
                    [0.579, 0.938, 0.969, 1, 1, 1],            # 60 - 69
                    [0.789, 0.972, 0.979, 0.986, 0.993, 1]]         # 70+ 
    ## return distribution as tuple
  
    # since this is manually input, check if the length of all the inner vectors are the same
    #map(x -> length(x), wfd)√
    return dist_men, dist_women
end

## the hazard function for mosquito age death, returns both winter and summer distributions
function distribution_hazard_function(P::ZikaParameters)
    
    
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
        @inbounds KS[t], E = QuadGK.quadgk(hazard_summer, 0, t)   ## returns a tuple, E is the error
        @inbounds summer_SurS[t] = exp(-KS[t])
        @inbounds summer_PDFS[t] = hazard_summer(t)*summer_SurS[t]            
    end
    for t=1:winterlifespan
        @inbounds KW[t], E = QuadGK.quadgk(hazard_winter, 0, t)   ## returns a tuple, E is the error
        @inbounds winter_SurS[t] = exp(-KW[t])
        @inbounds winter_PDFS[t] = hazard_winter(t)*winter_SurS[t]
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
