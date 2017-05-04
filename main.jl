## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
workspace()
using Gadfly
using DataArrays, DataFrames

include("parameters.jl")   ## sets up the parameters
include("functions.jl")
include("entities.jl")     ## sets up functions for human and mosquitos
include("disease.jl")
include("interaction.jl")


function main()

    ## setup main variables    
    global P = ZikaParameters(sim_time = 731, grid_size_human = 100000, grid_size_mosq = 250000, inital_latent = 10)    ## variables defined outside are not available to the functions. 
    
    ## the grids for humans and mosquitos
    humans = Array{Human}(P.grid_size_human)
    mosqs  = Array{Mosq}(P.grid_size_mosq)
    
    ## current season
    global current_season = SUMMER   #current season

    ## before running the main setups, make sure distributions are setup, make these variables global
    sdist_lifetimes, wdist_lifetimes = distribution_hazard_function()  #summer/winter mosquito lifetimes
    global sdist_lifetimes
    global wdist_lifetimes

    
    global latent_ctr = zeros(Int64, P.sim_time)
    global bite_symp_ctr = zeros(Int64, P.sim_time)
    global bite_asymp_ctr = zeros(Int64, P.sim_time)
    
    global sex_symp_ctr = zeros(Int64, P.sim_time)
    global sex_asymp_ctr = zeros(Int64, P.sim_time)
    
    setup_humans(humans)              ## initializes the empty array
    setup_human_demographics(humans)  ## setup age distribution, male/female 
    setup_sexualinteractionthree(humans)   ## setup sexual frequency, and partners
    setup_mosquitos(mosqs)
    setup_mosquito_random_age(mosqs)
    setup_rand_initial_latent(humans)
    print("setup completed... starting main simulation timeloop \n")
    ## run tests at this point to make sure humans and 
    for t=1:P.sim_time
        ## day is starting, increase age by one of mosquitos
        for i=1:P.grid_size_mosq
            mosqs[i].age += 1
            if mosqs[i].age > mosqs[i].ageofdeath 
                mosqs[i] = create_mosquito()
            end 
        end

        ## go through interactions. 
        bite_interaction(humans, mosqs)
        sexual_interaction(humans, mosqs)

        ## increase timeinstate human
        for i=1:P.grid_size_human
            increase_timestate(humans[i])
            update_human(humans[i], t)
        end

        ## increase timeinstate
        for i=1:P.grid_size_mosq
            increase_timestate(mosqs[i])
            update_mosq(mosqs[i])
        end
    end ##end of time 
    #df[:L] = latent_ctr
    #df[:S] = bite_symp_ctr
    #df[:A] = bite_asymp_ctr
    #df[:SS] = sex_symp_ctr
    #df[:AS] = sex_asymp_ctr
    #return humans, mosqs
    #return df
    return latent_ctr, bite_symp_ctr, bite_asymp_ctr, sex_symp_ctr, sex_asymp_ctr
end

function run_sims()
    ## set up dataframes
    ldf  = DataFrame(Int64, 0, 731)
    adf  = DataFrame(Int64, 0, 731)
    sdf  = DataFrame(Int64, 0, 731)
    ssdf = DataFrame(Int64, 0, 731)
    asdf = DataFrame(Int64, 0, 731)
    for i=1:10
        print("starting simulation $i \n")
        l, s, a, ss, as = main()
        push!(ldf, l)
        push!(sdf, s)
        push!(adf, a)
        push!(ssdf, ss)
        push!(asdf, as)
    end
end

writetable("firstbatch.csv", ldf)