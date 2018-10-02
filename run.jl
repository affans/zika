include("SlurmConnect.jl")
using ProgressMeter
using PmapProgressMeter
using DataFrames
using Match
using ParallelDataTransfer
using QuadGK
using Parameters #module
using Distributions
using StatsBase
using Lumberjack
using FileIO
using SlurmConnect 

#Pkg.add("VegaLite")

add_truck(LumberjackTruck("processrun.log"), "my-file-logger")
remove_truck("console")
info("lumberjack process started up, starting repl")

info("adding procs...")

s = SlurmManager(544)
@eval Base.Distributed import Base.warn_once
addprocs(s, partition="defq", N=17)
#addprocs(40)
#addprocs([("node003", 32), ("node004", 32)])

println("added $(nworkers()) processors")
info("starting @everywhere include process...")
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
        #preimmunity = $pm)
    run(P, 2000)
end

map(rm, filter(t -> ismatch(r"job.*\.out", t), readdir()))
info("all simulations finished")
quit()



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

