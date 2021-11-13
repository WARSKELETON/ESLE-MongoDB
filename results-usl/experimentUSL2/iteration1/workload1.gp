set terminal pdf
set output './experiments/experimentUSL4/iteration1/workload1.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'workload1'
lambda = 1063.4414341392
delta = 0.1488820052
kappa = 0.0031035573
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot usl(x) title 'theoretical', './experiments/experimentUSL4/iteration1/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'workload1 latency'
plot './experiments/experimentUSL4/iteration1/results-latency-read.dat' using ($1):($2 / 1000) title 'read' with linespoints,'./experiments/experimentUSL4/iteration1/results-latency-update.dat' using ($1):($2 / 1000) title 'update' with linespoints,'./experiments/experimentUSL4/iteration1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan' with linespoints,'./experiments/experimentUSL4/iteration1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert' with linespoints