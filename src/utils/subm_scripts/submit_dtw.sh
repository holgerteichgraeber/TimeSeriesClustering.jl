#!/bin/tcsh
#PBS -N clustering_nohourly
#PBS -l nodes=1:ppn=24
#PBS -q ere
#PBS -V
#PBS -e logs/err
#PBS -o logs/out
cd $PBS_O_WORKDIR

julia -p 24 /data/cees/hteich/scratch_runs/clustering/dtw_k_1_9_sc_0_5/cluster_gen_dbaclust_parallel.jl 
