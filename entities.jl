## to get
@enum HEALTH SUSC=1 LAT=2 ASYMP=3 SYMP=4 SYMPISO=5 REC=6 DEAD=7 UNDEF=0
@enum GENDER MALE=1 FEMALE=2

type Human
    health::HEALTH      # health status of the human
    swap::HEALTH
    age::Int64          # current age of the human
    ageofdeath::Int64   # time of death of the human
    gender::GENDER
    statetime::Int64
    timeinstate::Int64
    sickcnt::Int64      # how many times this person goes to latent
    sexonoff :: Bool
    partner::Int64      # the index of the partner in the lattice
    nextsevensex::Vector{Int64}  
end

type Mosq 
    health::HEALTH
    age::Int64
    ageofdeath::Int64
end


function setup_humans(a)
    ## intialize the array with empty values. 
    for i = 1:length(a)
        a[i] = Human(SUSC, UNDEF,    #health swap
                     -1, -1, MALE,   #age, ageofdeath, all males 
                      1000, 0,      #statetime, timeinstate
                      0,            #zero sick count
                      false, -1, [0, 0, 0, 0, 0, 0, 0])
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function setup_age(a)
    ## get the 3-tuple age: (probdistribution, agemin, agemax)
    d = distribution_age()    
    for i = 1:length(a)
        rn = rand()
        g = minimum(find(x -> rn <= x, d[1]))
        a[i].age = Int(round(rand()*(d[3][g] - d[2][g]) + d[2][g]))*365
    end 
end

## TO DO
function setup_ageofdeath(a)
    for i = 1:length(a)
        a[i].ageofdeath = a[i].age*2
    end
end




#### DEBUG ####


## how to get an array
## the fill! fucntion dosnt seem to be working. It adds the same instance to each element. 
#a = Array(Human, 2)
#fill!(a, Human(SUSC, -1, -1, -1, -1, [0, 0, 0, 0, 0, 0, 0]))

#change age
##a[1] = 20
#a[1] # outputs 20
#a[2] # ALSO outputs 20
