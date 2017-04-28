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



function summarize_humans

end