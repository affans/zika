## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
#workspace()
#using Gadfly
#using Plots

using ProgressMeter         ## updated for 1.0
using PmapProgressMeter
using DataFrames            ## updated for 1.0
using CSV                   ## updated for 1.0
using Match                 ## dosn't look like it's updated -- remove all instances of code -- submit PR. 
#using ParallelDataTransfer  ## I don't really use this, but 0.7/1.0 shouldn't have affected this. 
using QuadGK                ## updated for 1.0
using Parameters #module    ## updated for 1.0
using Distributions         ## updated for 1.0
using StatsBase             ## updated for 1.0
using JSON                  ## updated for 1.0

include("parameters.jl");   ## sets up the parameters
include("functions.jl");
include("entities.jl");   ## sets up functions for human and mosquitos
include("disease.jl");
include("interaction.jl");

function main(simulationnumber::Int64, P::ZikaParameters; callback::Function = x -> nothing)   
        
    ## simple error checks
    P.transmission == 0.0 && warning("Transmission value is set to zero - no disease will happen");
    !(P.country in countries()) && error("Country not defined for model");

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
    setup_human_demographics(humans, P)          ## setup age distribution, male/female 
    setup_preimmunity(humans, P)
    setup_pregnant_women(humans, P)           ## setup pregant women according to distribution
    g, p = setup_vaccination(humans, P)       ## setup initial vaccination if coverage is more than 0. (g, p) are the number of people vaccinated (general and pregnant women) - add to the counter at the end
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
        callback(1) ## increase the progress metre by 1.. callback function
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


function main_calibration(simulationnumber::Int64, P::ZikaParameters; callback::Function = x->nothing)   
      
    ## simple error checks
    P.transmission == 0.0 && warning("Transmission value is set to zero - no disease will happen")
    !(P.country in countries()) && error("Country not defined for model");
    
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
    
    ## simulation setup functions
    setup_humans(humans)                      ## initializes the empty array
    setup_human_demographics(humans, P)          ## setup age distribution, male/female 
    setup_mosquitos(mosqs, current_season)    ## setup the mosquito array, including bite distribution
    setup_mosquito_random_age(mosqs, P)       ## assign age and age of death to mosquitos
    setup_rand_initial_latent(humans, P)      ## introduce initial latent person
    
    ## calibration parameters/variables
    calibrated_person = 0
    mosq_latent_ctr = 0
    newmosq_ctr = 0
    calibrated_person = find(x -> x.health == LAT, humans)[1]   
    
    ## the main time loop 
    for t=1:P.sim_time        
        
        ## functions to capture zika dynamics
        increase_mosquito_age(mosqs, current_season)
        bite_interaction_calibration(humans, mosqs, P, calibrated_person)

        ## end of day update for humans + data collection
        for i=1:P.grid_size_human    
            increase_timestate(humans[i], P)
            if humans[i].swap != UNDEF ## person is swapping, update proper counters
                if humans[i].swap == LAT 
                  latent_ctr[t] += 1           
                  make_human_latent(humans[i], P)    
                elseif humans[i].swap == SYMP || humans[i].swap == SYMPISO                ## note: for the initial human latents.. they never get recorded in the latent ctr because their swap is never set to latent
                  ## and also, the initial latent will turn into symp/asymp but indeed they don't get recorded again because their "latentfrom=0" by default. 
                  if humans[i].latentfrom == 1 
                    bite_symp_ctr[max(1, t - humans[i].statetime - 1)] += 1
                  elseif humans[i].latentfrom == 2
                    sex_symp_ctr[max(1, t - humans[i].statetime - 1)] += 1     
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
        callback(1) ## increase the progress metre by 1.. callback function
    end ##end of time 
    
    ## return the counters 
    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr
end

function setup_filestructure(P)
  ## using the parameters create directories  
  cn = "$(P.country)"
  asymp = "Asymp$(Int(P.reduction_factor*100))" 
  iso = "Iso$(Int(P.ProbIsolationSymptomatic*100))"
  cov = "Coverage$(Int(P.coverage_general*100))$(Int(P.coverage_pregnant*100))"
  pre = P.preimmunity > 0 ? "Pre1" : "Pre0"
  trans = replace(string(P.transmission), "." => "-")
  return string(cn, "/", asymp, iso, "_", cov, pre, "_", trans)
end

function dataprocess(results, numofsims, P)
  dirname = setup_filestructure(P)
  mkpath(dirname)
  
  #numofdays = 182*2
  #numofsims = 2000
  #create empty matrices
  lm = Matrix{Int64}(numofsims, P.sim_time)
  bsm = Matrix{Int64}(numofsims, P.sim_time)
  bam = Matrix{Int64}(numofsims, P.sim_time)
  ssm = Matrix{Int64}(numofsims, P.sim_time)
  sam = Matrix{Int64}(numofsims, P.sim_time)
  
  ps = Matrix{Int64}(numofsims, P.sim_time)
  pa = Matrix{Int64}(numofsims, P.sim_time)
  mic = Matrix{Int64}(numofsims, P.sim_time)
  vgen = Matrix{Int64}(numofsims, P.sim_time)
  vpre = Matrix{Int64}(numofsims, P.sim_time)
  rec = Matrix{Int64}(numofsims, P.sim_time)
    
  # read each file
  for i = 1:numofsims
      lm[i, :] = results[i][1] 
      bsm[i, :] = results[i][2] 
      bam[i, :] = results[i][3] 
      ssm[i, :] = results[i][4] 
      sam[i, :] = results[i][5] 
      ps[i, :] = results[i][6] 
      pa[i, :] = results[i][7]
      mic[i, :] = results[i][8] 
      vgen[i, :] = results[i][9] 
      vpre[i, :] = results[i][10]       
      #rec[i, :] = results[i][11] 
      
  end   

  writedlm(string(dirname, "/latent.dat"), lm)
  writedlm(string(dirname, "/bitesymp.dat"), bsm)
  writedlm(string(dirname, "/biteasymp.dat"), bam)
  writedlm(string(dirname, "/sexsymp.dat"), ssm)
  writedlm(string(dirname, "/sexasymp.dat"), sam)
  writedlm(string(dirname, "/pregsymp.dat"), ps)
  writedlm(string(dirname, "/pregasymp.dat"), pa)
  writedlm(string(dirname, "/micro.dat"), mic)
  writedlm(string(dirname, "/vacgeneral.dat"), vgen)
  writedlm(string(dirname, "/vacpregnant.dat"), vpre)    
  #writedlm(string(dirname, "/recovered.dat"), rec)      
end

function run(P, numberofsims) 
  # cb is the callback function. It updates the progress bar
  info("Parameters: \n $P \n")  ## prints to STDOUT - redirect to logfile
  info("directory name: $(setup_filestructure(P))")  
  info("starting pmap...\n")
  results = pmap((cb, x) -> main(x, P, callback=cb), Progress(numberofsims*P.sim_time), 1:numberofsims, passcallback=true)      
  dataprocess(results, numberofsims, P)
end
