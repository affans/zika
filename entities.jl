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
    for i = 1:length(a)
        @inbounds a[i] = Human()     
    end  # or use a = [Human(SUSC) for i in 1:2]    
end

function setup_human_demographics(a::Array{Human}, P::ZikaParameters)
    agemin, agemax = age_brackets()  ## get the age brackets
    md, fd = age_distribution()      ## get the age_distribution
    male = md[P.country]
    female = fd[P.country]
    @inbounds for i = 1:length(a)
        #assign age and gender        
        if rand() < 0.5 #dist_gend[g] 
            a[i].gender = MALE  
            rn = rand()          
            g = findfirst(x -> rn <= x, male)
            age_y = rand(agemin[g]:agemax[g])#Int(round(rand()*(agemax[g] - agemin[g]) + agemin[g]))
            a[i].age = age_y
            a[i].agegroup = g
        else 
            a[i].gender = FEMALE     
            rn = rand()       
            g = findfirst(x -> rn <= x, female)
            age_y = rand(agemin[g]:agemax[g])#Int(round(rand()*(agemax[g] - agemin[g]) + agemin[g]))
            a[i].age = age_y
            a[i].agegroup = g
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
                ctr += 1
            end
        end
    end
    return ctr
end

function setup_pregnant_women(h::Array{Human}, P::ZikaParameters)    
    totalpreg = zeros(Int64, 7)
    propvec = fertility_distribution()[P.country]
    a = findall(x -> x.gender == FEMALE && x.age >= 15 && x.age <= 19, h)
    ag = Int(round(propvec[1]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[1] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 20 && x.age <= 24, h)
    ag = Int(round(propvec[2]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[2] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 25 && x.age <= 29, h)
    ag = Int(round(propvec[3]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[3] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 30 && x.age <= 34, h)
    ag = Int(round(propvec[4]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[4] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 35 && x.age <= 39, h)
    ag = Int(round(propvec[5]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[5] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 40 && x.age <= 44, h)
    ag = Int(round(propvec[6]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[6] += 1
    end
    a = findall(x -> x.gender == FEMALE && x.age >= 45 && x.age <= 49, h)
    ag = Int(round(propvec[7]*length(a)))
    for ii = 1:ag        
        h[a[ii]].ispregnant = true
        h[a[ii]].timeinpregnancy = rand(0:270)
        totalpreg[7] += 1
    end
    return totalpreg
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
        genpop_males = findall(x -> (x.age >= 9 && x.age <= 60) && x.gender == MALE, h)

        for i = 1:length(genpop_males)
            rn = rand()
            if rn < P.coverage_general
                h[genpop_males[i]].isvaccinated = true
                h[genpop_males[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end

        genpop_females = findall(x -> ((x.age >= 9 && x.age < 15) || (x.age > 49 && x.age <= 60)) && (x.gender == FEMALE), h)
        for i = 1:length(genpop_females)
            rn = rand()
            if rn < P.coverage_general
                h[genpop_females[i]].isvaccinated = true
                h[genpop_females[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end
    
        nonpreg_women = findall(x -> x.gender == FEMALE && (x.age >= 15 && x.age <= 49) && x.ispregnant == false, h)
        for i = 1:length(nonpreg_women)                   
            rn = rand()
            if rn < P.coverage_reproductionAge
                h[nonpreg_women[i]].isvaccinated = true
                h[nonpreg_women[i]].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)
                genvac += 1
            end
        end
        
        preg_women = findall(x -> x.gender == FEMALE && x.age >= 15 && x.age <= 49 && x.ispregnant == true && x.isvaccinated == false, h)
        ## women who didn't get vaccinated before and is pregnant has another probability of vaccination.
        for i = 1:length(preg_women)  
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
    malein = findall(x -> x.gender == MALE && x.age >= 15, h)
    femalein = findall(x -> x.gender == FEMALE && x.age >= 15, h)

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
        suitable_filtered = suitable[findall(x -> x > 0, suitable)]
        
        ## if there is no suitable partner.. BUT PARTNERS REMAIN since we are working with a smaller index, store this person in an array, and we'll assign later.
        if length(suitable_filtered) == 0
            ## for this i'th human, we dont have a suitable partner.. we'll assign a random one later on
            push!(missedindex, i)
        else 
            ## this i'th person has a suitable partner to pick from
            rnf = suitable_filtered[rand(1:length(suitable_filtered))]
            h[i].partner = rnf            
            h[rnf].partner = i

            # need to delete from the largerindex
            #  first find what index this human is in the largerindex
            idxtodelete = findfirst(x -> x == rnf, largerindex)
            deleteat!(largerindex, idxtodelete)
        end        
    end

    ## go through the missing index.. these were humans that couldnt find partners
    ## go through all of them, and assign them random partners from the largerindex
    ##  first check if this is even possible
    if length(largerindex) < length(missedindex)
        error("error in sexual interaction function")        
    end

    @inbounds for i in missedindex
        rnf = rand(1:length(largerindex))
        h[i].partner = largerindex[rnf]
        h[largerindex[rnf]].partner = i
        deleteat!(largerindex, rnf)
    end
    return smallerindex
end

## make a random person latent 
function setup_rand_initial_latent(h::Array{Human}, P::ZikaParameters)
    cnt = 0
    for i=1:P.inital_latent
      randperson = rand(1:P.grid_size_human)
      make_human_latent(h[randperson], P)
      cnt += 1
    end
    return cnt
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
    m.ageofdeath =  findfirst(x -> rn <= x, d)        
    m.age = 0   ## new mosquito is 1 day old (this is because the way sim logic works)
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
        a = findall(x -> x == i, lt)
        test[i] = length(a)/P.grid_size_mosq
    end
    ## create a cumlative
    ctest = cumsum(test)
   
    for i=1:P.grid_size_mosq
        rn = rand()
        age = minimum(findall(x -> rn <= x, ctest))
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
