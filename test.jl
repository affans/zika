using ClusterManagers
#include("torquemanager.jl")

print("starting script...\n")
print("system cores: $(Sys.CPU_CORES) \n")
print("workers: $(nworkers())")

a = TorqueManager( queue="qwork", nodes=1, ppn=24, l="walltime=3:00:00", job_name="test",  env=:ALL, priority=100, other_qsub_params="-W group_list=aiy-141-af" )
addprocs( )

master_port = 9009
worker_arg = "--worker $(Base.cluster_cookie())"
julia_command = "julia $(worker_arg)"   
bash_command  = "bash -c 'for i in {1..2}; do $(julia_command) & done; wait;'"                                 # Must run under bash because we use the bash network construct
    echo_command  = `echo $(bash_command)`

     (stdout, qsub_proc) = open( pipeline( echo_command, "echo USER" ) )

      match( r"julia_worker:(\d+)#([\d\.]+)", "julia_worker:9009#192.168.2.16")