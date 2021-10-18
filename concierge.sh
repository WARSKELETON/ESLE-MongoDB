#!/bin/bash

declare -a threads=(1 2 4 8 16 32)

while getopts w: flag
do
    case "${flag}" in
        w) workload=${OPTARG};;
    esac
done

echo '[CONCIERGE] STARTING CLEANING PROCESS'

rm ./workloads/$workload/outputs/*.txt
rm ./workloads/$workload/*.gp
rm ./workloads/$workload/*.dat
rm ./workloads/$workload/*.pdf

echo '[CONCIERGE] DO YOU SMELL THAT? THE SMELL OF CLEAN\nI AM DONE SIR'