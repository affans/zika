
cn = "/Colombia"
par = "/Asymp10Iso50_Coverage00Pre1"
path = string("../Zika Vaccine/results_july10", cn, par)

latent = readdlm("$path/latent.dat")
dayavg = DataFrame(x = 1:364, y=squeeze(mean(latent, 1)', 2))

dayavg |> @vlplot(:line, x=:x, y=:y)

df = DataFrame(latent)
df |> @vlplot(:line)

using VegaLite, VegaDatasets
dataset("cars") |>
@vlplot(
    :point,
    x=:Horsepower,
    y=:Miles_per_Gallon,
    color=:Origin,
    width=400,
    height=400
)

using DataFrames
latent = readdlm("../Zika Vaccine/Zika Vaccine Americas/Results_July15/Colombia/Asymp90Iso0_Coverage00Pre0/latent.dat")
bitesymp = readdlm("../Zika Vaccine/Zika Vaccine Americas/Results_July15/Colombia/Asymp10Iso0_Coverage00Pre0/bitesymp.dat")
sexsymp = readdlm("../Zika Vaccine/Zika Vaccine Americas/Results_July15/Colombia/Asymp10Iso0_Coverage00Pre0/sexsymp.dat")
biteasymp = readdlm("../Zika Vaccine/Zika Vaccine Americas/Results_July15/Colombia/Asymp10Iso0_Coverage00Pre0/biteasymp.dat")
sexasymp = readdlm("../Zika Vaccine/Zika Vaccine Americas/Results_July15/Colombia/Asymp10Iso0_Coverage00Pre0/sexasymp.dat")


latent = readdlm("../Zika Vaccine/Zika Vaccine Americas/results july 19/Asymp100Iso0_Coverage00Pre0_0-2/latent.dat")

h1 = 0;
S0 = 10000
idx1 = zeros(Int64, 2000)
# loop through each row
for i=1:2000
    K1 = sum(latent[i,1:364]);
    if (K1>=1)
        idx1[i]=i;
        h1=h1+1;
    else
        idx1[i]=0;
    end
end
Wave1=find(x -> x>0, idx1);


# attack rate 
Attack = zeros(Float64, length(Wave1))
for i=1:length(Wave1)
    TotalInc=sum(latent[Wave1[i],:]);
    Attack[i]=TotalInc/S0;
end
OverallAttackRate=mean(Attack)


## shorter Julia code
rowsums = sum(latent[:, 1:365], 2)  ## get the number of latents over the first year
idx = find(x -> x >= 1, rowsums) ## find all sims that are above 100 latent individuals
sums = map(x -> sum(latent[x,:])/10000, idx) ## sum up the latents and take mean
mean(sums)*100



function read_folders()
    a = readdir("./")
    df = DataFrame(transmission = Float64[], attackrate = Float64[]) 
    #d= Dict{Float64, Float64}()
    r = map(a) do x
        #lfile = readdlm("./$x/latent.dat")        
        latent = readdlm("./$x/latent.dat")
        rowsums = sum(latent[:, 1:365], 2)  ## get the number of latents over the first year
        idx = find(x -> x >= 0, rowsums) ## find all sims that are above 100 latent individuals
        sums = map(x -> sum(latent[x,:])/10000, idx) ## sum up the latents and take mean      
        #d[parse(Float64, split(x,  "-")[2])] =  mean(sums)*100
        push!(df, [parse(Float64, split(x,  "-")[2])  mean(sums)])
    end
    return df
end

using GLM 
using DataFrames
using CSV
using Queryverse
using Query
using TermWin
function regress()
    df = CSV.read("attackrates.dat")
    df[:ttwo] = df[:transmission] .* df[:transmission]
    x = @from i in df begin
        @where i.attackrate < 0.25
        @select i
        @collect DataFrame        
    end

    df[:transmission] = df[:transmission] ./ 10.^(length.(string.(convert(Array{Int64}, df[:transmission]))))
    
    
    ols = lm(@formula(attackrate ~ transmission), df)
    predict(ols, DataFrame([ll = 2]))

    lineplot(df[:transmission], convert(Array{Float64}, df[:attackrate]))
   
    df |> 
    @vlplot(
        :line,
        x=:transmission,
        y=:attackrate,        
        width=400,
        height=400
    )


end

