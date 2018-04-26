rm(list = ls())
library(data.table)
library(ggplot2)
library(reshape2)
#library(ggthemes)
#library(plyr)
#library(gridExtra)
#library(grid)
#library(RColorBrewer)
library(boot)
library(BCEA)


## the following three functions are for DALY computations, from the Deeseiver paper 

## the integrand for burden() 
term <- function(x, K, C = 0.1658, beta = 0.04, r, a){
  K*C*x*exp(-beta*x)*exp(-r * (x - a)) + (1 - K)*exp(-r*(x-a))
}

# calculate the integral
burden <- function(DW, AgeOfOnset, YearsUnderBurden, ModFactor, DiscountRate, BurdenAge){
  DW*integrate(term, lower = AgeOfOnset, upper = (AgeOfOnset+YearsUnderBurden), K=ModFactor, r=DiscountRate, a=BurdenAge)$value
}

daly <- function(DW, A, LD, LY, BA = 0, Dis=0.03, K=0){
  ## DW = disability weight
  ## A = Age of onset of burden
  ## LD = years lived with disability from age A
  ## LY = after dying, the years LOST (ie, if didn't die was was expected lifetime)
  ## BA = the age to calculate the "burden", ie THE "PRESENT TIME"
  ##   note: Most likely A = BA (Age of onset is when is the "present time")
  yld = burden(DW, AgeOfOnset = A, YearsUnderBurden = LD, ModFactor=K, DiscountRate=Dis, BurdenAge=BA)
  yll = burden(DW=1, AgeOfOnset = (A+LD), YearsUnderBurden = LY, ModFactor=K, DiscountRate=Dis, BurdenAge=BA)
  daly = yld + yll
  return(c(yld, yll, daly))
}
#daly_v = Vectorize(daly, c("LD", "LY"), SIMPLIFY = T)
## exmaple from the pdf 
#daly(DW = 0.16, A = 40, LD = 20, LY = 0, BA = 0, Dis = 0.03, K=0)
#daly(DW = 0.16, A = 0, LD = 8.483575, LY = 0, BA = 0, Dis = 0.03, K=0)

## returns a named list of strings, corresponding to simulation data output
fnames <- function(R = "R022", imm=0, asymp=10, iso=10){
  #pp = paste0("/Users/abmlab/Dropbox/Zika Vaccine/Affan/", R, "/")
  #pp = paste0("E:/Dropbox/Zika Vaccine/Affan/", R, "/")
  #pp = paste0("")
  asympiso = paste0("/Asymp", asymp, "Iso", iso)
  pre = paste0("Pre",imm)
  nv = paste0(pp, asympiso, "_Coverage00", pre, "/")
  wv = paste0(pp, asympiso, "_Coverage1080", pre, "/")
  lv = c("wv", "nv")
  mainlist = list()
  mainlist["dir"] = paste0(imm, asymp)
  for(i in lv){
    d = eval(parse(text=i)) ## get either wv or nv filepath from the string "wv" or "nv"
    fnlist = list()
    fnlist["latent"] = paste0(d, "latent.dat")
    fnlist["bitesymp"] = paste0(d, "bitesymp.dat")
    fnlist["sexsymp"] = paste0(d, "sexsymp.dat")
    fnlist["biteasymp"] = paste0(d, "biteasymp.dat")
    fnlist["sexasymp"] = paste0(d, "sexasymp.dat")
    fnlist["micro"] = paste0(d, "micro.dat")
    fnlist["pregsymp"] = paste0(d, "pregsymp.dat")
    fnlist["pregasymp"] = paste0(d, "pregasymp.dat")
    fnlist["vacgeneral"] = paste0(d, "vacgeneral.dat")
    fnlist["vacpregnant"] = paste0(d, "vacpregnant.dat")
    fnlist["recovered"] = paste0(d, "recovered.dat")
    mainlist[i] = list(fnlist)
  }  
  return(mainlist)
}



## process microcephaly- input dt is a datatable at simulation level resolution with the total number of microcephaly cases in each simulation 
process_micro <- function(dt){

  ## mdt is the intermediate datatable that holds the calculations per micro case
  mdt = data.table("simid"=numeric(), "die"=numeric(), "expectancy"=numeric(), "microlife"=numeric(), "daly"=numeric())
  
  ## for each simulation, calculate the number of dalys per micro case in each simulation
  for(i in 1:5000){
    if(dt[i]$total > 0){
      simid = i
      expectancy = min(-70*log(1-runif(1,0,1)), 99)
      microlife = -35*log(1-runif(1,0,1))
      if(microlife > expectancy)
        microlife = expectancy
      die = rbinom(1, 1, 0.2) ## 20% chance of dying
      if(die == 1)
        microlife = 0
      
      d = daly(DW = 0.16, A = 0, LD = microlife, LY = (expectancy - microlife), BA = 0, Dis = 0.03, K = 0)
      mdt = rbind(mdt, list(simid, die, expectancy, microlife,  d[3]))
    }
  }
  ## sum up the DALYs at the simulation level
  mdt = mdt[, .(totaldalys = sum(daly)), by=simid]
  setkey(mdt, simid)
  dt = merge(dt, mdt, all.x = T)
  dt[is.na(dt$totaldalys), "totaldalys"]= 0
  #summary(mdt$totaldalys)
  return(list(dt=dt, summary=summary(mdt$totaldalys)))
}



