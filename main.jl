## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
workspace()
include("parameters.jl")   ## sets up the parameters
include("functions.jl")
include("entities.jl")     ## sets up functions for human and mosquitos
    

function main()
    
    ## setup main variables    
    global P = ZikaParameters()    ## variables defined outside are not available to the functions. 
    
    ## the grids for humans and mosquitos
    humans = Array{Human}(P.grid_size_human)
    mosqs  = Array{Mosq}(P.grid_size_mosq)
    
    ## current season
    current_season = SUMMER

    @time setup_humans(humans)              ## initializes the empty array
    @time setup_human_demographics(humans)  ## setup age distribution, male/female 
    @time setup_sexualinteraction(humans)   ## setup sexual frequency, and partners
    @time setup_mosquitos(mosqs)
   
    return humans, mosqs
end

