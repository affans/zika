## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
workspace()
using Gadfly

include("parameters.jl")   ## sets up the parameters
include("functions.jl")
include("entities.jl")     ## sets up functions for human and mosquitos
    

function main()
    
    ## setup main variables    
    global P = ZikaParameters(grid_size_mosq = 50000, summerlifespan_max = 65)    ## variables defined outside are not available to the functions. 
    
    ## the grids for humans and mosquitos
    humans = Array{Human}(P.grid_size_human)
    mosqs  = Array{Mosq}(P.grid_size_mosq)
    
    ## current season
    global current_season = SUMMER   #current season

    ## before running the main setups, make sure distributions are setup.
    sdist_lifetimes, wdist_lifetimes = distribution_hazard_function()  #summer/winter mosquito lifetimes
    global sdist_lifetimes
    global wdist_lifetimes

    @time setup_humans(humans)              ## initializes the empty array
    @time setup_human_demographics(humans)  ## setup age distribution, male/female 
    @time setup_sexualinteraction(humans)   ## setup sexual frequency, and partners
    
    @time setup_mosquitos(mosqs)
   
    return humans, mosqs
end


