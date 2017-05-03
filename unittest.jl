
function test_mosquito_lifetimes()
    humans, mosqs = main();
    lt = map(x -> x.ageofdeath, mosqs)
    ag = map(x -> x.age, mosqs)
    
    plot(x = lt, Geom.histogram)
    plot(x = ag, Geom.histogram)
end

function test_bites()
    ## this function plots the distribtion of the bites.. should be similar to lifetimes
    a = map(x -> sum(x.bitedistribution), mosqs)
    plot(x=a, Geom.histogram)
end

function test_humanage()
    ag = map(x -> x.age, humans)
    plot(x = ag, Geom.histogram)

    a = find(x -> x.gender == FEMALE, humans)
    ag = zeros(Int64, length(a))
    for i=1:length(a)
        ag[i] = humans[a[i]].agegroup
    end

    ag = map(x -> x.agegroup, humans)

#    ag = map(x -> x.age, humans)
    plot(x = ag, Geom.histogram)

    find(x -> x.age >= 15, humans)
    find(x -> x.age >= 15 && x.gender == MALE, humans)
    find(x -> x.age >= 15 && x.gender == FEMALE, humans)
    
end

function sexualtest()
    t = find(x -> x.age >= 15, humans)
    tm = find(x -> x.age >= 15 && x.gender == MALE, humans)
    tf = find(x -> x.age >= 15 && x.gender == FEMALE, humans)

    find(x -> x.gender == FEMALE && x.age >= 15 && x.partner == -1, humans)
    find(x -> x.gender == MALE && x.age >= 15 && x.partner == -1, humans)
    
    sf = find(x -> x.age >= 60 && x.age < 70, humans)
    sfg = map(x -> humans[x].sexfrequency, sf)
    plot(x = sfg, Geom.histogram)

    find(x -> x == 3, sfg)

    find(x -> x.sexfrequency > 5, humans)
   
end


