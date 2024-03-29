#!/bin/bash

usage () {
    cat << EOF
Usage: runner.sh -w {workload_name} -e {experiment_id} -i {experiment_iterations} -c {cloud} -x {x} -m {min_client_threads} -n {max_client_threads} -s {step} -r {repetitions} -W {write_concern} -R {read_concern} -P {write_concern}
EOF
}

operations=("read" "update" "scan" "insert")

# Handle input flags
while getopts w:e:i:c:x:m:n:s:r:W:R:P: flag
do
    case "${flag}" in
        w) workload=${OPTARG};;
        e) experiment=${OPTARG};;
        i) iterations=${OPTARG};;
        c) cloud=${OPTARG};;
        x) x=${OPTARG};;
        m) m=${OPTARG};;
        n) n=${OPTARG};;
        s) step=${OPTARG};;
        r) repetitions=${OPTARG};;
        W) writeConcern=${OPTARG};;
        R) readConcern=${OPTARG};;
        P) readPreference=${OPTARG};;
    esac
done

# Initialize base MongoDB connection string
connectionString="mongodb://mongo1:30001,mongo2:30002,mongo3:30003/ycsb?replicaSet=my-replica-set&"
cleanerConnectionString="mongodb://mongo1:30001,mongo2:30002,mongo3:30003/db?replicaSet=my-replica-set&"
if [ "$cloud" -gt 0 ];
then
    connectionString="mongodb://mongo-0.mongo:27017,mongo-1.mongo:27017,mongo-2.mongo:27017/ycsb?"
    cleanerConnectionString="mongodb://mongo-0.mongo:27017,mongo-1.mongo:27017,mongo-2.mongo:27017/db?"
fi

# Call concierge to clean workload environment
./concierge.sh -e $experiment
python2 ./janitor.py $cleanerConnectionString

# Initialize load and run MongoDB connection string
loadString=$connectionString"w=1"
runString=$connectionString"w="$writeConcern"&readConcernLevel="$readConcern"&readPreference="$readPreference

echo $connectionString
echo $cleanerConnectionString
echo $loadString
echo $runString

# Determine workload's operations
readproportion=$(grep readproportion ./workloads/$workload | awk -F'=' '{print $2}')
readproportion=$(echo $readproportion '>' 0.0 | bc -l)
updateproportion=$(grep updateproportion ./workloads/$workload | awk -F'=' '{print $2}')
updateproportion=$(echo $updateproportion '>' 0.0 | bc -l)
scanproportion=$(grep scanproportion ./workloads/$workload | awk -F'=' '{print $2}')
scanproportion=$(echo $scanproportion '>' 0.0 | bc -l)
insertproportion=$(grep insertproportion ./workloads/$workload | awk -F'=' '{print $2}')
insertproportion=$(echo $insertproportion '>' 0.0 | bc -l)

mkdir -p experiments
mkdir ./experiments/$experiment

