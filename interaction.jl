function bite_interaction(h::Array{Human}, m::Array{Mosq})
  ## This function considers the main interaction of the model 
  ## idea: go through all mosquitos, and see if they will bite on their 

  ## on this "day", run through bites
  totalbitestoday = 0

  for i=1:length(m)
    willbite = m[i].bitedistribution[m[i].age] ## check if mosquito i will bite on this day
    if willbite == 1
        totalbitestoday += 1
        ## we need to pick a random person to bite, but this random person must NOT be isolated
        nonisos = find(x -> x.health != SYMPISO, h)  ## go through humans, and find all humans that are not isolated
        persontobite = rand(nonisos) ## pick a random person from the above list - nonisos

        ## run through different scenarios
        ## 1) susceptible person - infected mosquito 
        if h[persontobite].health == SUSC && m[i].health == SYMP
          #this susceptible person may go to latent
          rn = rand() #pick a random number
          if rn < P.prob_infection_MtoH
            h[persontobite].swap = LAT
            h[persontobite].latentfrom = 1
          end             
        end

        ## 2) infected person - susceptible mosquito
        if (h[persontobite].health == SYMP || h[persontobite].health == ASYMP) && m[i].health == SUSC
          rn = rand()   # pick a random number
          if h[persontobite].health == SYMP 
            proboftransfer = P.prob_infection_HtoM
          elseif h[persontobite].health == ASYMP
            proboftransfer = P.prob_infection_HtoM*P.reduction_factor
          end
          rn = rand()
          if rn < proboftransfer ## mosquito gets infected
            m[i].swap = LAT
          end
        end

        ## for all other scenarios, do nothing, and the bite is wasted. 

    end 
  end
  return totalbitestoday
end


function sexual_interaction(h::Array{Human}, m::Array{Mosq})
  suitable = find(x -> x.partner > -1, h)
  for i in suitable
    if h[i].health == SYMP || h[i].health == ASYMP || h[i].health == SYMPISO || h[i].health == REC 
      if h[h[i].partner].health == SUSC
        probofsex = calculate_sexprob(h[i])
        proboftransmission = 0.0
        rn = rand()
        if rn < probofsex
          ## sex will happen, the probability of infection transfer depends on health status
          h[i].cumalativesex += 1

          if h[i].health == SYMP || h[i].health == SYMPISO || h[i].recoveredfrom == SYMP || h[i].recoveredfrom == SYMPISO
            proboftransmission = h[i].sexprobability
          elseif h[i].health == ASYMP || h[i].recoveredfrom == ASYMP
            proboftransmission = h[i].sexprobability*P.reduction_factor          
          end
          
          ## roll dice to see if person gets infected
          if rand() < proboftransmission
            h[h[i].partner].swap = LAT
            h[h[i].partner].latentfrom = 2            
          end                   
        end
      end
    end

  end  # end of for
end