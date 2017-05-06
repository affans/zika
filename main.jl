## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
#workspace()
#using Gadfly
#using Plots
addprocs(60)

using DataArrays, DataFrames
@everywhere using ParallelDataTransfer

@everywhere include("parameters.jl");   ## sets up the parameters
@everywhere include("functions.jl");
@everywhere include("entities.jl");   ## sets up functions for human and mosquitos
@everywhere include("disease.jl");
@everywhere include("interaction.jl");


@everywhere function main(simulationnumber::Int64, P::ZikaParameters)   
    print("starting simulation $simulationnumber \n")
        
    params = P  ## store the incoming parameters in a local variable
    ## the grids for humans and mosquitos
    humans = Array{Human}(params.grid_size_human)
    mosqs  = Array{Mosq}(params.grid_size_mosq)
    
    ## current season
    current_season = SUMMER   #current season

    ## before running the main setups, make sure distributions are setup, make these variables global
    sdist_lifetimes, wdist_lifetimes = distribution_hazard_function(params)  #summer/winter mosquito lifetimes
    global sdist_lifetimes
    global wdist_lifetimes

    
    global latent_ctr = zeros(Int64, params.sim_time)
    global bite_symp_ctr = zeros(Int64, params.sim_time)
    global bite_asymp_ctr = zeros(Int64, params.sim_time)    
    global sex_symp_ctr = zeros(Int64, params.sim_time)
    global sex_asymp_ctr = zeros(Int64, params.sim_time)
    
    setup_humans(humans)              ## initializes the empty array
    setup_human_demographics(humans)  ## setup age distribution, male/female 
    setup_sexualinteractionthree(humans)   ## setup sexual frequency, and partners
    setup_mosquitos(mosqs, current_season)
    setup_mosquito_random_age(mosqs, params)
    setup_rand_initial_latent(humans, params)
    print("setup completed... starting main simulation timeloop \n")
    
    ## run tests at this point to make sure humans and 
    for t=1:params.sim_time
        increase_mosquito_age(mosqs, current_season)
        bite_interaction(humans, mosqs, params)
        sexual_interaction(humans, mosqs, params)
        timeinstate_plusplus(humans, mosqs, t, params)
    end ##end of time 

    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr
end


    

#numsims = 5
##l = convert(Matrix, ldf)
#a = convert(Matrix, sdf)
#b = convert(Matrix, adf)

#

@everywhere function main_calibration(simulationnumber::Int64, P::ZikaParameters)   
    print("starting calibration $simulationnumber on process $(myid()) \n")    
    params = P  ## store the incoming parameters in a local variable
    ## the grids for humans and mosquitos
    humans = Array{Human}(params.grid_size_human)
    mosqs  = Array{Mosq}(params.grid_size_mosq)

    print("transmission prob: \n $(params.prob_infection_MtoH) \n")
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
    
   
    setup_humans(humans)              ## initializes the empty array
    setup_human_demographics(humans)  ## setup age distribution, male/female 
    #setup_sexualinteractionthree(humans)   ## setup sexual frequency, and partners
    setup_mosquitos(mosqs, current_season)
    setup_mosquito_random_age(mosqs, params)
    setup_rand_initial_latent(humans, params)
    
    ##testreturn() no.. returning from a function dosnt end it    
    calibrated_person = find(x -> x.health == LAT, humans)[1]   
    #print("process: $(myid()) the calibrated person index is $calibrated_person \n")
    #print("setup completed... starting main simulation timeloop \n")
    #print("starting main time loop of sim $simulationnumber process: $(myid()) \n")
    for t=1:params.sim_time
        increase_mosquito_age(mosqs, current_season)        
        bite_interaction_calibration(humans, mosqs, params)
        #print("new mosquitos: $newmosq_ctr \n")
        #sexual_interaction(humans, mosqs, params)
        timeinstate_plusplus(humans, mosqs, t, params)
    end ##end of time 
    #print("$latent_ctr \n")
    #fname = string("mainfile-",simulationnumber, ".txt") 
    
    #writedlm(fname, [latent_ctr, bite_symp_ctr, bite_asymp_ctr])
    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr
    #return 2
end

      
numberofsims = 250
@everywhere transmission = 0.0
for j=1:16
    print("--------------------\n")
    #@broadcast testi = 0.35
    sendto(workers(), transmission = (0.65 - (j - 1)*0.01) )
    ## setup main variables    
    @everywhere P = ZikaParameters(sim_time = 100, grid_size_human = 100000, grid_size_mosq = 500000, inital_latent = 1, prob_infection_MtoH = transmission, prob_infection_HtoM = transmission, reduction_factor = 0.1)    ## variables defined outside are not available to the functions. 
    results = pmap(x -> main_calibration(x, P), 1:numberofsims)  
    
    ## set up dataframes
    ldf  = DataFrame(Int64, 0, P.sim_time)
    adf  = DataFrame(Int64, 0, P.sim_time)
    sdf  = DataFrame(Int64, 0, P.sim_time)
    ssdf = DataFrame(Int64, 0, P.sim_time)
    asdf = DataFrame(Int64, 0, P.sim_time)
    
    #load up dataframes
    for i=1:numberofsims
        push!(ldf, results[i][1])
        push!(sdf, results[i][2])
        push!(adf, results[i][3])
        push!(ssdf,results[i][4])
        push!(asdf, results[i][5])
    end        

    ## for calibration
    sumss = zeros(Int64, numberofsims)
    sumsa = zeros(Int64, numberofsims)
    sumsl = zeros(Int64, numberofsims)

    l = convert(Matrix, ldf)        
    s = convert(Matrix, sdf)
    a=  convert(Matrix, adf)

    for i=1:numberofsims
        sumss[i] = sum(s[i, :])
        sumsa[i] = sum(a[i, :])
        sumsl[i] = sum(l[i, :])
    end
    totalavg = sum(sumss)/numberofsims
    print("averaging on process: $(myid()) \n")
    print("transmission: $transmission (or $j) \n")
    print("total symptomatics: $(sum(sumss)) \n")
    print("\n")
    print("R0: $totalavg")
    print("\n")
    resarr = Array{Number}(8)
    resarr[1] = j
    resarr[2] = j
    resarr[3] = P.reduction_factor
    resarr[4] = numberofsims
    resarr[5] = sum(sumss)
    resarr[6] = sum(sumsa)
    resarr[7] = sum(sumsl)
    resarr[8] = totalavg 
    filename = string("file-", j, "-",  transmission, ".txt")
    writedlm(filename, resarr)
end
