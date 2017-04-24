## Modelling Zika virus through an ABM, developed in Julia
## Affan Shoukat
## this file: main entry file of the simulation
workspace()


function main()
    include("parameters.jl")   ## sets up the parameters
    include("entities.jl")     ## sets up functions for human and mosquitos
    
    ## setup main variables    
    P = ZikaParameters()    ## variables defined outside are not available to the functions. 
    
    ## the grids for humans and mosquitos
    human = Array(Human, P.grid_size_human)
    mosq  = Array(Mosq, P.grid_size_mosq)
       
    setup_humans(human)          ## setups age distribution, sexual frequency
    age_distribution(human)

    return human
end