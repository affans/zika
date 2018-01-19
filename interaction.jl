function bite_interaction(h::Array{Human}, m::Array{Mosq}, P::ZikaParameters)
  ## This function considers the main interaction of the model which is vector transmission
  ## The logic is as follows: go through all mosquitos (which have already been given a bite distribution), and check each day if they will bite someone. 

  ## counter to keep track of bites per day -- not really needed, but good for testing. 
  totalbitestoday = 0  
  
  ## go through humans, and find all humans that are not isolated
  nonisos = find(x -> x.health != SYMPISO, h) 

  ## go through the entire mosquito array
  for i=1:length(m)
    willbite = m[i].bitedistribution[m[i].age] ## check if mosquito i will bite on this day
    if willbite == 1
        totalbitestoday += 1
        
         ## we need to pick a random person to bite, but this random person must NOT be isolated       
        persontobite = rand(nonisos) ## pick a random person from the above list - nonisos

        ## run through different scenarios
        ## 1) susceptible person - infected mosquito 
        if h[persontobite].health == SUSC && m[i].health == SYMP
          #this susceptible person may go to latent
          rn = rand() #pick a random number
          if rn < P.transmission*(1-h[persontobite].protectionlvl)
            h[persontobite].swap = LAT
            h[persontobite].latentfrom = 1
          end             
        end

        ## 2) infected person - susceptible mosquito
        if (h[persontobite].health == SYMP || h[persontobite].health == ASYMP) && m[i].health == SUSC
          rn = rand()   # pick a random number
          if h[persontobite].health == SYMP 
            proboftransfer = P.transmission
          elseif h[persontobite].health == ASYMP
            proboftransfer = P.transmission*P.reduction_factor
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


function sexual_interaction(h::Array{Human}, m::Array{Mosq}, P::ZikaParameters)
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
            proboftransmission = h[i].sexprobability*(1 - P.condom_reduction)
          elseif h[i].health == ASYMP || h[i].recoveredfrom == ASYMP
            ## asymptomatic dont use condoms, they dont know.
            proboftransmission = h[i].sexprobability*P.reduction_factor        
          end
          
          ## roll dice to see if person gets infected
          if rand() < proboftransmission*(1 - h[h[i].partner].protectionlvl)
            h[h[i].partner].swap = LAT
            h[h[i].partner].latentfrom = 2            
          end                   
        end
      end
    end
  end  # end of for
end


function bite_interaction_calibration(h::Array{Human}, m::Array{Mosq}, P::ZikaParameters)
  ## This function considers the main interaction of the model 
  ## idea: go through all mosquitos, and see if they will bite on their 

  #print("bite_interaction() from process: $(myid()) with calibrated: $calibrated_person \n")
  #print("process: $(myid())  calibrated health: $(h[calibrated_person].health) \n")

  ## on this "day", run through bites
  #print("health of calibrated person: $(h[calibrated_person].health) \n")
  totalbitestoday = 0
  newmosquitos = 0
  nonisos = find(x -> x.health != SYMPISO, h)  ## go through humans, and find all humans that are not isolated
  for i=1:length(m)
    willbite = m[i].bitedistribution[m[i].age] ## check if mosquito i will bite on this day
    if willbite == 1       
         ## we need to pick a random person to bite, but this random person must NOT be isolated       
        persontobite = rand(nonisos) ## pick a random person from the above list - nonisos
        
        ## run through different scenarios
        ## 1) susceptible person - infected mosquito 
        if h[persontobite].health == SUSC && m[i].health == SYMP
          #this susceptible person may go to latent
          rn = rand() #pick a random number
          if rn < P.transmission
            h[persontobite].swap = LAT
            h[persontobite].latentfrom = 1
          end             
        end

        

        ## 2) infected person - susceptible mosquito
        if (h[persontobite].health == SYMP || h[persontobite].health == ASYMP) && m[i].health == SUSC && persontobite == calibrated_person
          totalbitestoday += 1
          
          #print("Transfer must happen \n")
          rn = rand()   # pick a random number
          if h[persontobite].health == SYMP 
            proboftransfer = P.transmission
          elseif h[persontobite].health == ASYMP
            proboftransfer = P.transmission*P.reduction_factor
          end
          rn = rand()
          if rn < proboftransfer ## mosquito gets infected
            #print("mosquito is latent...on process: $(myid()) \n")      
                        
            m[i].swap = LAT
            newmosquitos += 1  ## if a mosquito gets sick because of the initial latent, increase the coount
          end    
        end
        ## for all other scenarios, do nothing, and the bite is wasted. 
    end 
  end
  return totalbitestoday, newmosquitos
end