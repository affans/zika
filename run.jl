using DataFrames            ## updated for 1.0
using CSV                   ## updated for 1.0
using Match                 ## updated for 1.0
using QuadGK                ## updated for 1.0
using Parameters #module    ## updated for 1.0
using Distributions         ## updated for 1.rm 0
using StatsBase             ## updated for 1.0
using JSON                  ## updated for 1.0
using Random
using DelimitedFiles
using Distributed
using Base.Filesystem
using Statistics
using ClusterManagers
using Dates

addprocs(SlurmManager(544), partition="defq", N=17)
println("added $(nworkers()) processors")
include("main.jl")
@everywhere include("main.jl")


##### MAIN CODE

## example for colobia
## for 2.2
## 0.3947 - asymptomatic reduction by 10%
## 0.2851 - asymptomatic reduction by 90%

## for 2.8
# 0.3187 -  asymptomatic reduction by 10%
# 0.2224 -  asymptomatic reduction by 90%

## get a list of countries.
cn = countries()
#cn = ["Colombia"]

## set global properties

println("Starting at: $(Dates.format(now(), "HH:MM"))")
results = map(cn) do c    
    # for each country get the beta transmission values
    # @everywhere b3ten = transmission_beta("3beta_ten", $c) 
    # @everywhere b3ninety = transmission_beta("3beta_ninety", $c) 
    @everywhere betaval = transmission_beta("beta_zero", $c)
    @everywhere pm = herdimmunity($c)

    @everywhere P = ZikaParameters(
        sim_time = 364,
        grid_size_mosq = 50000,
        country = $c,
        inital_latent = 1,
        reduction_factor = 1.0, 
        transmission = betaval, 
        ProbIsolationSymptomatic = 0.0,  
        coverage_general = 0.0,
        coverage_pregnant = 0.0,        
        coverage_reproductionAge = 0.0,       
        preimmunity = $pm)
        #preimmunity = $pm)
    run(P, 2000)

    @everywhere P = ZikaParameters(
        sim_time = 364,
        grid_size_mosq = 50000,
        country = $c,
        inital_latent = 1,
        reduction_factor = 1.0, 
        transmission = betaval, 
        ProbIsolationSymptomatic = 0.0,  
        coverage_general = 0.10,
        coverage_pregnant = 0.80,     
        coverage_reproductionAge =  0.60,
        preimmunity = $pm)        
    run(P, 2000)
end

#map(rm, filter(t -> ismatch(r"job.*\.out", t), readdir()))
println("All sims finished at: $(Dates.format(now(), "HH:MM"))")



## test change of parameters over all workers
#fetch(@spawnat 4 "on $(myid()), val is $(P.transmission)")
# using Base.Test
# valtotest = P.transmission
# ctr = 0
# for i=1:nworkers()
#   #tval = fetch(@spawnat i P.transmission)
#   tval = remotecall_fetch(() -> P.transmission, i)
#   println("testing $i")
#   if tval != valtotest
#     ctr += 1
#   end
# end
# println("wrong vals: $ctr")