process_simulations <- function(fn, vaccineprice=0){
  ## create a restuls data
  numofsims = 5000
  rdt = data.table("simid" = numeric(numofsims))
  rdt$simid = seq(1:numofsims)
  
  ## cost variables
  sympcost = 65
  testcost = 150
  gbscost = 29027
  microcost = 91925
  
  ## read file names 
  l = fread(fn$latent)
  bitesymp = fread(fn$bitesymp)
  sexsymp = fread(fn$sexsymp)
  biteasymp = fread(fn$biteasymp)
  sexasymp = fread(fn$sexasymp)
  symp = bitesymp + sexsymp
  asymp = biteasymp + sexasymp
  symp = symp[, .(totals = rowSums(symp))]  ## add up incidence at simulation level
  asymp = asymp[, .(totals = rowSums(asymp))]
  pos = symp + asymp
  pos[, simid := seq(1:numofsims)]
  setkey(pos, simid)
  
  #r = fread("Dropbox/Zika Vaccine/Affan/R028/1 initial/Asymp10Iso10_Coverage00Pre0/recovered.dat")
  
  rdt$sympcases = symp$totals
  rdt$sympcost = sympcost * symp$totals
  ## check if 0 sims have zero cost
  stopifnot(nrow(rdt[sympcases == 0 & sympcost > 0 , ]) == 0)
  
  ## process GBS cases
  rn = 0.00025+runif(1)*(0.0006-0.00025)
  rdt$gbscases = (symp + asymp)*rn
  rdt$gbscost = gbscost * rdt$gbscases
  ## check if 0 sims have zero cost
  stopifnot(nrow(rdt[gbscases == 0 & gbscost > 0 , ]) == 0)
  
  ## get microcephaly cases
  mcr = fread(fn$micro)
  mcr[, simid:=seq(1:numofsims)] ## add a simid column
  mcr = mcr[, .(simid, total = rowSums(mcr[, !c("simid")]))] ## add up the rows
  setkey(mcr, simid)  ##set key to simid for merging with the intermediate results below
  
  mcr = process_micro(mcr) 
  rdt$microcases = mcr$dt$total
  rdt$microcost = microcost * mcr$dt$total
  rdt$totaldalys = mcr$dt$totaldalys
  ## check if this is all 0 for 0 sims
  stopifnot(sum(rdt[pos[totals == 0, ]$simid, ]$microcases) == 0)
  stopifnot(sum(rdt[pos[totals == 0, ]$simid, ]$microcost) == 0)
  stopifnot(sum(rdt[pos[totals == 0, ]$simid, ]$totaldalys) == 0)
  
  ## get test costs for pregnant symp
  pre = fread(fn$pregsymp)
  pre = pre[, .(totals = rowSums(pre))]
  rdt$pregsympcases = pre$totals
  rdt$pregsympcost = testcost * pre$totals
  
  ## take care of the initial case (dec 22nd). This bug is fixed in commit ffdf008
  rdt[pos[totals == 0, ]$simid,  ]$pregsympcases = 0
  rdt[pos[totals == 0, ]$simid,  ]$pregsympcost = 0
  
  vacgeneral = fread(fn$vacgeneral)
  vacpregnant = fread(fn$vacpregnant)
  vac = vacgeneral + vacpregnant
  vac[, simid:=seq(1:numofsims)] ## add a simid column
  vac = vac[, .(simid, total = rowSums(vac[, !c("simid")]))]
  
  ## set all the simulations where there was no vaccine to zero cases so we dont count them
  vac[pos[totals == 0, ]$simid, "total"] = 0
  rdt$vaccases = vac$total
  rdt$vaccost = vaccineprice*vac$total
  
  rdt$totalcosts = rdt$sympcost + rdt$gbscost + rdt$microcost + rdt$pregsympcost + rdt$vaccost
  ## check if the total costs and total dalys for 0 sims are actually zero. 
  stopifnot(sum(rdt[pos[totals == 0, ]$simid, ]$totalcosts) == 0)
  stopifnot(sum(rdt[pos[totals == 0, ]$simid, ]$totaldalys) == 0)
  return(rdt[totalcosts > 0, ])
  #return(rdt)
}

## bootstraping
icerbootstrap <- function(dat, idx){
  wvc = mvc = mean(dat[idx, wvcosts])
  nvc = mnc = mean(dat[idx, nvcosts])
  wvd = mvd = mean(dat[idx, wvdalys])
  nvd = mnd = mean(dat[idx, nvdalys])
  costdiff = wvc - nvc
  dalydiff = -(wvd - nvd)
  ## want wvc, nvc, nvd, wvd in order for the BCEA package since it does a direct "substraction" for the difference
  return(c(costdiff/dalydiff, costdiff, dalydiff, wvc, nvc, nvd, wvd))
}

