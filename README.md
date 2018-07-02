# ZIKA Virus Agent-Based Model

## Overview

ZIKV, like other _flaviviruses_, is transmitted to humans primarily through the bites of infectious _Aedes_ mosquitoes in the subgenus _Stegomyia_, particularly _Ae. Aegypti_  [ref](https://www.nature.com/articles/s41598-017-05013-9#ref-CR17 "Kramer, L. D. & Ebel, G. D. Dynamics of flavivirus infection in mosquitoes. Adv. Virus Res. 60, 187–232 (2003)."). We developed an agent-based model to include human and mosquito agents in the chain of disease transmission as well as sexual tranmission. The results from the agent-based model are used to address scientific and economic impact of ZIKV. 

This github repository stores all computer simulation code for ZIKV ABM model developed by Affan Shoukat, PhD Candidate @ York University. For replication of results, please `git checkout` the appropriate branch (see below). 

## Published Results

> **Asymptomatic transmission and the dynamics of Zika infection**
SM Moghadas, A Shoukat, AL Espindola, RS Pereira, F Abdirizak
2017, Scientific Reports 7 (1), 582
[https://doi.org/10.1038/s41598-017-05013-9](https://doi.org/10.1038/s41598-017-05013-9)
**Git Branch for replication of results:** `Publication`

> **Cost-Effectiveness of a Potential Zika Vaccine Candidate: A Case Study for Colombia**
A Shoukat, SM Moghadas, T Vilches
2018, (submitted, accepted) BMC Medicine
**Git Branch for replication of results:** `Publication`

# How to use
To run this model, two particular modules need to be considered.
1) The demographics of the area of interest
2) Calibration of the model to that country's particular $R_0$ estimate. 

## Calibration
The calibration run code is in `calibration.jl`. Currently the code uses the Slurm HPC manager to utilize the lab's HPC cluster. On a local computer, say with 8 cores, one can simply comment/delete this code and go with a simple `addprocs(8)`. 

Calibration logic is as follows: An initial latent individual is introduced in the system with susceptible mosquitos. The number of secondary infections are counted and divded by the number of simulations to get an estimate of $R_0$. In other words, the flow is `latent -> mosquito -> secondary infection`. The main functions for calibration logic are `main_calibration()` and `bite_interaction_calibration()`. 

Under `CALIBRATION PARAMETERS` are the user controlled parameters for calibration. The `trans` variable loops over a spectrum of tranmissions values. Each transmission value yields a particular $R_0$. The `rel` variable is the reduction in transmission due to asymptomatic tranmission. i.e 0.1 corresponds to a 10% reduction in transmission. 

Calibration is run by executing `julia calibration.jl` 

## Contact 
Agent-Based modelling Laboratory, 
York University, Toronto, Ontario M3J 1P3, Canada
`affans@yorku.ca` 
