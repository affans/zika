## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
#workspace()
#using Gadfly
#using Plots

using ProgressMeter
using PmapProgressMeter
using DataArrays, DataFrames
using Match
using ParallelDataTransfer
using QuadGK
using Parameters #module
using Distributions
using StatsBase

include("parameters.jl");   ## sets up the parameters
include("functions.jl");
include("entities.jl");   ## sets up functions for human and mosquitos
include("disease.jl");
include("interaction.jl");

function main(cb, simulationnumber::Int64, P::ZikaParameters)   
    
    ##
    if P.transmission == 0.0
      warning("Transmission value is set to zero - no disease will happen")
    end
    
    ## the grids for humans and mosquitos
    humans = Array{Human}(P.grid_size_human)
    mosqs  = Array{Mosq}(P.grid_size_mosq)
    
    ## current season
    current_season = SUMMER   #current season

    ## before running the main setups, make sure distributions are setup, make these variables global
    sdist_lifetimes, wdist_lifetimes = distribution_hazard_function(P)  #summer/winter mosquito lifetimes
    global sdist_lifetimes
    global wdist_lifetimes

    ## data collection arrays
    latent_ctr = zeros(Int64, P.sim_time)
    bite_symp_ctr = zeros(Int64, P.sim_time)
    bite_asymp_ctr = zeros(Int64, P.sim_time)    
    sex_symp_ctr = zeros(Int64, P.sim_time)
    sex_asymp_ctr = zeros(Int64, P.sim_time)
    preg_symp_ctr = zeros(Int64, P.sim_time)
    preg_asymp_ctr = zeros(Int64, P.sim_time)
    micro_ctr = zeros(Int64, P.sim_time)
    vac_gen_ctr = zeros(Int64, P.sim_time)
    vac_pre_ctr = zeros(Int64, P.sim_time)
    testctr = zeros(Int64, P.sim_time)
    
    ## simulation setup functions
    setup_humans(humans)                      ## initializes the empty array
    setup_human_demographics(humans)          ## setup age distribution, male/female 
    setup_preimmunity(humans, P)
    setup_pregnant_women(humans, P)           ## setup pregant women according to distribution
    g, p = setup_vaccination_two(humans, P)       ## setup initial vaccination if coverage is more than 0. (g, p) are the number of people vaccinated (general and pregnant women) - add to the counter at the end
    setup_sexualinteractionthree(humans)      ## setup sexual frequency, and partners
    setup_mosquitos(mosqs, current_season)    ## setup the mosquito array, including bite distribution
    setup_mosquito_random_age(mosqs, P)       ## assign age and age of death to mosquitos
    setup_rand_initial_latent(humans, P)      ## introduce initial latent person
   

    ## the main time loop 
    for t=1:P.sim_time        
        ## every day check for season update
        if mod(t, 182) == 0
            current_season = SEASON(Int(current_season) * -1)
        end

        ## functions to capture zika dynamics
        increase_mosquito_age(mosqs, current_season)
        bite_interaction(humans, mosqs, P)
        sexual_interaction(humans, mosqs, P)
        w = pregnancy_and_vaccination(humans, P) 
        vac_pre_ctr[t] = w   
    
        ## end of day update for humans + data collection
        for i=1:P.grid_size_human    
            increase_timestate(humans[i], P)
            if humans[i].swap != UNDEF ## person is swapping, update proper counters
                if humans[i].swap == LAT 
                  latent_ctr[t] += 1           
                  ## if the human is pregnant, while getting infection, determine risk of microcephaly and increase microcephaly counter
                  if humans[i].ispregnant == true
                    rn = rand()
                    if humans[i].timeinpregnancy <= 97
                      if rn < rand()*(P.micro_trione_max - P.micro_trione_min) + P.micro_trione_min
                        micro_ctr[t] += 1
                      end
                    elseif humans[i].timeinpregnancy > 97 && humans[i].timeinpregnancy <= 270
                      if rn < rand()*(P.micro_tritwo_max - P.micro_tritwo_min) + P.micro_tritwo_min
                        micro_ctr[t] += 1
                      end
                    end
                  end    
                  make_human_latent(humans[i], P)    
                elseif humans[i].swap == SYMP || humans[i].swap == SYMPISO                 
                  ## note: for the initial human latents.. they never get recorded in the latent ctr because their swap is never set to latent
                  ## and also, the initial latent will turn into symp/asymp but indeed they don't get recorded again because their "latentfrom=0" by default. 
                  if humans[i].latentfrom == 1 
                    bite_symp_ctr[max(1, t - humans[i].statetime - 1)] += 1
                  elseif humans[i].latentfrom == 2
                    sex_symp_ctr[max(1, t - humans[i].statetime - 1)] += 1     
                  end       
                  ## count if a women is pregnant and are sympotmatic (only if latentfrom > 0 (= 0 for the initial cases))
                  if humans[i].ispregnant == true && humans[i].timeinpregnancy < 270 && humans[i].latentfrom > 0
                    preg_symp_ctr[max(1, t - humans[i].statetime - 1)]  += 1
                  end

                  
                  if humans[i].swap == SYMP 
                    make_human_symptomatic(humans[i], P)
                  else
                    make_human_sympisolated(humans[i], P)
                  end    
                  
                elseif humans[i].swap == ASYMP      
                  if humans[i].latentfrom == 1 
                    bite_asymp_ctr[max(1, t - humans[i].statetime - 1)] += 1
                  elseif humans[i].latentfrom == 2
                    sex_asymp_ctr[max(1, t - humans[i].statetime - 1)] += 1   
                  end  
                  if humans[i].ispregnant == true && humans[i].timeinpregnancy < 270 && humans[i].latentfrom > 0
                    preg_asymp_ctr[max(1, t - humans[i].statetime - 1)]  += 1
                  end 
                  make_human_asymptomatic(humans[i], P)
                elseif humans[i].swap == REC
                  make_human_recovered(humans[i], P) 
                elseif humans[i].swap == SUSC
                  print("swap set to sus - never happen")
                  assert(1 == 2)
                end 
                humans[i].timeinstate = 0 #reset their time in state
                humans[i].swap = UNDEF #reset their time in state
            end
        end

        ## end of day update for mosquitos
        for i=1:P.grid_size_mosq
            increase_timestate(mosqs[i])
            if mosqs[i].swap != UNDEF 
                if mosqs[i].swap == LAT 
                  make_mosquito_latent(mosqs[i], P)
                elseif mosqs[i].swap == SYMP
                  make_mosquito_symptomatic(mosqs[i])
                end
                mosqs[i].timeinstate = 0
                mosqs[i].swap = UNDEF
            end 
        end
        cb(1) ## increase the progress metre by 1.. callback function
    end ##end of time 

    ## count the number of people vaccinated from the initial setup
    ## we add the original "number" back because we don't wnat to lose the data that happened in the above time loop
    ## ie, we have 50 initial vaccinated (time = 0 really, but we recrod at time=1) + 2 new ones at time = 1.
    vac_gen_ctr[1] = g + vac_gen_ctr[1]
    vac_pre_ctr[1] = p + vac_pre_ctr[1]
 
    
    ## write the filename to disk 
    if P.writerawfiles == 1
      ## filename for the simulation
      fname = string("simulation-",simulationnumber, ".dat")     
      writedlm(fname, [latent_ctr bite_symp_ctr bite_asymp_ctr sex_symp_ctr sex_asymp_ctr preg_symp_ctr preg_asymp_ctr micro_ctr vac_gen_ctr vac_pre_ctr])      
    end
    
    ## return the counters 
    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr, preg_symp_ctr, preg_asymp_ctr, micro_ctr, vac_gen_ctr, vac_pre_ctr
