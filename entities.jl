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
        a[i].age = age_y*365
        if rand() < m[age_y] 
            a[i].gender = MALE
        else 
            a[i].gender = FEMALE
        end
        a[i].sexonoff = false ## turn of sex for all
    end 
end

function setup_sexualinteraction(h)
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
    ## intialize the array with empty values. 
    ## all mosquitos start as susceptible, swap is set to null. 
    for i = 1:length(m)
        m[i] = Mosq(SUSC, UNDEF,    #health swap
                     -1, -1,       #age, ageofdeath 
                      999, 0,        #statetime, timeinstate      
                      UNDEF, -1)     # infection from, numbers of bites.
    end
    ## get the number of bites for this mosquito using a poisson distribution
    map(x -> x.numberofbites = rand(Poisson(x.age/2)), m)
end

function setup_mosquitobites()
    ## this function distributes the mosquito age
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
