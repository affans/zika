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



function setup_filestructure(P)
  ## using the parameters create directories  
  asymp = "Asymp$(Int(P.reduction_factor*100))" 
  iso = "Iso$(Int(P.ProbIsolationSymptomatic*100))"
  cov = "Coverage$(Int(P.coverage_general*100))$(Int(P.coverage_pregnant*100))"
  pre = P.preimmunity > 0 ? "Pre1" : "Pre0"
  return string(asymp, iso, "_", cov, pre)
end

function dataprocess(results, numofsims, P)
  dirname = setup_filestructure(P)
  mkdir(dirname)
  
  #numofdays = 182*2
  #numofsims = 2000
  #create empty matrices
  lm = Matrix{Int64}(numofsims, P.sim_time)
  bsm = Matrix{Int64}(numofsims, P.sim_time)
  bam = Matrix{Int64}(numofsims, P.sim_time)
  ssm = Matrix{Int64}(numofsims, P.sim_time)
  sam = Matrix{Int64}(numofsims, P.sim_time)
  
  ps = Matrix{Int64}(numofsims, P.sim_time)
  pa = Matrix{Int64}(numofsims, P.sim_time)
  mic = Matrix{Int64}(numofsims, P.sim_time)
  vgen = Matrix{Int64}(numofsims, P.sim_time)
  vpre = Matrix{Int64}(numofsims, P.sim_time)
  rec = Matrix{Int64}(numofsims, P.sim_time)
    
  # read each file
  for i = 1:numofsims
      lm[i, :] = results[i][1] 
      bsm[i, :] = results[i][2] 
      bam[i, :] = results[i][3] 
      ssm[i, :] = results[i][4] 
      sam[i, :] = results[i][5] 
      ps[i, :] = results[i][6] 
      pa[i, :] = results[i][7]
      mic[i, :] = results[i][8] 
      vgen[i, :] = results[i][9] 
      vpre[i, :] = results[i][10]       
      #rec[i, :] = results[i][11] 
      
  end 
  
  # # read each file
  # for i = 1:numofsims
  #   fn = string("simulation-", i, ".dat")
  #   dt = readdlm(fn, Int64)
  #   lm[i, :] = dt[:, 1] 
  #   bsm[i, :] = dt[:, 2]
  #   bam[i, :] = dt[:, 3]
  #   ssm[i, :] = dt[:, 4]
  #   sam[i, :] = dt[:, 5]  
  #   ps[i, :] = dt[:, 6]
  #   pa[i, :] = dt[:, 7]
  #   mic[i, :] = dt[:, 8]
  #   vgen[i, :] = dt[:, 9]
  #   vpre[i, :] = dt[:, 10]
  # end 
  

  writedlm(string(dirname, "/latent.dat"), lm)
  writedlm(string(dirname,"/bitesymp.dat"), bsm)
  writedlm(string(dirname, "/biteasymp.dat"), bam)
  writedlm(string(dirname, "/sexsymp.dat"), ssm)
  writedlm(string(dirname, "/sexasymp.dat"), sam)
  writedlm(string(dirname, "/pregsymp.dat"), ps)
  writedlm(string(dirname, "/pregasymp.dat"), pa)
  writedlm(string(dirname, "/micro.dat"), mic)
  writedlm(string(dirname, "/vacgeneral.dat"), vgen)
  writedlm(string(dirname, "/vacpregnant.dat"), vpre)    
  #writedlm(string(dirname, "/recovered.dat"), rec)      
end

function run(P, numberofsims) 
  # cb is the callback function. It updates the progress bar
  results = pmap((cb, x) -> main(cb, x, P), Progress(numberofsims*P.sim_time), 1:numberofsims, passcallback=true)    
  info("Parameters: \n $P \n")  ## prints to STDOUT - redirect to logfile
  info("directory name: $(setup_filestructure(P))")  
  info("starting pmap...\n")
  dataprocess(results, numberofsims, P)
end




##### MAIN CODE

## for 2.2
## 0.3947 - asymptomatic reduction by 10%
## 0.2851 - asymptomatic reduction by 90%

## for 2.8
# 0.3187 -  asymptomatic reduction by 10%
# 0.2224 -  asymptomatic reduction by 90%

## setup main Zika Parameters  
##scenario one

@everywhere gridsize = 50000  # 100000
@everywhere asymp_ten = 0.3947 #0.3187 #0.3947
@everywhere asymp_ninety = 0.2851 #0.2224 #0.2851
@everywhere runsims = 5000

## asymp 10, iso 10, covgen 0, covpreg 0, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.1, 
transmission = asymp_ten , 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.0 )
run(P, runsims)

## asymp 10, iso 10, covgen 10, covpreg 80, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.1, 
transmission = asymp_ten , 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.0 )
run(P, runsims)

## asymp 10, iso 50, covgen 0, covpreg 0, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.5, 
transmission = asymp_ten , 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.0 )
run(P, runsims)

## asymp 10, iso 50, covgen 10, covpreg 80, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.5, 
transmission = asymp_ten , 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.0 )
run(P, runsims)


## asymp 90, iso 50, covgen 0, covpreg 0, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.50, 
transmission = asymp_ninety, 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.0 )
run(P, runsims)

## asymp 90, iso 50, covgen 10, covpreg 80, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.50, 
transmission = asymp_ninety, 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.0 )
run(P, runsims)


## asymp 90, iso 10, covgen 0, covpreg 0, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.10, 
transmission = asymp_ninety, 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.0 )
run(P, runsims)

## asymp 90, iso 10, covgen 10, covpreg 80, preimmunity 0
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.10, 
transmission = asymp_ninety, 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.0 )
run(P, runsims)

#### START PRE IMMUNITY 1
## asymp 10, iso 10, covgen 0, covpreg 0, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.1, 
transmission = asymp_ten , 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.08 )
run(P, runsims)

## asymp 10, iso 10, covgen 10, covpreg 80, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.1, 
transmission = asymp_ten , 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.08 )
run(P, runsims)

## asymp 10, iso 50, covgen 0, covpreg 0, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.5, 
transmission = asymp_ten, 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.08 )
run(P, runsims)

## asymp 10, iso 50, covgen 10, covpreg 80, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.1, 
ProbIsolationSymptomatic = 0.5, 
transmission = asymp_ten , 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.08 )
run(P, runsims)


## asymp 90, iso 50, covgen 0, covpreg 0, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.50, 
transmission = asymp_ninety, 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.08 )
run(P, runsims)

## asymp 90, iso 50, covgen 10, covpreg 80, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.50, 
transmission = asymp_ninety, 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.08 )
run(P, runsims)


## asymp 90, iso 10, covgen 0, covpreg 0, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.10, 
transmission = asymp_ninety, 
coverage_general = 0.0,
coverage_pregnant = 0.0,               
preimmunity = 0.08 )
run(P, runsims)

## asymp 90, iso 10, covgen 10, covpreg 80, preimmunity 1
@everywhere P = ZikaParameters(
grid_size_mosq = gridsize,
inital_latent = 1,
reduction_factor = 0.90, 
ProbIsolationSymptomatic = 0.10, 
transmission = asymp_ninety, 
coverage_general = 0.10,
coverage_pregnant = 0.80,               
preimmunity = 0.08 )
run(P, runsims)


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