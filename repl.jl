
numofdays = 182*2
numofsims = 10
lm = Matrix{Int64}(numofsims, numofdays)
bsm = Matrix{Int64}(numofsims, numofdays)
bam = Matrix{Int64}(numofsims, numofdays)
ssm = Matrix{Int64}(numofsims, numofdays)
sam = Matrix{Int64}(numofsims, numofdays)

ps = Matrix{Int64}(numofsims, numofdays)
mic = Matrix{Int64}(numofsims, numofdays)
vgen = Matrix{Int64}(numofsims, numofdays)
vpre = Matrix{Int64}(numofsims, numofdays)


# read each file
for i = 1:numofsims
    fn = string("simulation-", i, ".dat")
    dt = readdlm(fn, Int64)
    lm[i, :] = dt[:, 1] 
    bsm[i, :] = dt[:, 2]
    bam[i, :] = dt[:, 3]
    ssm[i, :] = dt[:, 4]
    sam[i, :] = dt[:, 5]  
    ps[i, :] = dt[:, 6]
    mic[i, :] = dt[:, 7]
    vgen[i, :] = dt[:, 8]
    vpre[i, :] = dt[:, 9]
end 

writedlm("latent.dat", lm)
writedlm("bite_symp.dat", bsm)
writedlm("bite_asymp.dat", bam)
writedlm("sex_symp.dat", ssm)
writedlm("sex_asymp.dat", sam)

writedlm("preg_symp.dat", ps)
writedlm("micro.dat", mic)
writedlm("vac_general.dat", vgen)
writedlm("vac_pregnant.dat", vpre)





