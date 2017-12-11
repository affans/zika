
using DataArrays, DataFrames
using ProgressMeter
using PmapProgressMeter
using ParallelDataTransfer
using Match 

include("parameters.jl");   ## sets up the parameters
include("functions.jl");
include("entities.jl");   ## sets up functions for human and mosquitos
include("disease.jl");
include("interaction.jl");

P = ZikaParameters()
humans = Array{Human}(P.grid_size_human)
mosqs  = Array{Mosq}(P.grid_size_mosq)

## current season
current_season = SUMMER   #current season


setup_humans(humans)                      ## initializes the empty array
setup_human_demographics(humans)          ## setup age distribution, male/female 
setup_pregnant_women(humans, P)


setup_sexualinteractionthree(humans)      ## setup sexual frequency, and partners
setup_mosquitos(mosqs, current_season)    ## setup the mosquito array, including bite distribution
setup_mosquito_random_age(mosqs, P)  ## assign age and age of death to mosquitos
setup_rand_initial_latent(humans, P) ## introduce initial latent person


for t=1:P.sim_time
    if mod(t, 182) == 0
        current_season = SEASON(Int(current_season) * -1)
    end 
    increase_mosquito_age(mosqs, current_season)
    bite_interaction(humans, mosqs, P)
    sexual_interaction(humans, mosqs, P)
    timeinstate_plusplus(humans, mosqs, t, P)
    baby_born(humans, P)
    cb(1) ## increase the progress metre by 1.. callback function
end ##end of time 

a = find(x-> x.gender == FEMALE && x.age >= 15 && x.age <= 49 && x.ispregnant == true, humans)

humans[10].timeinpregnancy = 268
baby_born(humans, P)
print(humans[10].timeinpregnancy)



find(x-> x.gender == FEMALE && x.age <= 49 && x.age >= 15 && x.ispregnant== true && x.isvaccinated==true, humans)

find(x -> x.isvaccinated == true, humans)