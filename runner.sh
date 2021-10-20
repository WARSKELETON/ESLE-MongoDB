#!/bin/bash

usage () {
    cat << EOF
Usage: runner.sh -w {workload_name} -x {x} -y {y}
Where:
  {command} is a string containing the command, including parameters, to run
  {num_iter} is an positive integer indicating how many iterations to execute
  [num_parallel] is an (optional) positive integer indicating how many parallel commands should be executed
     in each iteration. If not provided, the default is half the number of available CPU cores.
EOF
}

operations=("read" "update" "scan" "insert")

# Handle input flags
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

# Call concierge to clean workload environment
./concierge.sh -w $workload
python3 ./janitor.py

# Determine workload's operations
readproportion=$(grep readproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
readproportion=$(echo $readproportion '>' 0.0 | bc -l)
updateproportion=$(grep updateproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
updateproportion=$(echo $updateproportion '>' 0.0 | bc -l)
scanproportion=$(grep scanproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
scanproportion=$(echo $scanproportion '>' 0.0 | bc -l)
insertproportion=$(grep insertproportion ./workloads/$workload/$workload | awk -F'=' '{print $2}')
insertproportion=$(echo $insertproportion '>' 0.0 | bc -l)

# Initialize data files for workload's operations
printf "#${x} ${y}\n" >> ./workloads/$workload/results-throughput.dat

if [ "$readproportion" -gt 0 ];
then
    printf "#${x} latency\n" >> ./workloads/$workload/results-latency-read.dat
fi

if [ "$updateproportion" -gt 0 ];
then
    printf "#${x} latency\n" >> ./workloads/$workload/results-latency-update.dat
fi

if [ "$scanproportion" -gt 0 ];
then
    printf "#${x} latency\n" >> ./workloads/$workload/results-latency-scan.dat
fi

if [ "$insertproportion" -gt 0 ];
then
    printf "#${x} latency\n" >> ./workloads/$workload/results-latency-insert.dat
else
    ./ycsb-0.17.0/bin/ycsb load mongodb-async -s -P ./workloads/$workload/$workload -p mongodb.url='mongodb://mongo1:30001,mongo2:30002,mongo3:30003/ycsb?replicaSet=my-replica-set&w=1' -p mongodb.writeConcern='1' > ./workloads/$workload/outputs/outputLoad.txt
fi

# Execute the input workload for the input threads 
for (( i=1; i<=n; i+=$step ))
do
    avg=0.0
    avgRead=0.0
    avgUpdate=0.0
    avgScan=0.0
    avgInsert=0.0

    # Repeat the same experiment for the input repetitions
    for (( j=0; j<$repetitions; j++ ))
    do
        if [ "$insertproportion" -gt 0 ];
        then
            python3 ./janitor.py
            ./ycsb-0.17.0/bin/ycsb load mongodb-async -s -P ./workloads/$workload/$workload -p mongodb.url='mongodb://mongo1:30001,mongo2:30002,mongo3:30003/ycsb?replicaSet=my-replica-set&w=1' -p mongodb.writeConcern='1' > ./workloads/$workload/outputs/outputLoad.txt
        fi
        ./ycsb-0.17.0/bin/ycsb run mongodb-async -s -P ./workloads/$workload/$workload -threads $i -p mongodb.url='mongodb://mongo1:30001,mongo2:30002,mongo3:30003/ycsb?replicaSet=my-replica-set&w=1&readPreference=primary_preferred' -p mongodb.writeConcern='1' -p mongodb.readPreference='primary_preferred' > ./workloads/$workload/outputs/outputRun$i-$j.txt
        result=$(grep Throughput ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
        avg=$(echo "$avg $result" | awk '{print $1 + $2}')

        if [ "$readproportion" -gt 0 ];
        then
            resultLatency=$(grep "\[READ\], Average" ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
            avgRead=$(echo "$avgRead $resultLatency" | awk '{print $1 + $2}')
        fi

        if [ "$updateproportion" -gt 0 ];
        then
            resultLatency=$(grep "\[UPDATE\], Average" ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
            avgUpdate=$(echo "$avgUpdate $resultLatency" | awk '{print $1 + $2}')
        fi

        if [ "$scanproportion" -gt 0 ];
        then
            resultLatency=$(grep "\[SCAN\], Average" ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
            avgScan=$(echo "$avgScan $resultLatency" | awk '{print $1 + $2}')
        fi

        if [ "$insertproportion" -gt 0 ];
        then
            resultLatency=$(grep "\[INSERT\], Average" ./workloads/$workload/outputs/outputRun$i-$j.txt | awk '{print $3}')
            avgInsert=$(echo "$avgInsert $resultLatency" | awk '{print $1 + $2}')
        fi
    done

    # Calculate average after the input repetitions
    avg=$(echo "$avg $repetitions" | awk '{print $1 / $2}')
    printf "${i}, ${avg}\n" >> ./workloads/$workload/results-throughput.dat

    if [ "$readproportion" -gt 0 ];
    then
        avgRead=$(echo "$avgRead $repetitions" | awk '{print $1 / $2}')
        printf "${i}, ${avgRead}\n" >> ./workloads/$workload/results-latency-read.dat
    fi

    if [ "$updateproportion" -gt 0 ];
    then
        avgUpdate=$(echo "$avgUpdate $repetitions" | awk '{print $1 / $2}')
        printf "${i}, ${avgUpdate}\n" >> ./workloads/$workload/results-latency-update.dat
    fi

    if [ "$scanproportion" -gt 0 ];
    then
        avgScan=$(echo "$avgScan $repetitions" | awk '{print $1 / $2}')
        printf "${i}, ${avgScan}\n" >> ./workloads/$workload/results-latency-scan.dat
    fi

    if [ "$insertproportion" -gt 0 ];
    then
        avgInsert=$(echo "$avgInsert $repetitions" | awk '{print $1 / $2}')
        printf "${i}, ${avgInsert}\n" >> ./workloads/$workload/results-latency-insert.dat
    fi
done

# Build latency plot based on the operations executed
latencyString="set xlabel 'Client Threads (#)'\nset ylabel 'Latency (ms)'\nset title '${workload} latency'\nplot "
for operation in ${operations[@]}; do
    case "${operation}" in
        read)
            if [ "$readproportion" -gt 0 ];
            then
                latencyString+="'./workloads/$workload/results-latency-read.dat' using (\$1):(\$2 / 1000) title 'read' with linespoints,"
            fi
            ;;
        update)
            if [ "$updateproportion" -gt 0 ];
            then
                latencyString+="'./workloads/$workload/results-latency-update.dat' using (\$1):(\$2 / 1000) title 'update' with linespoints,"
            fi
            ;;
        scan)
            if [ "$scanproportion" -gt 0 ];
            then
                latencyString+="'./workloads/$workload/results-latency-scan.dat' using (\$1):(\$2 / 1000) title 'scan' with linespoints,"
            fi
            ;;
        insert)
            if [ "$insertproportion" -gt 0 ];
            then
                latencyString+="'./workloads/$workload/results-latency-insert.dat' using (\$1):(\$2 / 1000) title 'insert' with linespoints,"
            fi
            ;;
    esac
done

# Remove last comma
latencyString=$(echo "$latencyString" | sed 's/.$//')

# Calculate USL values
lambda=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results-throughput.dat | grep Lambda | awk '{print $2}')
delta=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results-throughput.dat | grep Lambda | awk '{print $4}')
kappa=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./workloads/${workload}/results-throughput.dat | grep Lambda | awk '{print $6}')

# Build gnuplot file
printf "set terminal pdf\nset output './workloads/$workload/${workload}.pdf'\nset xlabel 'Client Threads (#)'\nset ylabel 'Throughput (ops/sec)'\nset title '${workload}'\nlambda = ${lambda}\ndelta = ${delta}\nkappa = ${kappa}\nusl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))\nplot usl(x) title 'theoretical', './workloads/${workload}/results-throughput.dat' using (\$1):(\$2) title 'experiment' with linespoints\n$latencyString" >> ./workloads/$workload/$workload.gp
gnuplot ./workloads/$workload/$workload.gp
xdg-open ./workloads/$workload/$workload.pdf
