set terminal pdf
set output './results-usl/workload1.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'Workload (Throughput)'
set key samplen 0.1 spacing 1.1 font ",6"

# w=1
lambda1 = 1407.1419296290
delta1 = 0.2107108561
kappa1 = 0.0019801592

# w=maj
lambda2 = 467.5539003109
delta2 = 0.0754499171
kappa2 = 0.0003586786

usl1(x) = (lambda1*x)/(1 + delta1*(x-1) + kappa1*x*(x-1))
uslMaj(x) = (lambda2*x)/(1 + delta2*(x-1) + kappa2*x*(x-1))

plot [0:100] [0:5500] usl1(x) title 'theoretical w=1', './results-usl/experimentUSL2/iteration1/results-throughput.dat' using ($1):($2) title 'experiment w=1' with linespoints, uslMaj(x) title 'theoretical w=maj', './results-usl/experimentUSL1/iteration1/results-throughput.dat' using ($1):($2) title 'experiment w=maj' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'Workload (Read Operations - Latency)'
plot [0:100][0:50]'./results-usl/experimentUSL2/iteration1/results-latency-read.dat' using ($1):($2 / 1000) title 'read w=1' with linespoints, \
                  './results-usl/experimentUSL1/iteration1/results-latency-read.dat' using ($1):($2 / 1000) title 'read w=maj' with linespoints, \
                  './results-usl/experimentUSL2/iteration1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan w=1' with linespoints,\
                  './results-usl/experimentUSL1/iteration1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan w=maj' with linespoints,\

set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'Workload (Write Operations - Latency)'
plot [0:100][0:50]'./results-usl/experimentUSL2/iteration1/results-latency-update.dat' using ($1):($2 / 1000) title 'update w=1' with linespoints, \
                  './results-usl/experimentUSL1/iteration1/results-latency-update.dat' using ($1):($2 / 1000) title 'update w=maj' with linespoints, \
                  './results-usl/experimentUSL2/iteration1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert w=1' with linespoints,\
                  './results-usl/experimentUSL1/iteration1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert w=maj' with linespoints,\
