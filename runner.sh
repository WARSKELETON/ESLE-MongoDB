#!/bin/bash

while getopts w:x:y:n:s:r: flag
do
    case "${flag}" in
        w) workload=${OPTARG};;
        x) x=${OPTARG};;
        y) y=${OPTARG};;
        n) n=${OPTARG};;
        s) step=${OPTARG};;
        r) repetitions=${OPTARG};;
    esac
done

./concierge.sh -w $workload

readproportion=$(grep readproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}') > 0.0
updateproportion=$(grep updateproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
insertproportion=$(grep insertproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
scanproportion=$(grep scanproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')

printf "#${x} ${y}\n" >> ./workloads/$workload/results.dat

for (( i=1; i<=n; i+=$step ))
do
    avg=0.0
    for (( j=0; j<$repetitions; j++ ))
    do
        ./ycsb-0.17.0/bin/ycsb run mongodb-async -s -P ./workloads/$workload/$workload -threads $i -p mongodb.url='mongodb://mongo1:30001,mongo2:30002,mongo3:30003/ycsb?replicaSet=my-replica-set' > ./workloads/$workload/outputs/outputRun$i-$j.txt
        result=$(grep Throughput ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
        avg=$(echo "$avg $result" | awk '{print $1 + $2}')
    done
    avg=$(echo "$avg $repetitions" | awk '{print $1 / $2}')
    printf "${i}, ${avg}\n" >> ./workloads/$workload/results.dat
done

lambda=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results.dat | grep Lambda | awk '{print $2}')
delta=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results.dat | grep Lambda | awk '{print $4}')
kappa=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results.dat | grep Lambda | awk '{print $6}')
printf "set terminal pdf\nset output './workloads/$workload/${workload}.pdf'\nset xlabel 'Threads'\nset ylabel 'Throughput (ops/sec)'\nset title '${workload}'\nlambda = ${lambda}\ndelta = ${delta}\nkappa = ${kappa}\nusl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))\nplot usl(x) title 'theoretical', './workloads/${workload}/results.dat' using (\$1):(\$2) title 'experiment' with linespoints" >> ./workloads/$workload/$workload.gp
gnuplot ./workloads/$workload/$workload.gp
xdg-open ./workloads/$workload/$workload.pdf
