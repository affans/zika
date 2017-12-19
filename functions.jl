## this file contains housekeeping functions.

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

## helper function to calculate an individauls' sex frequency 
function calculatesexfrequency(age::Int64, sex::GENDER)
    ## this function calculates sex frequency based on the distribution
    # first we need to get the age group  - this is a number between 1 and 8 -
    ag = get_age_group(age)     ## get the agegroup
    if ag == 0   # ie, age is between 1 - 15
        return 0
    end
    mfd, wfd = distribution_sexfrequency()  ## get the distributions
    rn = rand() ## roll a dice
    sexfreq = 0
    if sex == MALE 
        sexfreq = minimum(find(x -> rn <= x, mfd[ag])) - 1   #if male, use the male distribution
    else 
        sexfreq = minimum(find(x -> rn <= x, wfd[ag])) - 1   #if female, use the female distribution
    end
    return sexfreq
end

function prot(a) 
    ## this function is used 
    if a > 0 
        return 0
    else 
        return 1
    end
end
