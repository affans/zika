## to get
@enum HEALTH SUSC=1 LAT=2 ASYMP=3 SYMP=4 SYMPISO=5 REC=6 DEAD=7 UNDEF=0
@enum GENDER MALE=1 FEMALE=2

type Human
    health::HEALTH      # health status of the human
    swap::HEALTH
    age::Int64          # current age of the human
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
    statetime::Int64
    timeinstate::Int64
    infectionfrom::HEALTH
    numberofbites::Int64
end


function setup_humans(a)
    ## intialize the array with empty values. 
    for i = 1:length(a)
        a[i] = Human(SUSC, UNDEF,    #health swap
                     -1, MALE,   #age, all males 
                      1000, 0,      #statetime, timeinstate
                      0,            #zero sick count
                      false, -1, [0, 0, 0, 0, 0, 0, 0]) #sexonoff, partner index, frequency
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function setup_human_demographics(a)
    ## get the 3-tuple age: (probdistribution, agemin, agemax)
    d = distribution_age() # so d[1] dist, d[2] - age min, d[3] age max 
    ## get the male/female distribution
    m = distribution_gender()   
    for i = 1:length(a)
        #assign age and gender        
        rn = rand()
        g = minimum(find(x -> rn <= x, d[1]))
        age_y = Int(round(rand()*(d[3][g] - d[2][g]) + d[2][g]))
        a[i].age = age_y*365
        if rand() < m[age_y] 
            a[i].gender = MALE
        else 
            a[i].gender = FEMALE
        end
    end 
end

function setup_sexualinteraction(h)
    ## this fucntion assigns sexual partners. 
    ## if there are 24 males (over 15 years age), and 26(over 15 years) females, 
    ##   then all 24 males get a partner.
    ## 
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
            #delete the index from the female
            deleteat!(femalein, rnf)
        end        
    else 
        #more males, females will get saturated with partners
        for i in femalein
            rnf = rand(1:length(malein)) #get a random felame
            h[i].partner = malein[rnf] ## gets the rnf'th element which is an index of the female
            h[malein[rnf]].partner = i 
            #delete the index from the female
            deleteat!(malein, rnf)
        end  
    end 
end

function calculate_sexfrequency(i::Int64)
    #calculate sexual frequency
    return 1
end


function setup_mosquito_demographics(m)
    for i=1:length(m)
        rn = rand()

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

function howmany_malefemale(a)
    print("male: $(length(find(x -> x.gender == MALE, a))) \n")
    print("female: $(length(find(x -> x.gender == FEMALE, a))) \n")
    print("male (over 15): $(length(find(x -> x.gender == MALE && x.age >= 5475, a))) \n")
    print("female (over 15): $(length(find(x -> x.gender == FEMALE && x.age >= 5475, a))) \n")
end

function test_sexualpartners(h)
    malein = find(x -> x.gender == MALE && x.partner > 0, h)
    femalein = find(x -> x.gender == FEMALE && x.partner > 0, h)
    
    ## should be equal
    assert(length(malein) == length(femalein))

    for i=1:length(h) ## go through all, optimization not neccesary, its a test
        if h[i].partner > 0  ## partner is assigned
            partnerindex = h[i].partner
            if i != h[partnerindex].partner
                print("partner different at $i and $partnerindex")
            end
        end
    end 
end