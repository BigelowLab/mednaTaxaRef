#!/bin/sh                                                                    

## set name of script                                                           
#PBS -N ben-taxizer                                                 

## send the environment variables with job 
#PBS -V

## set the queue                                                                          
#PBS -q route                                                                   

## give job 10 minutes                        
#PBS -l walltime=192:00:00 

## use one compute node and one cpu (this will default to use 2gb of memory)                                                      
#PBS -l select=1:ncpus=4:mem=128GB    
                                                              
## output files placed in output directory in the user vcc’s home directory                                     
#PBS -e /mnt/storage/data/edna/mednaTaxaRef/egrey                                                   
#PBS -o /mnt/storage/data/edna/mednaTaxaRef/egrey                                                     

#PBS -m bea
#PBS -M btupper@bigelow.org

## jobs to submit
module use /mod/bigelow
module load R   

path=/mnt/storage/data/edna/mednaTaxaRef/egrey
cd $path                                                         
Rscript taxizer.R ${path}/input/taxizer.000.yaml
