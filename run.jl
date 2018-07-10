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

#Pkg.add("ProgressMeter")
#Pkg.add("PmapProgressMeter")
#Pkg.add("DataFrames")
#Pkg.add("Match")
#Pkg.add("Para")
#Pkg.add("")
#Pkg.add("")


add_truck(LumberjackTruck("processrun.log"), "my-file-logger")
remove_truck("console")
info("lumberjack process started up, starting repl")

info("adding procs...")

s = SlurmManager(512)
@eval Base.Distributed import Base.warn_once
addprocs(s, partition="defq", N=16)
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
#cn = countries()
cn = ["Colombia"]

## set global properties

results = map(cn) do c    
    # for each country get the beta transmission values
    @everywhere b3ten = transmission_beta("3beta_ten", $c) 
    @everywhere b3ninety = transmission_beta("3beta_ninety", $c) 
    @everywhere b5ten = transmission_beta("5beta_ten", $c) 
    @everywhere b5ninety = transmission_beta("5beta_ninety", $c) 
    @everywhere pm = herdimmunity($c)

    ## r0 2.2, asymp 10, iso 50, covgen 0, covpreg 0, preimmunity country specific
    @everywhere P = ZikaParameters(
    sim_time = 364,
    grid_size_mosq = 50000,
    inital_latent = 1,
    reduction_factor = 0.1, 
    transmission = b3ten, 
    ProbIsolationSymptomatic = 0.5,  
    coverage_general = 0.0,
    coverage_pregnant = 0.0,               
    preimmunity = pm)
    run(P, 2000)

    ## r0 2.2, asymp 90, iso 50, covgen 0, covpreg 0, preimmunity country specific
    @everywhere P = ZikaParameters(
    sim_time = 364,
    grid_size_mosq = 50000,
    inital_latent = 1,
    reduction_factor = 0.9, 
    transmission = b3ninety, 
    ProbIsolationSymptomatic = 0.5,  
    coverage_general = 0.0,
    coverage_pregnant = 0.0,               
    preimmunity = pm)
    run(P, 2000)

end

info("all simulations finished")



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

## recover code K86OZ4AUUE