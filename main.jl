## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
workspace()
include("parameters.jl")   ## sets up the parameters
include("entities.jl")     ## sets up functions for human and mosquitos
    

function main()
    
    ## setup main variables    
    P = ZikaParameters(grid_size_human = 50)    ## variables defined outside are not available to the functions. 
    
    ## the grids for humans and mosquitos
    human = Array{Human}(P.grid_size_human)
    mosq  = Array{Mosq}(P.grid_size_mosq)
    
    @time setup_humans(human)
    @time setup_human_demographics(human)          ## setups age distribution, sexual frequency
    @time setup_sexualinteraction(human)
    return human
end