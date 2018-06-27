## entities.jl - functions on setting up the mosquito and human vectors

mutable struct Human
    health::HEALTH      # health status of the human
    swap::HEALTH
    latentfrom::Int64   ## 1 if bite, 2 if sexual
    age::Int64          # current age of the human
    agegroup::Int64     # agegroup - for age distribution
    gender::GENDER
    statetime::Int64
    timeinstate::Int64 
    recoveredfrom::HEALTH      
    partner::Int64      # the index of the partner in the lattice
    sexfrequency::Int64 # sex frequency
    sexprobability::Float64  ## dont think i need this
    cumalativesex::Int64
    cumalativedays::Int64
    ## pregnancy 
    ispregnant::Bool 
    timeinpregnancy::Int64
    ## vaccination
    isvaccinated::Bool 
    protectionlvl::Float64 ## reduction in transmission by vaccine

    Human() = new(SUSC, UNDEF, 0, -1, -1, MALE, 999, 0, UNDEF, -1, -1, -1, -1, -1, false, -1, false, 0)
end

mutable struct Mosq 
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


function setup_humans(a::Array{Human})
    #print("running human setup on process: $(myid()) \n")
    ## intialize the array with empty values. 
    ## everyone stats as susceptible, swap is set to null. 
    ## statetime is 999 (longer than 2 year sim time), timeinstate is 0. !
    @simd for i = 1:length(a)
        @inbounds a[i] = Human()     
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function setup_human_demographics(a::Array{Human}) 
    ## get the 3-tuple age: (probdistribution, agemin, agemax)
    cumdist, dist_gend, agemin, agemax = distribution_age() 
    @inbounds for i = 1:length(a)
        #assign age and gender        
        rn = rand()
        g = findfirst(x -> rn <= x, cumdist)
        age_y = rand(agemin[g]:agemax[g])#Int(round(rand()*(agemax[g] - agemin[g]) + agemin[g]))
        a[i].age = age_y
        a[i].agegroup = g
        if rand() < 0.5 #dist_gend[g] 
            a[i].gender = MALE
        else 
            a[i].gender = FEMALE
        end        
    end 
end

function setup_preimmunity(h::Array{Human}, P::ZikaParameters)
    ctr = 0 
    cov = P.preimmunity
    if cov > 0 
        @inbounds for i = 1:length(h)
            if rand() < cov 
                h[i].protectionlvl = P.preimmunity_protectionlvl
            end
        end
    end
    return ctr
end



function setup_pregnant_women(h::Array{Human}, P::ZikaParameters)
    ## get the number of eligible, this is too slow just use loop/if
    sd = find(x -> x.gender == FEMALE && x.age >= 15 && x.age <= 49, h)
    totalnumber = length(sd)*(44*0.75 + 120*0.167)/1000 ## parameters from seyed

    ## for each agegroup, probability of a falling in an age group
    probvec = [0.2082, 0.2996, 0.2385, 0.1470, 0.0773, 0.0254, 1-(0.2082+0.2996+0.2385+0.1470+0.0773+0.0254)]
    pd = Categorical(probvec)

    ## go through all the people we have to make pregnant
    @inbounds for i=1:totalnumber
        ## which age group to make pregnant
        ag = rand(pd)
        @match ag begin
            1 => begin
                    minage = 15
                    maxage = 19 
                 end 
            2 => begin
                    minage = 20
                    maxage = 24 
                end 
            3 => begin
                    minage = 25
                    maxage = 29 
                 end 
            4 => begin
                    minage = 30
                    maxage = 34
                 end 
            5 => begin
                    minage = 35
                    maxage = 39
                 end 
            6 => begin
                    minage = 40
                    maxage = 44 
                 end 
            7 => begin
                    minage = 45
                    maxage = 49 
                 end 
            _ => println("default")
        end
        ## find a random human id in the correct age group
        a =find(x -> x.gender == FEMALE && x.age >= minage && x.age <= maxage, h)
        if length(a) > 0 
            aid = rand(a)
            h[aid].ispregnant = true
            h[aid].timeinpregnancy = rand(0:270)
        end        
    end
end

