
#!/bin/bash
#PBS -W group_list=aiy-141-af
#PBS -l walltime=4:00:00
#PBS -l nodes=2:ppn=1
#PBS -q qwork
 
module load julia

cd $HOME/juliazika
julia test.jl &> logfile 