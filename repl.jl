

numberofsims = 2
@everywhere transmission = 0.0
for j=1:6
    print("--------------------\n")
    #@broadcast testi = 0.35
    #sendto(workers(), transmission = 0.625 ) ## 0.1
    #sendto(workers(), transmission = (0.545 - (j - 1)*0.01) )
    ##sendto(workers(), transmission = (0.52 - (j - 1)*0.01) )
    sendto(workers(), transmission = 0.6237 )
    
    
    ## setup main variables    
    @everywhere P = ZikaParameters(sim_time = 731, grid_size_human = 100000, grid_size_mosq = 500000, inital_latent = 1, prob_infection_MtoH = transmission, prob_infection_HtoM = transmission, reduction_factor = 0.1)    ## variables defined outside are not available to the functions. 
    results = pmap(x -> main(x, P), 1:numberofsims)  
    
    ## set up dataframes
    ldf  = DataFrame(Int64, 0, P.sim_time)
    adf  = DataFrame(Int64, 0, P.sim_time)
    sdf  = DataFrame(Int64, 0, P.sim_time)
    ssdf = DataFrame(Int64, 0, P.sim_time)
    asdf = DataFrame(Int64, 0, P.sim_time)
    
    #load up dataframes
    for i=1:numberofsims
        push!(ldf, results[i][1])
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
    totalavg = sum(sumss)/numberofsims
    print("averaging on process: $(myid()) \n")
    print("transmission: $transmission (or $j) \n")
    print("total symptomatics: $(sum(sumss)) \n")
    print("\n")
    print("R0: $totalavg")
    print("\n")
    resarr = Array{Number}(8)
    resarr[1] = j
    resarr[2] = j
    resarr[3] = P.reduction_factor
    resarr[4] = numberofsims
    resarr[5] = sum(sumss)
    resarr[6] = sum(sumsa)
    resarr[7] = sum(sumsl)
    resarr[8] = totalavg 
    filename = string("file-", j, "-",  transmission, ".txt")
    writedlm(filename, resarr)
end