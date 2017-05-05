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
