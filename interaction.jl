function bite_interaction(h::Array{Human}, m::Array{Mosq}, P::ZikaParameters)
  ## This function considers the main interaction of the model which is vector transmission
  ## The logic is as follows: go through all mosquitos (which have already been given a bite distribution), and check each day if they will bite someone. 

  ## counter to keep track of bites per day -- not really needed, but good for testing. 
  totalbitestoday = 0  
  
  ## go through humans, and find all humans that are not isolated
  nonisos = findall(x -> x.health != SYMPISO, h) 

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
  suitable = findall(x -> x.partner > -1, h)
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


function bite_interaction_calibration(h::Array{Human}, m::Array{Mosq}, P::ZikaParameters, calibratedperson)
  ## This function considers the main interaction of the model 
  ## idea: go through all mosquitos, and see if they will bite on their 

  #print("bite_interaction() from process: $(myid()) with calibrated: $calibrated_person \n")
  #print("process: $(myid())  calibrated health: $(h[calibrated_person].health) \n")

  ## on this "day", run through bites
  #print("health of calibrated person: $(h[calibrated_person].health) \n")
  totalbitestoday = 0 ## counts how many bites the infected calibrated person got
  newmosquitos = 0
  nonisos = findall(x -> x.health != SYMPISO, h)  ## go through humans, and find all humans that are not isolated
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

        ## 2) infected person (the initial calibtration person) - susceptible mosquito
        if (h[persontobite].health == SYMP || h[persontobite].health == ASYMP) && m[i].health == SUSC && persontobite == calibratedperson
          
          # the persontobite is the calibrated person, count how many total bites he gets from all mosquitos
          totalbitestoday += 1        
         
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


function pregnancy_and_vaccination(h::Array{Human}, P::ZikaParameters)
  ## this increases the time in pregnancy for women by 1 day. If it reaches 270 days, a baby is born - this does not need to be recorded (as you can get this from pregnant women). At 270 days, we find another nonpregnant women (in the same age group) and make them pregnant with timeinpregnancy = 0
  ## As the new person is becoming pregnant, vaccinate them if they have not been vaccinated before. if the vaccination coverage is set to zero, no one will get vaccinated according to this code. 
  ## The function returns the the number of vaccinated pregnant women (ie, if a women is becoming pregnant and also gets vaccination, we return this function) 

  numbervaccinated = 0
  @inbounds for i=1:length(h)
      if h[i].ispregnant == true
          h[i].timeinpregnancy += 1 
          if h[i].timeinpregnancy == 270
              ag = get_age_group(h[i].age)
              sd = findall(x -> x.gender == FEMALE && x.agegroup == ag && x.ispregnant != true, h)
              if length(sd) > 0 
                  randfemale = rand(sd)
                  h[randfemale].ispregnant = true
                  h[randfemale].timeinpregnancy = 0
                  if h[randfemale].isvaccinated == false && rand() < P.coverage_pregnant
                      h[randfemale].isvaccinated = true
                      h[randfemale].protectionlvl = P.efficacy_min + rand()*(P.efficacy_max - P.efficacy_min)                       
                      numbervaccinated += 1                        
                  end
              end                
          end
      end        
  end  
  return numbervaccinated
end