end

function main_calibration(cb, simulationnumber::Int64, P::ZikaParameters)   
    #print("starting calibration $simulationnumber on process $(myid()) \n")    
    params = P  ## store the incoming parameters in a local variable
    ## the grids for humans and mosquitos
    humans = Array{Human}(params.grid_size_human)
    mosqs  = Array{Mosq}(params.grid_size_mosq)

    global calibrated_person = 0
    mosq_latent_ctr = 0
    newmosq_ctr = 0
    
    ## current season
    current_season = SUMMER   #current season

    ## before running the main setups, make sure distributions are setup, make these variables global
    sdist_lifetimes, wdist_lifetimes = distribution_hazard_function(params)  #summer/winter mosquito lifetimes
    global sdist_lifetimes
    global wdist_lifetimes

    ## setup the counters
    global latent_ctr = zeros(Int64, params.sim_time)
    global bite_symp_ctr = zeros(Int64, params.sim_time)
    global bite_asymp_ctr = zeros(Int64, params.sim_time)    
    global sex_symp_ctr = zeros(Int64, params.sim_time)
    global sex_asymp_ctr = zeros(Int64, params.sim_time)

    #global ihts = zeros(Int64, 2) ## two is arbritrary
    #global ihta = zeros(Int64, 2)
       
    setup_humans(humans)              ## initializes the empty array
    setup_human_demographics(humans)  ## setup age distribution, male/female 
    #setup_sexualinteractionthree(humans)   ## setup sexual frequency, and partners
    setup_mosquitos(mosqs, current_season)
    setup_mosquito_random_age(mosqs, params)
    setup_rand_initial_latent(humans, params)    
    calibrated_person = find(x -> x.health == LAT, humans)[1]   
    #return humans[calibrated_person].latentfrom
    for t=1:params.sim_time
        increase_mosquito_age(mosqs, current_season)        
        bite_interaction_calibration(humans, mosqs, params)
        #sexual_interaction(humans, mosqs, params)
        timeinstate_plusplus(humans, mosqs, t, params)
        cb(1) ## increase the progress metre by 1.. callback function
         
    end ##end of time 
    
    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr

end


#  numberofsims = 500
#  @everywhere transmission = 0.0
#  for j=0.43:-0.01:0.40
#     #@broadcast testi = 0.35
#     #sendto(workers(), transmission = 0.625 ) ## 0.1
#     #sendto(workers(), transmission = (0.545 - (j - 1)*0.01) )
#     transmission = j;
#     sendto(workers(), transmission = j)
#     #sendto(workers(), transmission = 0.6237 )
    
  
#     ## setup main variables    
#     @everywhere P = ZikaParameters(sim_time = 100, grid_size_human = 10000, grid_size_mosq = 20000, inital_latent = 1, reduction_factor = 0.9)    ## variables defined outside are not available to the functions. 
    
#     print("parameters: \n $P \n")
#     #results = pmap(x -> main(x, P), 1:numberofsims)      
#     results = pmap((cb, x) -> main_calibration(cb, x, P), Progress(numberofsims*P.sim_time), 1:numberofsims, passcallback=true)
#     ## set up dataframes
#     ldf  = DataFrame(Int64, 0, P.sim_time)
#     adf  = DataFrame(Int64, 0, P.sim_time)
#     sdf  = DataFrame(Int64, 0, P.sim_time)
#     ssdf = DataFrame(Int64, 0, P.sim_time)
#     asdf = DataFrame(Int64, 0, P.sim_time)
    
#     #load up dataframes
#     for i=1:numberofsims
#         push!(ldf, results[i][1])
#         push!(sdf, results[i][2])
#         push!(adf, results[i][3])
#         push!(ssdf,results[i][4])
#         push!(asdf, results[i][5])
#     end        

#     ## for calibration
#     sumss = zeros(Int64, numberofsims)
#     sumsa = zeros(Int64, numberofsims)
#     sumsl = zeros(Int64, numberofsims)

#     l = convert(Matrix, ldf)        
#     s = convert(Matrix, sdf)
#     a=  convert(Matrix, adf)

#     for i=1:numberofsims
#         sumss[i] = sum(s[i, :])
#         sumsa[i] = sum(a[i, :])
#         sumsl[i] = sum(l[i, :])
#     end
#     totalavg_symp = sum(sumss)/numberofsims
#     totalavg_lat = sum(sumsl)/numberofsims
#     # print("averaging on process: $(myid()) \n")
#     # print("transmission: $transmission (or $j) \n")
#     # print("total symptomatics: $(sum(sumss)) \n")
#     # print("\n")
#     print("R0: $totalavg_lat \n")
#     print("\n")
#     # print("\n")
#     resarr = Array{Number}(9)
#     resarr[1] = j
#     resarr[2] = j
#     resarr[3] = P.reduction_factor
#     resarr[4] = numberofsims
#     resarr[5] = sum(sumss)
#     resarr[6] = sum(sumsa)
#     resarr[7] = sum(sumsl)
#     resarr[8] = totalavg_symp
#     resarr[9] = totalavg_lat 
 
