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
#trans = [0.15 + 0.005i for i in 0:100]
#rel = [0.10, 0.50, 0.90]

trans = [0.3109, 0.2942, 0.3073, 0.2982, 0.2609, 0.2893, 0.3046, 0.3073, 0.3016, 0.3032, 0.3016, 0.2794, 0.3060, 0.3032, 0.3060, 0.2748, 0.3120, 0.3086]
rel = [1.0]
final = DataFrame(transmission = trans) #create a dataframe for the results
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

try 
    values = map(rel) do r
        info("starting calibration for relative asymptomatic: $r")
        a = map(trans) do t
            info("...setting up parameters with transmission: $t")
            ## don't care about country- -leave default.
            @everywhere P = ZikaParameters(sim_time = 100,  transmission = $t, ProbIsolationSymptomatic = 0.0,  grid_size_human = 10000, grid_size_mosq = 50000, inital_latent = 1, reduction_factor = $r,  coverage_general = 0.0, coverage_pregnant = 0.0, coverage_reproductionAge = 0.0)
            info("...starting spectrum")
            spectrum(numberofsims, P)
        end
        info("...finished")
        final[:, Symbol(r)]  = a
    end
    ## write to file
    info("writing to file")
    writetable("calibration_values.dat", final)    
finally
    # remove job files
    map(rm, filter(t -> ismatch(r"job.*\.out", t), readdir()))
end
info("\n end of calibration")


## CALIBRATION TO ATTACK RATE:
## The following piece of code is used to run the entire simulation for a range of beta values
## The results are then used to calculate attack rates 
## Only need to run for COlombia. 
## dont need to set reduction factor/symptomtaic isolation using this method of calibration. 
## Betas for each country are then calculated using curve fitting/regressiob techniques

## this code is commented. If you want to run it, copy paste it into a new file with the "headers" of the file from run.jl
# c = "Colombia"

# trans = [0.15 + 0.005i for i in 0:100]
# #trans = [0.15]

# a = map(trans) do t
#     info("...setting up parameters with transmission: $t")
#     @everywhere P = ZikaParameters(
#             sim_time = 728,
#             grid_size_mosq = 50000,
#             country = "Colombia",
#             inital_latent = 1,
#             reduction_factor = 1.0, 
#             transmission = $t, 
#             ProbIsolationSymptomatic = 0.0,  
#             coverage_general = 0.0,
#             coverage_pregnant = 0.0,               
#             preimmunity = 0.0)
#     info("...starting run")
#     run(P, 2000)
# end

# map(rm, filter(t -> ismatch(r"job.*\.out", t), readdir()))
# info("all simulations finished")
# quit()



## VEGA LITE PLOTTING
#the "pred" is the predicted column from the regression
# c |> @vlplot(width=500, height=500) + @vlplot(mark={
#         :point,
#         point=true,
#         color=:red
#     }, x="trans:q", y="ten:q") + @vlplot(mark={
#         :line,
#         point=false,
#         color=:blue
#     }, x="trans:q", y="pred:q")

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