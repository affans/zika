## test code -- scratch pad.. not part of the main simulations

include("main.jl")
using Base.Test 


using Plots

include("main.jl")
 ## the grids for humans and mosquitos

cn = countries() 
#male/female dataframes
dfm = DataFrame()
dff = DataFrame()

#df[:countries] = cn
for (i, c) in enumerate(cn)
    P = ZikaParameters(preimmunity = 0, transmission = 1.0, coverage_pregnant=0.05, coverage_general=0.0, preg_percentage=1.0, country=c)
    !(P.country in countries()) && error("Country not defined for model");   

    sm = zeros(Int64, 15, 100)
    sf = zeros(Int64, 15, 100)
    for sim in 1:100
        humans = Array{Human}(P.grid_size_human)
        mosqs  = Array{Mosq}(P.grid_size_mosq)
        # simulation setup functions
        setup_humans(humans)                      ## initializes the empty array
        setup_human_demographics(humans, P)          ## setup age distribution, male/female 
        setup_preimmunity(humans, P)
        setup_pregnant_women(humans, P)           ## setup pregant women according to distribution 
        
        ## 17 age brackets
        m_tmparr = zeros(Int64, 15)
        f_tmparr = zeros(Int64, 15)
    
        malecnt = find(x -> x.gender == MALE, humans)
        femalecnt = find(x -> x.gender == FEMALE, humans)
        
        for (j, m) in enumerate(malecnt)
            m_tmparr[humans[m].agegroup] += 1
        end
        
        for (j, m) in enumerate(femalecnt)
            f_tmparr[humans[m].agegroup] += 1        
        end    
        sm[:, sim] = m_tmparr
        sf[:, sim] = f_tmparr
    end
    tmp = Array{Float64}(15)    
    dfm[Symbol(c)] = reshape(sum(sm, 2)/100, (15, ))
    dff[Symbol(c)] = reshape(sum(sf, 2)/100, (15, ))
end
dfm[:agegroup] = 1:15
dff[:agegroup] = 1:15

maleplot = dff |>
@vlplot(repeat={row=Symbol.(countries())}) +
(
    @vlplot(width=400, height=400) + 
    @vlplot(
        :bar,
        title = {repeat=:row},
        y={field={repeat=:row},typ=:quantitative},
        x={"agegroup:n", title="Age Group"},       
        opacity={value=0.2}
    ) 
)
save("femaleplot.pdf", maleplot)

dfp[Symbol(P.country)] = length(find(x-> x.gender == FEMALE && x.age >= 15 && x.age <= 49 && x.ispregnant == true , humans))
P = ZikaParameters(preimmunity = 0, transmission = 1.0, coverage_pregnant=0.05, coverage_general=0.0, preg_percentage=1.0, country="Colombia")
!(P.country in countries()) && error("Country not defined for model");
humans = Array{Human}(P.grid_size_human)
mosqs  = Array{Mosq}(P.grid_size_mosq)
# simulation setup functions
setup_humans(humans)                      ## initializes the empty array
setup_human_demographics(humans, P)          ## setup age distribution, male/female 
setup_preimmunity(humans, P)
setup_pregnant_women(humans, P)           ## setup pregant women according to distribution 

for i in 1:length(humans)
    println(humans[i].age)
end


using VegaLite, VegaDatasets

dataset("cars") 
@vlplot(
    :point,
    x=:Horsepower,
    y=:Miles_per_Gallon,
    color=:Origin,
    width=400,
    height=400
)

using DataFrames
using CSV

df = CSV.read("transmissions.csv", )



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