## we dont use this function, see comment for more elegant solution inside.
remove_outliers <- function(x, na.rm = TRUE, ...) {
  qnt <- quantile(x, probs=c(.25, .75), na.rm = na.rm, ...)
  H <- 1.5 * IQR(x, na.rm = na.rm)
  y <- x
  y[x < (qnt[1] - H)] <- NA
  y[x > (qnt[2] + H)] <- NA
  y
  
  ## more elegant solution
  ## x[!x %in% boxplot.stats(x)$out]
  ## https://stackoverflow.com/questions/4787332/how-to-remove-outliers-from-a-dataset
}


run_analysis <- function(Rzero, immonoff, asymplvl, isolvl){
  ## the main function for cost-effectiveness analysis

  ## the willingness to pay vector for BCEA
  wtpvec = seq(from = 0, to = 50000, by = 50)
  
  ## vaccine prices to loop over
  vaccineprices = seq(from = 2, to = 100, by = 1)
  
  ## allocate return matrices
  data.CE <- matrix(0,nrow=length(wtpvec),ncol=length(vaccineprices));
  ## for 2000 bootstrap values
  data.ICER <- matrix(0,nrow=2000,ncol=length(vaccineprices)); 
  
  
  ## get the base data tables 
  filenames = fnames(R=Rzero, imm=immonoff, asymp=asymplvl, iso=isolvl)

  ## process the simulations without vaccine... dont need to put this inside loop
  nv_raw = process_simulations(filenames$nv, vaccineprice=0)
  for(i in 1:length(vaccineprices)){
    #print(i)
    ## WHAT FILES DO YOU WANT TO PROCESS?
    wv_raw = process_simulations(filenames$wv, vaccineprice=vaccineprices[i])
    
    ## since we are elimnating zeros, these might be different size data tables
    ## for easy bootstrap we need the same number of rows
    numrows = min(nrow(nv_raw), nrow(wv_raw))
    icerdt = data.table("simid"=numeric(numrows))
    icerdt$simid = seq(1:numrows)
    icerdt$nvcosts = nv_raw[1:numrows, ]$totalcosts
    icerdt$nvdalys = nv_raw[1:numrows, ]$totaldalys
    icerdt$wvcosts = wv_raw[1:numrows, ]$totalcosts
    icerdt$wvdalys = wv_raw[1:numrows, ]$totaldalys
    
    set.seed(913)
    b = boot(icerdt, icerbootstrap, R = 2000)
    #b.conf = boot.ci(b, index=1) ## index = 1 is the ICER, index=2 is the cost diff, index=3 is the DALY diff
    # extract the mean costs and effects from bootstrap results. 
    
    ## capture the bootstrap results in a data table
    tmp_bt = data.table(b$t)
    ## remove the outliers from this (FOR CEAC PURPOSES ONLY) by using the boxplot.stats() function
    tmp_bt = tmp_bt[!(V1 %in% boxplot.stats(tmp_bt$V1)$out)]
    
    #c = as.matrix(b$t[, c(4, 5)])  ## get the costs from bootstrap data
    #e = as.matrix(b$t[, c(6, 7)])  ## get the effects from bootstrap data
    c = as.matrix(tmp_bt[, c("V4", "V5")])
    e = as.matrix(tmp_bt[, c("V6", "V7")])
    
    ## create analysis
    mc = bcea(e, c, ref=1, interventions = c("With Vaccine", "No Vaccine"), Kmax =50000, wtp = wtpvec)
   
    ## remove the manual seed
    rm(.Random.seed, envir=globalenv()) ## remove the set seed
    
    #  rst[, paste0("P", i)] = b$t[, 1]
    #  cecurve[, paste0("P", i)] = mc$ceac
    data.ICER[, i] <- b$t[, 1]
    data.CE[, i] <- mc$ceac
    #btresults = data.table(cost = b$t[, 2], daly = b$t[, 3])
  }
  icerfilename = paste0("Pre", immonoff, "Asymp", asymplvl, "Iso", isolvl, ".dat")
  ceacfilename = paste0("Pre", immonoff, "Asymp", asymplvl, "Iso", isolvl, "CEAC.dat")
  fwrite(data.table(data.ICER), file = icerfilename, col.names = F, row.names = F)
  fwrite(data.table(data.CE), file = ceacfilename, col.names = F, row.names = F)
}



run_analysis("R028", 0, 10, 10)
run_analysis("R028", 0, 10, 50)
run_analysis("R028", 0, 90, 10)
run_analysis("R028", 0, 90, 50)
run_analysis("R028", 1, 10, 10)
run_analysis("R028", 1, 10, 50)
run_analysis("R028", 1, 90, 10)
run_analysis("R028", 1, 90, 50)



## the file to write should comes from the results above. Name accordingly, fn=fnames() function call above

#ggplot(rst, aes("P2", P2)) + geom_boxplot()

#paper
# Definition, interpretation and calculation of cost-effectiveness acceptability curves.

# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1538588/ 
#system("convert -delay 75 bday_*.png birthday.mp4")
#system("rm bday*.png")
## TO DO main() function to get the vaccine/no vaccine case and to calculate dalys
## see analysis.R and zika_functions.R in abm Rstudio

