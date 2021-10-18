set terminal pdf
set output './workloads/workload2/workload2.pdf'
set xlabel 'Threads'
set ylabel 'Throughput (ops/sec)'
set title 'workload2'
lambda = 534.9767828139
delta = 0.6014615911
kappa = -0.0000983378
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot usl(x) title 'theoretical', './workloads/workload2/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Threads'
set ylabel 'Latency (ms)'
set title 'workload2 latency'
plot