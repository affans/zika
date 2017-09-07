
numofdays = 182*8
lm = Matrix{Int64}(2000, numofdays)
bsm = Matrix{Int64}(2000, numofdays)
bam = Matrix{Int64}(2000, numofdays)
ssm = Matrix{Int64}(2000, numofdays)
sam = Matrix{Int64}(2000, numofdays)

# read each file
for i = 1:2000
    fn = string("simulation-", i, ".dat")
    dt = readdlm(fn, Int64)
    lm[i, :] = dt[:, 1] 
    bsm[i, :] = dt[:, 2]
    bam[i, :] = dt[:, 3]
    ssm[i, :] = dt[:, 4]
    sam[i, :] = dt[:, 5]    
end 

writedlm("latent.dat", lm)
writedlm("bite_symp.dat", bsm)
writedlm("bite_asymp.dat", bam)
writedlm("sex_symp.dat", ssm)
writedlm("sex_asymp.dat", sam)



