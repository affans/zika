## this file contains housekeeping functions.


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

function get_age_group(age::Int64)
    ## make sure the age incoming is IN DAYS!!! It should be if passing in the human type
    agegroup = -1
    if age >=0 && age < 5475 
        agegroup = 0
    elseif age >= 5475 && age < 9125
        agegroup = 1
    elseif age >= 9125 && age < 10950
        agegroup = 2
    elseif age >= 10950 && age < 14600
        agegroup = 3
    elseif age >= 14600 && age < 18250 
        agegroup = 4 
    elseif age >= 18250 && age < 21900 
        agegroup = 5 
    elseif age >= 21900 && age < 25550        
        agegroup = 6 
    elseif age >= 25550
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


function test_mosquito_age_agedeath_numberofbites(m)
    ## this function tests if the number of bites assigned to a mosqutio 
    ##  exceeds the days remaining for the mosquito
    ##  example, if mosqutio has age 5, and dies at age 10.. then the max number of bites is 5..
    ctr = 0 
    map(x -> begin
                if x.numberofbites > (x.ageofdeath - x.age)
                    print("mosquito: age =  $(x.age), death = $(x.ageofdeath), numberofbites = $(x.numberofbites) \n")
                    ctr = ctr + 1
                end
             end, m)
    print("total number of mosquitos for which number of bites > ageofdeath - age: $ctr")
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