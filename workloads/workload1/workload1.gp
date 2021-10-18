set terminal pdf
set output './workloads/workload1/workload1.pdf'
set xlabel 'Threads'
set ylabel 'Throughput (ops/sec)'
set title 'workload1'
lambda = 215.9828607149
delta = 0.5584402585
kappa = 0.0001247325
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot usl(x) title 'theoretical', './workloads/workload1/results.dat' using ($1):($2) title 'experiment' with linespoints