for (( iter=1; iter<=$iterations; iter+=1 ))
do
    mkdir ./experiments/$experiment/iteration$iter
    mkdir ./experiments/$experiment/iteration$iter/outputs

    # Initialize data files for workload's operations
    printf "#${x} throughput\n" >> ./experiments/$experiment/iteration$iter/results-throughput.dat

    if [ "$readproportion" -gt 0 ];
    then
        printf "#${x} latency\n" >> ./experiments/$experiment/iteration$iter/results-latency-read.dat
    fi

    if [ "$updateproportion" -gt 0 ];
    then
        printf "#${x} latency\n" >> ./experiments/$experiment/iteration$iter/results-latency-update.dat
    fi

    if [ "$scanproportion" -gt 0 ];
    then
        printf "#${x} latency\n" >> ./experiments/$experiment/iteration$iter/results-latency-scan.dat
    fi

    if [ "$insertproportion" -gt 0 ];
    then
        printf "#${x} latency\n" >> ./experiments/$experiment/iteration$iter/results-latency-insert.dat
    else
        ./ycsb-0.17.0/bin/ycsb load mongodb -s -P ./workloads/$workload -p mongodb.url=$loadString > ./experiments/$experiment/iteration$iter/outputs/outputLoad.txt
    fi


    # Execute the input workload for the input threads 
    for (( i=m; i<=n; i+=$step ))
    do
        avg=0.0
        avgRead=0.0
        avgUpdate=0.0
        avgScan=0.0
        avgInsert=0.0

        # Repeat the same experiment for the input repetitions
        for (( j=1; j<=$repetitions; j++ ))
        do
            echo "ITERATION: $iter/$iterations; CLIENT THREADS: $i/$n; REPETITION: $j/$repetitions"

            if [ "$insertproportion" -gt 0 ];
            then
                python2 ./janitor.py $cleanerConnectionString
                ./ycsb-0.17.0/bin/ycsb load mongodb -s -P ./workloads/$workload -p mongodb.url=$loadString > ./experiments/$experiment/iteration$iter/outputs/outputLoad.txt
            fi
            ./ycsb-0.17.0/bin/ycsb run mongodb -s -P ./workloads/$workload -threads $i -p mongodb.url=$runString > ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt
            result=$(grep Throughput ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt | awk '{print $3}')
            avg=$(echo "$avg $result" | awk '{print $1 + $2}')

            if [ "$readproportion" -gt 0 ];
            then
                resultLatency=$(grep "\[READ\], Average" ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt | awk '{print $3}')
                avgRead=$(echo "$avgRead $resultLatency" | awk '{print $1 + $2}')
            fi

            if [ "$updateproportion" -gt 0 ];
            then
                resultLatency=$(grep "\[UPDATE\], Average" ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt | awk '{print $3}')
                avgUpdate=$(echo "$avgUpdate $resultLatency" | awk '{print $1 + $2}')
            fi

            if [ "$scanproportion" -gt 0 ];
            then
                resultLatency=$(grep "\[SCAN\], Average" ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt | awk '{print $3}')
                avgScan=$(echo "$avgScan $resultLatency" | awk '{print $1 + $2}')
            fi

            if [ "$insertproportion" -gt 0 ];
            then
                resultLatency=$(grep "\[INSERT\], Average" ./experiments/$experiment/iteration$iter/outputs/outputRun$i-$j.txt | awk '{print $3}')
                avgInsert=$(echo "$avgInsert $resultLatency" | awk '{print $1 + $2}')
            fi
        done

        # Calculate average after the input repetitions
        avg=$(echo "$avg $repetitions" | awk '{print $1 / $2}')
        printf "${i}, ${avg}\n" >> ./experiments/$experiment/iteration$iter/results-throughput.dat

        if [ "$readproportion" -gt 0 ];
        then
            avgRead=$(echo "$avgRead $repetitions" | awk '{print $1 / $2}')
            printf "${i}, ${avgRead}\n" >> ./experiments/$experiment/iteration$iter/results-latency-read.dat
        fi

        if [ "$updateproportion" -gt 0 ];
        then
            avgUpdate=$(echo "$avgUpdate $repetitions" | awk '{print $1 / $2}')
            printf "${i}, ${avgUpdate}\n" >> ./experiments/$experiment/iteration$iter/results-latency-update.dat
        fi

        if [ "$scanproportion" -gt 0 ];
        then
            avgScan=$(echo "$avgScan $repetitions" | awk '{print $1 / $2}')
            printf "${i}, ${avgScan}\n" >> ./experiments/$experiment/iteration$iter/results-latency-scan.dat
        fi

        if [ "$insertproportion" -gt 0 ];
        then
            avgInsert=$(echo "$avgInsert $repetitions" | awk '{print $1 / $2}')
            printf "${i}, ${avgInsert}\n" >> ./experiments/$experiment/iteration$iter/results-latency-insert.dat
        fi
    done

    if [ "$m" = 1 ];
    then
        # Build latency plot based on the operations executed
        latencyString="set xlabel 'Client Threads (#)'\nset ylabel 'Latency (ms)'\nset title '${workload} latency'\nplot "
        for operation in ${operations[@]}; do
            case "${operation}" in
                read)
                    if [ "$readproportion" -gt 0 ];
                    then
                        latencyString+="'./experiments/$experiment/iteration$iter/results-latency-read.dat' using (\$1):(\$2 / 1000) title 'read' with linespoints,"
                    fi
                    ;;
                update)
                    if [ "$updateproportion" -gt 0 ];
                    then
                        latencyString+="'./experiments/$experiment/iteration$iter/results-latency-update.dat' using (\$1):(\$2 / 1000) title 'update' with linespoints,"
                    fi
                    ;;
                scan)
                    if [ "$scanproportion" -gt 0 ];
                    then
                        latencyString+="'./experiments/$experiment/iteration$iter/results-latency-scan.dat' using (\$1):(\$2 / 1000) title 'scan' with linespoints,"
                    fi
                    ;;
                insert)
                    if [ "$insertproportion" -gt 0 ];
                    then
                        latencyString+="'./experiments/$experiment/iteration$iter/results-latency-insert.dat' using (\$1):(\$2 / 1000) title 'insert' with linespoints,"
                    fi
                    ;;
            esac
        done

        # Remove last comma
        latencyString=$(echo "$latencyString" | sed 's/.$//')

        # Calculate USL values
        lambda=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./experiments/$experiment/iteration$iter/results-throughput.dat | grep Lambda | awk '{print $2}' | sed 's/\,/./')
        delta=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./experiments/$experiment/iteration$iter/results-throughput.dat | grep Lambda | awk '{print $4}' | sed 's/\,/./')
        kappa=$(java -jar esle-usl-1.0-SNAPSHOT.jar ./experiments/$experiment/iteration$iter/results-throughput.dat | grep Lambda | awk '{print $6}' | sed 's/\,/./')

        # Build gnuplot file
        printf "set terminal pdf\nset output './experiments/$experiment/iteration$iter/$workload.pdf'\nset xlabel 'Client Threads (#)'\nset ylabel 'Throughput (ops/sec)'\nset title '${workload}'\nlambda = ${lambda}\ndelta = ${delta}\nkappa = ${kappa}\nusl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))\nplot usl(x) title 'theoretical', './experiments/$experiment/iteration$iter/results-throughput.dat' using (\$1):(\$2) title 'experiment' with linespoints\n$latencyString" >> ./experiments/$experiment/iteration$iter/$workload.gp
        gnuplot ./experiments/$experiment/iteration$iter/$workload.gp

        if [ "$cloud" = 0 ];
        then
            xdg-open ./experiments/$experiment/iteration$iter/$workload.pdf
        fi
    fi
done