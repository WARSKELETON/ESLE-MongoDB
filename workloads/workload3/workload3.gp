set terminal pdf
set output './workloads/workload3/workload3.pdf'
set xlabel 'Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'workload3'
lambda = 515.4713815963
delta = 0.6238619550
kappa = -0.0005258340
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot [0:110] [0:1500] usl(x) title 'theoretical', './workloads/workload3/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Threads (#)'
set ylabel 'Latency (ms)'
set title 'workload3 latency'
plot './workloads/workload3/results-latency-read.dat' using ($1):($2 / 1000) title 'read' with linespoints,'./workloads/workload3/results-latency-update.dat' using ($1):($2 / 1000) title 'update' with linespoints,'./workloads/workload3/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan' with linespoints,'./workloads/workload3/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert' with linespoints