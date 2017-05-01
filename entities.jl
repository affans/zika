type Human
    health::HEALTH      # health status of the human
    swap::HEALTH
    age::Int64          # current age of the human
    gender::GENDER
    statetime::Int64
    timeinstate::Int64    
    sexonoff :: Bool    # turn this one when the person gets infected
    partner::Int64      # the index of the partner in the lattice
    sexfrequency::Int64 # sex frequency, dosnt get used if sexonoff stays false
end

type Mosq 
    health::HEALTH
    swap::HEALTH
    age::Int64
    ageofdeath::Int64
    statetime::Int64
    timeinstate::Int64
    infectionfrom::HEALTH
    numberofbites::Int64
    bitedistribution::Array{Int64}
end


function setup_humans(a)
    ## intialize the array with empty values. 
    ## everyone stats as susceptible, swap is set to null. 
    ## statetime is 999 (longer than 2 year sim time), timeinstate is 0. !
    for i = 1:length(a)
        a[i] = Human(SUSC, UNDEF,    #health swap
                     -1, MALE,       #age, all males 
                      999, 0,        #statetime, timeinstate      
                      false, -1, -1) #sexonoff, partner index, number of sex
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function setup_human_demographics(a) # to-do: nothing
    ## get the 3-tuple age: (probdistribution, agemin, agemax)
    d = distribution_age() # so d[1] dist, d[2] - age min, d[3] age max 
    ## get the male/female distribution
    m = distribution_gender()   
    for i = 1:length(a)
        #assign age and gender        
        rn = rand()
        g = minimum(find(x -> rn <= x, d[1]))
        age_y = Int(round(rand()*(d[3][g] - d[2][g]) + d[2][g]))
        a[i].age = age_y*364
        if rand() < m[age_y] 
            a[i].gender = MALE
        else 
            a[i].gender = FEMALE
        end
        a[i].sexonoff = false ## turn of sex for all
    end 
end

function setup_sexualinteraction(h)
    ## incoming parameter: h -- an array of initialized humans

    ## assign everyone sexual frequency. the function returns 0 if age < 15, so dont deal with it now
    map(x -> x.sexfrequency = calculatesexfrequency(x.age, x.gender), h);
    
    ## next, assign sexual partners. -- logic of this:
    ## if there are 24 males (over 15 years age), and 26(over 15 years) females, 
    ##   then all 24 males get a partner.
    ## if a human is being assigned a partner, randomly give him/her number of times of sex
    ## age 15 in days in 5475
    cntmale = length(find(x -> x.gender == MALE && x.age >= 5475, h))
    cntfemale = length(find(x -> x.gender == FEMALE && x.age >= 5475, h))
    malein = find(x -> x.gender == MALE && x.age >= 5475, h)
    femalein = find(x -> x.gender == FEMALE && x.age >= 5475, h)
    if cntmale <= cntfemale
        #more females, males will get saturated with partners
        for i in malein
            rnf = rand(1:length(femalein)) #get a random felame
            h[i].partner = femalein[rnf] ## gets the rnf'th element which is an index of the female
            h[femalein[rnf]].partner = i         ## assign the opposite gender            
            deleteat!(femalein, rnf) #delete the index from the female        
        end        
    else 
        #more males, females will get saturated with partners
        for i in femalein
            rnf = rand(1:length(malein)) #get a random felame
            h[i].partner = malein[rnf] ## gets the rnf'th element which is an index of the female
            h[malein[rnf]].partner = i             
            deleteat!(malein, rnf) #delete the index from the female
        end  
    end 
end

function setup_mosquitos(m)   
    for i = 1:length(m)
        m[i] = create_mosquito()
        m[i].age = rand(1:m[i].ageofdeath)  ## for setting up the world, give them random age
    end    
end



function create_mosquito()
    ## intialize the array with empty values. 
    ## all mosquitos start as susceptible, swap is set to null, and infectionfrom is set to null
    m = Mosq(SUSC, UNDEF, -1, -1, 999, 0, UNDEF, -1, [])  ## initialization
    ## setup the age of death - distribution should already be created .. pick the right one
    d = current_season == SUMMER ? sdist_lifetimes : wdist_lifetimes  ## current_season defined as a global in main.jl
    rn = rand()
    m.ageofdeath =  minimum(find(x -> rn <= x, d))        
    m.age = 1    ## new mosquito is 1 day old (this is because the way sim logic works)
    m.numberofbites = min(rand(Poisson(m.ageofdeath/2)), m.ageofdeath)
    
    # bite distribution
    temp_bitedist = zeros(Int64, m.ageofdeath)  ## create a vector as long as age of death
    s = sample(1:m.ageofdeath, m.numberofbites, replace=false)   # sample, which indices(ie days) can a mosquito bite
    map(x -> temp_bitedist[x] = 1, s)
    m.bitedistribution = temp_bitedist
    return m
end


## this function distributes the number of bites into an array
function setup_mosquitobite_distribution()
    ## for every mosquito, take its number of bites
    return 1
end

function calculatesexfrequency(age::Int64, sex::GENDER)
    ## this function calculates sex frequency based on the distribution
    # first we need to get the age group  - this is a number between 1 and 8 -
    ag = get_age_group(age)     ## get the agegroup
    if ag == 0   # if age group 1 - 15
        return 0
    end
    mfd, wfd = distribution_sexfrequency()  ## get the distributions
    rn = rand() ## roll a dice
    sexfreq = 0
    if sex == MALE 
        sexfreq = minimum(find(x -> rn <= x, mfd[ag]))   #if male, use the male distribution
    else 
        sexfreq = minimum(find(x -> rn <= x, wfd[ag]))   #if female, use the female distribution
    end
    return sexfreq
end




#### DEBUG ####a


## how to get an array
## the fill! fucntion dosnt seem to be working. It adds the same instance to each element. 
#a = Array(Human, 2)
#fill!(a, Human(SUSC, -1, -1, -1, -1, [0, 0, 0, 0, 0, 0, 0]))

#change age
##a[1] = 20
#a[1] # outputs 20
#a[2] # ALSO outputs 20
