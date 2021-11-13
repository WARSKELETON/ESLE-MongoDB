set terminal pdf
set output './results-usl/experimentUSL3/iteration1/workload1.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'workload1'
lambda = 330.0045683709
delta = 0.0356544418
kappa = 0.0010436999
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot usl(x) title 'theoretical', './results-usl/experimentUSL3/iteration1/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'workload1 latency'
plot './results-usl/experimentUSL3/iteration1/results-latency-read.dat' using ($1):($2 / 1000) title 'read' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-update.dat' using ($1):($2 / 1000) title 'update' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert' with linespoints