function setup_vaccination(h::Array{Human}, P::ZikaParameters)
    ## go through different subgroups of populations, and vaccinate the groups
    ## 1) 60% coverage of women in reproductive age (pregnant or non-pregnant)
    ## 2) any women not vaccinated previously and is pregnant or becomes pregnant, 80% coverage
    ## 3) any woman on other age (9 - 15, 49+), or all men (9-60) are 10%

	genvac = 0
    prevac = 0

    ## first check if there is even coverage to be had 
    if (P.coverage_general + P.coverage_pregnant + P.coverage_reproductionAge) > 0      
        ## find all general_population males 
        genpop_males = find(x -> (x.age >= 9 && x.age <= 60) && x.gender == MALE, h)

        for i = 1:length(genpop_males)
            rn = rand()
            if rn < P.coverage_general
                h[genpop_males[i]].isvaccinated = true
                h[genpop_males[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end

        genpop_females = find(x -> ((x.age >= 9 && x.age < 15) || (x.age > 49 && x.age <= 60)) && (x.gender == FEMALE), h)
        for i = 1:length(genpop_females)
            rn = rand()
            if rn < P.coverage_general
                h[genpop_females[i]].isvaccinated = true
                h[genpop_females[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end
    
        nonpreg_women = find(x -> x.gender == FEMALE && (x.age >= 15 && x.age <= 49) && x.ispregnant == false, h)
        for i = 1:length(nonpreg_women)                   
            rn = rand()
            if rn < P.coverage_reproductionAge
                h[nonpreg_women[i]].isvaccinated = true
                h[nonpreg_women[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end
        
        preg_women = find(x -> x.gender == FEMALE && x.age >= 15 && x.age <= 49 && x.ispregnant == true && x.isvaccinated == false, h)
        for i = 1:length(preg_women)   ###who didn't get vaccinated before and is pregnant has another probability of vaccination.
            rn = rand()
            if rn < P.coverage_pregnant
                h[preg_women[i]].isvaccinated = true
                h[preg_women[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                prevac += 1
            end
        end
    end
    return genvac, prevac
end

function setup_sexualinteractionthree(h::Array{Human})  
    ## assign everyone sexual frequency. the function returns 0 if age < 15, so dont deal with it now
    map(x -> x.sexfrequency = calculatesexfrequency(x.age, x.gender), h);
    
    ## get the indices of all the eligible males and females
    malein = find(x -> x.gender == MALE && x.age >= 15, h)
    femalein = find(x -> x.gender == FEMALE && x.age >= 15, h)

    cntmale = length(malein)
    cntfemale = length(femalein)

    ## inline if statement.. if cntmale < cntfemale, use malein as the masterindex
    ## this masterindex contains the humans that could be saturated
    smallerindex = cntmale <= cntfemale ? malein : femalein
    largerindex  = cntmale > cntfemale ? malein : femalein
    missedindex = Int64[] # => 0-element Int64 Array, for people who dont get assigned a sexual partner.
    # GO THROUGH THE SMALLER INDEX
    @inbounds for i in smallerindex
        ## i is the i'th human that needs a partner.
        ag = h[i].age
        ## find all persons from the largerindex (opposite sex) from the master list, that are suitable..
        ## this returns the index of the human that is suitable. 
        # if the human is not suitable, it returns -1
        suitable = map(x -> h[x].age >= ag - 5 && h[x].age < ag + 5 ? x : -1, largerindex)
       
        # length of suitable is same as largerindex BUT non suitables are marked -1
        #  thus we only need to look at humans that are marked larger than -1
        #  the find function returns INDICES...so run it inside suitable[] to get the HUMAN  index back
        suitable_filtered = suitable[find(x -> x > 0, suitable)]
        
        ## if there is no suitable partner.. BUT PARTNERS REMAIN since we are working with a smaller index, store this person in an array, and we'll assign later.
        if length(suitable_filtered) == 0
            ## for this i'th human, we dont have a suitable partner.. we'll assign a random one
            push!(missedindex, i)
        else 
            ## this i'th person has a stuiable partner to pick from
            rnf = suitable_filtered[rand(1:length(suitable_filtered))]
            h[i].partner = rnf            
            h[rnf].partner = i

            # need to delete from the largerindex
            #  first find what index this human is in the largerindex
            idxtodelete = find(x -> x == rnf, largerindex)
            deleteat!(largerindex, idxtodelete)
        end        
    end

    ## go through the missing index.. these were humans that couldnt find partners
    ## go through all of them, and assign them random partners from the largerindex
    ##  first check if this is even possible
    if length(largerindex) < length(missedindex)
        print("error in sexual interaction")
        assert(1 == 2)
    end

    @inbounds for i in missedindex
        rnf = rand(1:length(largerindex))
        h[i].partner = largerindex[rnf]
        h[largerindex[rnf]].partner = i
        deleteat!(largerindex, rnf)
    end
    #return missedindex
end

## make a random person latent 
function setup_rand_initial_latent(h::Array{Human}, P::ZikaParameters)
    for i=1:P.inital_latent
      randperson = rand(1:P.grid_size_human)
      make_human_latent(h[randperson], P)
    end
end

function setup_mosquitos(m, current_season)   
    ## incoming parameter m is the array of Mosquito Type
    for i = 1:length(m)
        m[i] = create_mosquito(current_season)
        #m[i].age = rand(min(5, m[i].ageofdeath):m[i].ageofdeath)  ## for setting up the world, give them random age
    end    
end


function create_mosquito(current_season)
    ## intialize the array with empty values. 
    ## all mosquitos start as susceptible, swap is set to null, and infectionfrom is set to null
    m = Mosq(SUSC, UNDEF, -1, -1, 999, 0, UNDEF, -1, [])  ## initialization
    ## setup the age of death - distribution should already be created .. pick the right one
    local d::Array{Float64, 1} 
    d = current_season == SUMMER ? sdist_lifetimes : wdist_lifetimes  ## current_season defined as a global in main.jl
    rn = rand()
    m.ageofdeath =  minimum(find(x -> rn <= x, d))        
    m.age = 1   ## new mosquito is 1 day old (this is because the way sim logic works)
    m.numberofbites = min(rand(Poisson(m.ageofdeath/2)), m.ageofdeath)
    
    # bite distribution
    temp_bitedist = zeros(Int64, m.ageofdeath)  ## create a vector as long as age of death
    s = sample(1:m.ageofdeath, m.numberofbites, replace=false)   # sample, which indices(ie days) can a mosquito bite
    map(x -> temp_bitedist[x] = 1, s)
    m.bitedistribution = temp_bitedist
    return m
end

function setup_mosquito_random_age(m, P::ZikaParameters)
    ## pass in mosquito array 
    ## first create a frequnecy distribution based on their lifetimes
    lt = map(x -> x.ageofdeath, m)
    test = zeros(Float64, maximum(lt))
    for i=1:maximum(lt)
        a = find(x -> x == i, lt)
        test[i] = length(a)/P.grid_size_mosq
    end
    ## create a cumlative
    ctest = cumsum(test)
   
    for i=1:P.grid_size_mosq
        rn = rand()
        age = minimum(find(x -> rn <= x, ctest))
        tage = max(1, min(age, m[i].ageofdeath - 1))
        m[i].age = tage
    end
    return nothing
end


function increase_mosquito_age(m::Array{Mosq}, current_season)
    #print("increasemosquitoage() from process: $(myid()) \n")
    ## day is starting, increase age by one of mosquitos
    # print("current season: $current_season \n")
    @inbounds for i=1:length(m)
        m[i].age += 1
        if m[i].age > m[i].ageofdeath 
           @inbounds m[i] = create_mosquito(current_season)
        end 
    end
    return nothing
end

function pregnancy_and_vaccination(h::Array{Human}, P::ZikaParameters)
    ## this increases the time in pregnancy for women by 1 day. If it reaches 270 days, a baby is born - this does not need to be recorded (as you can get this from pregnant women). At 270 days, we find another nonpregnant women (in the same age group) and make them pregnant with timeinpregnancy = 0
    ## As the new person is becoming pregnant, vaccinate them if they have not been vaccinated before. if the vaccination coverage is set to zero, no one will get vaccinated according to this code. 
    ## The function returns the the number of vaccinated pregnant women (ie, if a women is becoming pregnant and also gets vaccination, we return this function) 

    numbervaccinated = 0
    @inbounds for i=1:length(h)
        if h[i].ispregnant == true
            h[i].timeinpregnancy += 1 
            if h[i].timeinpregnancy == 270
                ag = get_age_group(h[i].age)
                sd = find(x -> x.gender == FEMALE && x.agegroup == ag && x.ispregnant != true, h)
                if length(sd) > 0 
                    randfemale = rand(sd)
                    h[randfemale].ispregnant = true
                    h[randfemale].timeinpregnancy = 0
                    if h[randfemale].isvaccinated == false && rand() < P.coverage_pregnant
                        h[randfemale].isvaccinated = true
                        h[randfemale].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)                       
                        numbervaccinated += 1                        
                    end
                end                
            end
        end        
    end  
    return numbervaccinated
end


#### DEBUG ####a
#
#a = find(x -> x.health != SUSC, humans)
#map(x -> print("$(humans[x].statetime) : \n"), a)

## how to get an array
## the fill! fucntion dosnt seem to be working. It adds the same instance to each element. 
#a = Array(Human, 2)
#fill!(a, Human(SUSC, -1, -1, -1, -1, [0, 0, 0, 0, 0, 0, 0]))

#change age
##a[1] = 20
#a[1] # outputs 20
#a[2] # ALSO outputs 20
