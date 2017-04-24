## to get
@enum HEALTH SUSC=1 LAT=2 ASYMP=3 SYMP=4 SYMPISO=5 REC=6 DEAD=7 UNDEF=0

type Human
    health::HEALTH      # health status of the human
    age::Int64          # current age of the human
    ageofdeath::Int64   # time of death of the human
    sickcnt::Int64      # how many times this person goes to latent
    sexonoff :: Bool
    partner::Int64      # the index of the partner in the lattice
    nextsevensex::Vector{Int64}
    recoveredfrom ::HEALTH
end

type Mosq 
    health::HEALTH
    age::Int64
    ageofdeath::Int64
end


function setup_humans(a)
    ## intialize the array with empty values. 
    for i = 1:length(a)
        a[i] = Human(SUSC, -1, -1, -1, false, -1, [0, 0, 0, 0, 0, 0, 0], UNDEF)
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function age_distribution(a)
    return 1
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
