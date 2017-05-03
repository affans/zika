## this file contains housekeeping functions.


function howmany_malefemale(a)
    print("male: $(length(find(x -> x.gender == MALE, a))) \n")
    print("female: $(length(find(x -> x.gender == FEMALE, a))) \n")
    print("male (over 15): $(length(find(x -> x.gender == MALE && x.age >= 15, a))) \n")
    print("female (over 15): $(length(find(x -> x.gender == FEMALE && x.age >= 15, a))) \n")
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

function get_age_group(age::Int64)
    ## this agegroup is a "condensed version" from the age distribution
    ## this is mainly used for sex frequency
    agegroup = -1
    if age >=0 && age < 15 
        agegroup = 0
    elseif age >= 15 && age < 25
        agegroup = 1
    elseif age >= 25 && age < 30
        agegroup = 2
    elseif age >= 30 && age < 40
        agegroup = 3
    elseif age >= 40 && age < 50 
        agegroup = 4 
    elseif age >= 50 && age < 60 
        agegroup = 5 
    elseif age >= 60 && age < 70        
        agegroup = 6 
    elseif age >= 70
        agegroup = 7
    end 
    return agegroup
end

function test_getagegroup(human)
    # get an array of the age groups in humans
    a = map(x -> get_age_group(x.age), human )
    l = length(find(x -> x == -1, a))
    if l == 0 
        print("get_age_group function is good")
    else 
        print("get_age_group function is good")
    end

    #compare the same code to below
    #for i=1:length(human)
    #    if(get_age_group(human[i].age) == 0)
    #        print(i)
    #    end
    #end 
end



function test_mosquito_hazard_function()
    #get the distribution from the parameters.jl file
    summer_dist, winter_dist = distribution_hazard_function()
    summer_lifetimes = zeros(Int64, 100000)
    winter_lifetimes = zeros(Int64, 100000)

    ## get sample "lifetimes" for summer
    #method 1
    
    for i = 1:100000
        rn = rand()
        summer_lifetimes[i] = minimum(find(x -> rn <= x, summer_dist))
        winter_lifetimes[i] = minimum(find(x -> rn <= x, winter_dist))
    end
    ms = mean(summer_lifetimes)
    mw = mean(winter_lifetimes)
    print("mean of summer lifetimes: $ms \n") 
    print("mean of winter lifetimes: $mw \n")
end


function test_mosquito_numberofbites_and_lifetime(m)
    ## two tests in this
    #  1) check if the length of the bitedistribution vector is the same as age of death
    #  2) and check for each bitedistribution vector, the number of "ones" in the vector are equal to the number of bites
    t1 = map(x -> length(x.bitedistribution) == x.ageofdeath, m)
    t1c = length(find(x -> false, t1))
    if t1c != 0 
        print("test 1 failed. \n")
    else
        print("test 1 passed. \n") 
    end 
    t2fail=false
    for i=1:length(m)
        tbd= m[i].bitedistribution
        numofbites = m[i].numberofbites
        tbdc = length(find(x -> x == 1, tbd))
        if tbdc != numofbites
            t2fail = true
        end
    end
    if t2fail
        print("test 2 failed. \n")
    else
        print("test 2 passed. \n") 
    end
end

#method 1
#agd = zeros(Int64, 50000)
#for i = 1:50000
 #   rn = rand()
#    agd[i] = minimum(find(x -> rn <= x, a))
#end
#method 2
#ag = [findfirst(a, sample(a)) for i=1:5000]
  
#ap = plot(x=a, Geom.histogram)
#draw(PDF("myplot.pdf", 3inch, 3inch), ap)


function setup_sexualinteraction_deprecated(h)
    ## incoming parameter: h -- an array of initialized humans

   
    ## assign everyone sexual frequency. the function returns 0 if age < 15, so dont deal with it now
    map(x -> x.sexfrequency = calculatesexfrequency(x.age, x.gender), h);
    ## next, assign sexual partners. -- logic of this:
    ## if there are 24 males (over 15 years age), and 26(over 15 years) females, 
    ##   then all 24 males get a partner. However, their partner must be in a "similar" age, so therefore it is POSSIBLE not to saturate. 
    ## if a human is being assigned a partner, randomly give him/her number of times of sex
    ## age 15 in days in 5475
    cntmale = length(find(x -> x.gender == MALE && x.age >= 15, h))
    cntfemale = length(find(x -> x.gender == FEMALE && x.age >= 15, h))
    malein = find(x -> x.gender == MALE && x.age >= 15, h)
    femalein = find(x -> x.gender == FEMALE && x.age >= 15, h)
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
            femaleage = h[5].age ## the female age
            malein = find(x -> x.gender == MALE && x.age >= femaleage - 5 && x.age <= femaleage + 5 && x.partner == -1, h)

            rnf = rand(1:length(malein)) #get a random felame
            h[i].partner = malein[rnf] ## gets the rnf'th element which is an index of the female
            h[malein[rnf]].partner = i             
            deleteat!(malein, rnf) #delete the index from the female
        end  
    end 
end