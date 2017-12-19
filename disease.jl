##############################################
####### HELPER FUNCTIONS FOR DISEASE DYNAMICS#
##############################################

## for a human, increase their time in a particular state, and if they are expiring move them to symp/asymp
function increase_timestate(h::Human, P::ZikaParameters)
  h.timeinstate += 1
  if h.timeinstate > h.statetime ## they have expired, and moving compartnments
    if h.health == LAT 
      ## if they are latent, switch to asymp/symp
      ## if they have any level of protection, they will only go to asymptomatic
      if h.protectionlvl > 0 
        rn = 1
      else 
        rn = rand()*(P.ProbLatentToASymptomaticMax - P.ProbLatentToASymptomaticMin) + P.ProbLatentToASymptomaticMin
      end
      ## human is going to asymptomatic
      if rand() < rn 
        h.swap = ASYMP
      else ## human is going to symptomatic -- check if we isolate
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

## This function switches a mosquito from the latent stage to symptomatic
function increase_timestate(m::Mosq)
  m.timeinstate += 1
  if m.timeinstate > m.statetime
    if m.health == LAT 
      m.swap = SYMP
      #print("mosquito has swapped -> sympotmatic \n")
      #biteleft = m.bitedistribution[m.age:m.ageofdeath]
      #print("bitedistribution: $biteleft \n")
    else 
      print("timeinstate expired for a susceptible OR recovered mosquito")
      assert(2==1)
    end
  end
  return nothing
end

function start_sex(h::Human)
  ## check if they have a >0 frequency, are over 15 years old, and have a partner
  if h.sexfrequency >= 0 && h.age >= 15 && h.partner > -1     
    h.cumalativedays = 0
    h.cumalativesex = 0
    ### beta_sex in the paper
    h.sexprobability = rand()*(0.05 - 0.01) + 0.01
  end 
end

## the probability of having sex everyday, this approaches one by the end of the week
function calculate_sexprob(h::Human)
  retval = (h.sexfrequency - h.cumalativesex)/(7 - h.cumalativedays)
  h.cumalativedays += 1
  return retval
end

function make_human_latent(h::Human, P::ZikaParameters)
    ## make the i'th human latent
  h.health = LAT    # make the health -> latent
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_latent_shape, P.h_lognormal_latent_scale)
  h.statetime = max(4, min(Int(ceil(rand(d))), P.h_latency_max))  
end


function make_human_sympisolated(h::Human, P::ZikaParameters)
  h.health = SYMPISO  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = max(3, min(Int(ceil(rand(d))), P.h_symptomatic_max))
  ## if the human is infected, start sex
  start_sex(h)  
end

function make_human_symptomatic(h::Human, P::ZikaParameters)
  h.health = SYMP    # make the health -> symptomatic
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = max(3, min(Int(ceil(rand(d))), P.h_symptomatic_max))
  ## if the human is infected, start sex
  start_sex(h)
end

function make_human_asymptomatic(h::Human, P::ZikaParameters)
  ## extra step -- start their sexual counters
  h.health = ASYMP    # make the health -> asymptomatic  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.h_lognormal_symptomatic_shape, P.h_lognormal_symptomatic_scale)
  h.statetime = max(3, min(Int(ceil(rand(d))), P.h_symptomatic_max))  ## symptomatic same as asymptomatic
  start_sex(h)
end

function make_human_recovered(h::Human, P::ZikaParameters)
  ## make the i'th human recovered 
  ##  extra step - record if this human recovered from asymptomatic or symptomatic
  h.recoveredfrom = h.health
  h.health = REC     # make the health -> recovered  
  h.statetime = 999  ## no expiry time for recovered individuals, they are always recovered
end

function make_mosquito_latent(m::Mosq, P::ZikaParameters)
  ## make the i'th human latent
  m.health = LAT    # make the health -> latent  
  ## state time has to be calculated from the lognormal distribution
  d = LogNormal(P.m_lognormal_latent_shape, P.m_lognormal_latent_scale)
  m.statetime = max(P.m_latency_min, min(Int(floor(rand(d))), P.m_latency_max))
end

function make_mosquito_symptomatic(m::Mosq)
  m.health = SYMP
  m.statetime = m.ageofdeath + 1  ## mosquito will remain symptomatic till it dies
end




 