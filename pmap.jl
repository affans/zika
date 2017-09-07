using ProgressMeter
using PmapProgressMeter


# @showprogress 1 "Computing..." for i in 1:50
#     sleep(0.1)
# end



x,n = 1,10
p = Progress(n)
for iter = 1:10
    x *= 2
    sleep(0.5)
    ProgressMeter.next!(p; showvalues = [(:iter,iter), (:x,x)])
end

#progress(numberofsteps, min seconds to update, string to show, length)

p = Progress(150, 1, "Zika model running...", 10)
for iter = 1:150
    sleep(0.1)
    update!(p, iter)
end

function pmapfunc(x)
    #print("print in pmap \n")
    sleep(1)
    return 2
end
a = pmap((cb, P, x) -> begin sleep(1); x end, cb, Progress(10), 1:10; passcallback=true);

pmap((P, x)->begin sleep(1); x*m end, Progress(10), 1:10, 1:5; passcallback=true)

function cb()
    return 2
end


vals = 1:4
@everywhere function mainfunc(cb, x)
    print("calibration started for $x \n")
    for i = 1:25
        #cb(i)
        sleep(0.4)
        cb(1)
    end
    
    return 1
end

pmap((cb, x) -> mainfunc(cb,x), Progress(length(vals)*25),vals,passcallback=true)

