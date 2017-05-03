function increase_timestate(h::Human)
  h.timeinstate += 1
  if h.timeinstate > h.statetime ## they have expired, and moving compartnments
    if h.health == LAT 
      ## if they are latent, switch to asymp/symp
      rn = rand()*(P.ProbLatentToASymptomaticMax - P.ProbLatentToASymptomaticMin) + P.ProbLatentToASymptomaticMin
      if rand() < rn 
        h.swap = ASYMP
      else 
        if rand() < P.ProbIsolationSymptomatic
          h.swap = SYMPISO
        else 
          h.swap = SYMP
        end
      end
    elseif h.health == SYMP || h.health == ASYMP || h.health == SYMPISO
      h.swap = REC
    end
  end
end



function start_sex(h::Human)
  ## check if they have a preassigned frequency
  if h.sexfrequency >= 0 && h.age >= 15 && h.partner > -1     
    h.cumalativedays = 0
    h.cumalativesex = 0
    h.sexprobability = rand()*(0.03 - 0.01) + 0.01
  end 
end

function calculate_sexprob(h::Human)
  retval = (h.sexfrequency - h.cumalativesex)/(7 - h.cumalativedays)
  h.cumalativedays += 1
  return retval
end


#find(x -> x.sexfrequency >= 0 && x.age >= 15 && x.partner > -1 && x.cumalativesex > -1, humans)
# map(start_sex, humans)
# a = map(calculate_sexprob, humans)


function make_human_latent(h::Human)
    ## make the i'th human latent

  h.health = LAT    # make the health -> latent
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_latent_shape, P.h_lognormal_latent_scale)
  h.statetime = min(Int(ceil(rand(d))), P.h_latency_max)
end


function make_human_sympisolated(h::Human)
  h.health = SYMPISO
  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = min(Int(ceil(rand(d))), P.h_symptomatic_max)

  start_sex(h)  
end

function make_human_symptomatic(h::Human)
  h.health = SYMP    # make the health -> symptomatic
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = min(Int(ceil(rand(d))), P.h_symptomatic_max)
  start_sex(h)
end

function make_human_asymptomatic(h::Human)
  ## extra step -- start their sexual counters
  h.health = ASYMP    # make the health -> asymptomatic  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = min(Int(ceil(rand(d))), P.h_symptomatic_max)  ## symptomatic same as asymptomatic
  start_sex(h)
end

function make_human_recovered(h::Human)
  ## make the i'th human recovered 
  ##  extra step - record if this human recovered from asymptomatic or symptomatic
  h.recoveredfrom = h.health
  h.health = REC    # make the health -> recovered  
  h.statetime = 999  ## symptomatic same as asymptomatic
end

function update_human(h::Human, timestep::Int64)
  if h.swap != UNDEF ## person is swapping
    if h.swap == LAT 
      latent_ctr[timestep] += 1
      make_human_latent(h)      
    elseif h.swap == SYMP
      if h.latentfrom == 1
        bite_symp_ctr[max(1, timestep - h.statetime - 1)] += 1
      elseif h.latentfrom == 2
        sex_symp_ctr[max(1, timestep - h.statetime - 1)] += 1     
      end        
      make_human_symptomatic(h)
    elseif h.swap == SYMPISO
      if h.latentfrom == 1
        bite_symp_ctr[max(1, timestep - h.statetime - 1)] += 1
      elseif h.latentfrom == 2
        sex_symp_ctr[max(1, timestep - h.statetime - 1)] += 1      
      end   
      make_human_sympisolated(h)
    elseif h.swap == ASYMP 
      if h.latentfrom == 1
        bite_asymp_ctr[max(1, timestep - h.statetime - 1)] += 1
      elseif h.latentfrom == 2
        sex_asymp_ctr[max(1, timestep - h.statetime - 1)] += 1              
      end   
      make_human_asymptomatic(h)
    elseif h.swap == REC
      make_human_recovered(h) 
    elseif h.swap == SUS
      print("swap set to sus - never happen")
      assert(1 == 2)
    end 
    h.timeinstate = 0 #reset their time in state
    h.swap = UNDEF #reset their time in state
  end
end



function increase_timestate(m::Mosq)
  m.timeinstate += 1
  if m.timeinstate > m.statetime
    if m.health == LAT 
      m.swap = SYMP
    else 
      print("timeinstate expired for a susceptible OR recovered mosquito")
      assert(2==1)
    end
  end
end

function make_mosquito_latent(m::Mosq)
  ## make the i'th human latent
  m.health = LAT    # make the health -> latent
  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.m_lognormal_latent_shape, P.m_lognormal_latent_scale)
  m.statetime = min(Int(floor(rand(d))), P.m_latency_max)

end

function make_mosquito_symptomatic(m::Mosq)
  m.health = SYMP
  m.statetime = m.ageofdeath + 1
end

function update_mosq(m::Mosq)
  if m.swap != UNDEF 
    if m.swap == LAT 
      make_mosquito_latent(m)
    elseif m.swap == SYMP
      make_mosquito_symptomatic(m)
    end
    m.timeinstate = 0
    m.swap = UNDEF
  end 
end

