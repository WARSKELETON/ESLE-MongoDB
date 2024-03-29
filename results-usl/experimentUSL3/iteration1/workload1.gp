set terminal pdf
set output './results-usl/experimentUSL3/iteration1/workload1.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'workload1'
lambda = 365.2301965469
delta = 0.0669385218
kappa = 0.0002949792
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
plot [0:100][0:5500] usl(x) title 'theoretical', './results-usl/experimentUSL3/iteration1/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'workload1 latency'
plot [0:100][0:60] './results-usl/experimentUSL3/iteration1/results-latency-read.dat' using ($1):($2 / 1000) title 'read' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-update.dat' using ($1):($2 / 1000) title 'update' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan' with linespoints,'./results-usl/experimentUSL3/iteration1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert' with linespoints