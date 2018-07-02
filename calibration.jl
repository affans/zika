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

#nohup julia calibration.jl &> logfile
add_truck(LumberjackTruck("logcalib.log"), "my-file-logger")
remove_truck("console")
info("lumberjack process started up, starting repl")

info("adding procs...")

s = SlurmManager(512)
@eval Base.Distributed import Base.warn_once
addprocs(s, partition="defq", N=16)
#addprocs(20)
#addprocs([("node003", 32), ("node004", 32)])


info("added $(nworkers()) processors")
info("starting @everywhere of main.jl file...")
@everywhere include("main.jl")

#### CALIBRATION PARAMETERS
@everywhere numberofsims = 1000
trans = [0.15 + 0.005i for i in 0:100]
rel = [0.10, 0.50, 0.90]
##create a dataframe for the results
final = DataFrame(transmission = trans)
#### END PARAMETERS

function spectrum(numberofsims, P)
    info("...starting pmap with $numberofsims simulations...")
    results = pmap((cb, x) -> main_calibration(x, P, callback=cb), Progress(numberofsims*P.sim_time), 1:numberofsims, passcallback=true)
    #results = pmap(x -> main_calibration(x, P), Progress(numberofsims*P.sim_time), 1:numberofsims)
    info("...finished simulations")
    info("...processing")
    ## set up dataframes - no rows, time columns
    ldf  = DataFrame(Int64, 0, P.sim_time)
    adf  = DataFrame(Int64, 0, P.sim_time)
    sdf  = DataFrame(Int64, 0, P.sim_time)
    ssdf = DataFrame(Int64, 0, P.sim_time)
    asdf = DataFrame(Int64, 0, P.sim_time)
        
    #load up dataframes
    for i=1:numberofsims
        push!(ldf, results[i][1]) #results[i][1] is the latent vector of size sim_time
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
    totalavg_symp = sum(sumss)/numberofsims
    totalavg_lat = sum(sumsl)/numberofsims
    info("...averaging on process: $(myid())")
    #print("transmission: $transmission (or $j) \n")
    info("...total symptomatics: $(sum(sumss))")
    info("...R0: $totalavg_lat")
    info("...completed \n")
    return totalavg_lat
end

values = map(rel) do r
    info("starting calibration for relative asymptomatic: $r")
    a = map(trans) do t
        info("...setting up parameters with transmission: $t")
        @everywhere P = ZikaParameters(sim_time = 100, transmission = $t, grid_size_human = 10000, grid_size_mosq = 50000, inital_latent = 1, reduction_factor = $r)
        info("...starting spectrum")
        spectrum(numberofsims, P)
    end
    info("...finished")
    final[:, Symbol(r)]  = a
end
## write to file
info("writing to file")
writetable("calibration_values.dat", final)
info("\n end of calibration")
# numberofsims = 1000
# ## setup main variables    
# @everywhere trans_val = 0.205
# @everywhere P = ZikaParameters(sim_time = 100, transmission = trans_val, grid_size_human = 10000, grid_size_mosq = 50000, inital_latent = 1, reduction_factor = 0.1)
# results = pmap((cb, x) -> main_calibration(x, P, callback=cb), Progress(numberofsims*P.sim_time), 1:numberofsims, passcallback=true)


# ## set up dataframes - no rows, time columns
# ldf  = DataFrame(Int64, 0, P.sim_time)
# adf  = DataFrame(Int64, 0, P.sim_time)
# sdf  = DataFrame(Int64, 0, P.sim_time)
# ssdf = DataFrame(Int64, 0, P.sim_time)
# asdf = DataFrame(Int64, 0, P.sim_time)
    
# #load up dataframes
# for i=1:numberofsims
#     push!(ldf, results[i][1]) #results[i][1] is the latent vector of size sim_time
#     push!(sdf, results[i][2])
#     push!(adf, results[i][3])
#     push!(ssdf,results[i][4])
#     push!(asdf, results[i][5])
# end        

# ## for calibration
# sumss = zeros(Int64, numberofsims)
# sumsa = zeros(Int64, numberofsims)
# sumsl = zeros(Int64, numberofsims)

# l = convert(Matrix, ldf)        
# s = convert(Matrix, sdf)
# a=  convert(Matrix, adf)

# for i=1:numberofsims
#     sumss[i] = sum(s[i, :])
#     sumsa[i] = sum(a[i, :])
#     sumsl[i] = sum(l[i, :])
# end
# totalavg_symp = sum(sumss)/numberofsims
# totalavg_lat = sum(sumsl)/numberofsims
# print("averaging on process: $(myid()) \n")
# #print("transmission: $transmission (or $j) \n")
# print("total symptomatics: $(sum(sumss)) \n")
# print("\n")

# print("R0: $totalavg_lat \n")
# print("\n")
# # print("\n")
# resarr = Array{Number}(9)
# resarr[1] = trans_val
# resarr[2] = trans_val
# resarr[3] = P.reduction_factor
# resarr[4] = numberofsims
# resarr[5] = sum(sumss)
# resarr[6] = sum(sumsa)
# resarr[7] = sum(sumsl)
# resarr[8] = totalavg_symp
# resarr[9] = totalavg_lat 