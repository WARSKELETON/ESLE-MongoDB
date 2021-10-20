set terminal pdf
set output './workloads/workload2/workload2.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'Workload - w: 1'
lambda = 1131.1959551617
delta = 0.7211525602
kappa = 0.0014960699
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot [0:100] [0:1800] usl(x) title 'theoretical', './workloads/workload2/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'Workload (Latency) - w: 1'
plot [0:100] [0:900] './workloads/workload2/results-latency-read.dat' using ($1):($2 / 1000) title 'read' with linespoints,'./workloads/workload2/results-latency-update.dat' using ($1):($2 / 1000) title 'update' with linespoints,'./workloads/workload2/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan' with linespoints,'./workloads/workload2/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert' with linespoints