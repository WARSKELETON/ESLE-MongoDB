while getopts e: flag
do
    case "${flag}" in
        e) experiment=${OPTARG};;
    esac
done

kubectl cp default/ycsb:/experiments/$experiment ./results/$experiment -c ycsb
python results-aggregator.py workload1 $experiment 5 > ./results/$experiment/aggregate.txt
