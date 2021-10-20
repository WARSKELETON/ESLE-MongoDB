set terminal pdf
set output './workloads/workload1/workload1.pdf'
set xlabel 'Client Threads (#)'
set ylabel 'Throughput (ops/sec)'
set title 'Workload'
set key samplen 0.1 spacing 1.1 font ",6"
lambda = 92.4600607815
delta = 0.6345138839
kappa = 0.0015122801
usl(x) = (lambda*x)/(1 + delta*(x-1) + kappa*x*(x-1))
lambda2 = 1131.1959551617
delta2 = 0.7211525602
kappa2 = 0.0014960699
usl2(x) = (lambda2*x)/(1 + delta2*(x-1) + kappa2*x*(x-1))
plot [0:100] [0:1900] usl(x) title 'theoretical', './workloads/workload1/results-throughput.dat' using ($1):($2) title 'experiment' with linespoints
plot [0:100] [0:1900] usl(x) title 'theoretical - w: maj.', './workloads/workload1/results-throughput.dat' using ($1):($2) title 'experiment - w: maj.' with linespoints, usl2(x) title 'theoretical - w: 1', './workloads/workload2/results-throughput.dat' using ($1):($2) title 'experiment - w: 1' with linespoints
set xlabel 'Client Threads (#)'
set ylabel 'Latency (ms)'
set title 'Workload (Latency)'
plot [0:100] [0:1200] './workloads/workload1/results-latency-read.dat' using ($1):($2 / 1000) title 'read - w: maj.' with linespoints,'./workloads/workload1/results-latency-update.dat' using ($1):($2 / 1000) title 'update - w: maj.' with linespoints,'./workloads/workload1/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan - w: maj.' with linespoints,'./workloads/workload1/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert - w: maj.' with linespoints, './workloads/workload2/results-latency-read.dat' using ($1):($2 / 1000) title 'read - w: 1' with linespoints,'./workloads/workload2/results-latency-update.dat' using ($1):($2 / 1000) title 'update - w: 1' with linespoints,'./workloads/workload2/results-latency-scan.dat' using ($1):($2 / 1000) title 'scan - w: 1' with linespoints,'./workloads/workload2/results-latency-insert.dat' using ($1):($2 / 1000) title 'insert - w: 1' with linespoints