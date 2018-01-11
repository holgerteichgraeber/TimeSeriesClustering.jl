#!/bin/tcsh
#PBS -N clustering_
#PBS -l nodes=1:ppn=24
#PBS -q ere
#PBS -V
#PBS -e logs/err
#PBS -o logs/out
cd $PBS_O_WORKDIR

py /scratch/hteich/clustering/case_base/cluster_gen_kshape.py GER

