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
#setwd("/stor4/share/zika_costanalysis/R022/Affan/No Preimmunity/Asymp10Iso10_Coverage00//")


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
daly(DW = 0.16, A = 0, LD = 8.483575, LY = 0, BA = 0, Dis = 0.03, K=0)

## process microcephaly and calculate DALYs
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

fnames <- function(R = "R022", imm=0, asymp=10, iso=10){
  #pp = paste0("/Users/abmlab/Dropbox/Zika Vaccine/Affan/", R, "/")
  pp = paste0("E:/Dropbox/Zika Vaccine/Affan/", R, "/")
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
  
  ## process symptomatic costs
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




run_analysis <- function(Rzero, immonoff, asymplvl, isolvl){
  rst = data.table("P2" = numeric(2000), 
                   "P5" = numeric(2000), 
                   "P10"= numeric(2000), 
                   "P20"= numeric(2000), 
                   "P30"= numeric(2000), 
                   "P40"= numeric(2000), 
                   "P50"= numeric(2000))
  cecurvepoints = 501 ## from beac package
  cecurve = data.table("P2" = numeric(cecurvepoints), 
                       "P5" = numeric(cecurvepoints), 
                       "P10"= numeric(cecurvepoints), 
                       "P20"= numeric(cecurvepoints), 
                       "P30"= numeric(cecurvepoints), 
                       "P40"= numeric(cecurvepoints), 
                       "P50"= numeric(cecurvepoints))
 
  ## get the base data tables - no need to put these inside the loop.
  filenames = fnames(R=Rzero, imm=immonoff, asymp=asymplvl, iso=isolvl)
  nv_raw = process_simulations(filenames$nv, vaccineprice=0)
  for(i in c(2, 5, 10, 20, 30, 40, 50)){
    ## WHAT FILES DO YOU WANT TO PROCESS?
    wv_raw = process_simulations(filenames$wv, vaccineprice=i)
    ## since we are elimnating zeros, these might be different size data tables
    ## for easy bootstrap we need the same number of rows
    numrows = min(nrow(nv_raw), nrow(wv_raw))
    icerdt = data.table("simid"=numeric(numrows))
    icerdt$simid = seq(1:numrows)
    icerdt$nvcosts = nv_raw[1:numrows, ]$totalcosts
    icerdt$nvdalys = nv_raw[1:numrows, ]$totaldalys
    icerdt$wvcosts = wv_raw[1:numrows, ]$totalcosts
    icerdt$wvdalys = wv_raw[1:numrows, ]$totaldalys
    
    set.seed(912)
    b = boot(icerdt, icerbootstrap, R = 2000)
    #b.conf = boot.ci(b, index=1) ## index = 1 is the ICER, index=2 is the cost diff, index=3 is the DALY diff
    
    c = as.matrix(b$t[, c(4, 5)])  ## get the costs from bootstrap data
    e = as.matrix(b$t[, c(6, 7)])  ## get the effects from bootstrap data
    ## create analysis
    wtpvec = seq(from = 0, to = 50000, by = 200)
    mc = bcea(e, c, ref=1, interventions = c("With Vaccine", "No Vaccine"), Kmax =100000, wtp = wtpvec)
   
    ## remove the manual seed
    rm(.Random.seed, envir=globalenv()) ## remove the set seed
    
    rst[, paste0("P", i)] = b$t[, 1]
    cecurve[, paste0("P", i)] = mc$ceac
 
    #btresults = data.table(cost = b$t[, 2], daly = b$t[, 3])
  }
  fntowrite = paste0("Pre", immonoff, "Asymp", asymplvl, "Iso", isolvl, ".dat")
  fncetowrite = paste0("Pre", immonoff, "Asymp", asymplvl, "Iso", isolvl, "_CEAC.dat")
  fwrite(rst, file = fntowrite, col.names = F, row.names = F)
  fwrite(cecurve, file = fncetowrite, col.names = F, row.names = F)
}

plot_icer <- function(btdata){
  
}

run_analysis("R022", 0, 10, 10)
run_analysis("R022", 0, 10, 50)
run_analysis("R022", 0, 90, 10)
run_analysis("R022", 0, 90, 50)
run_analysis("R022", 1, 10, 10)
run_analysis("R022", 1, 10, 50)
run_analysis("R022", 1, 90, 10)
run_analysis("R022", 1, 90, 50)

## the file to write should comes from the results above. Name accordingly, fn=fnames() function call above

#ggplot(rst, aes("P2", P2)) + geom_boxplot()

#paper
# Definition, interpretation and calculation of cost-effectiveness acceptability curves.

# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC1538588/ 
#system("convert -delay 75 bday_*.png birthday.mp4")
#system("rm bday*.png")
## TO DO main() function to get the vaccine/no vaccine case and to calculate dalys
## see analysis.R and zika_functions.R in abm Rstudio

