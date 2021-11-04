import sys
import re

workload = sys.argv[1]
experiment = sys.argv[2]
iterations = int(sys.argv[3])

# Get workload proportions
fp_workload = open('workloads/' + workload , 'r')

data = fp_workload.read().replace('\n', ' ')

insertproportion = re.search(r"\binsertproportion=[0-9.]+", data).group().split('=')[1]
print(insertproportion)

readproportion = re.search(r"\breadproportion=[0-9.]+", data).group().split('=')[1]
print(readproportion)

scanproportion = re.search(r"\bscanproportion=[0-9.]+", data).group().split('=')[1]
print(scanproportion)

updateproportion = re.search(r"\bupdateproportion=[0-9.]+", data).group().split('=')[1]
print(updateproportion)


sum_insert = 0.0
sum_read = 0.0
sum_scan = 0.0
sum_update = 0.0
sum_throughput = 0.0

for i in range(1, iterations+1):

  # Calculate global latency
  insert = float(open('results/' + experiment + '/iteration' + str(i) + '/results-latency-insert.dat', 'r').read().replace('\n', ' ').split(', ')[1])
  sum_insert += insert

  read = float(open('results/' + experiment + '/iteration' + str(i) + '/results-latency-read.dat', 'r').read().replace('\n', ' ').split(', ')[1])
  sum_read += read

  scan = float(open('results/' + experiment + '/iteration' + str(i) + '/results-latency-scan.dat', 'r').read().replace('\n', ' ').split(', ')[1])
  sum_scan += scan

  update = float(open('results/' + experiment + '/iteration' + str(i) + '/results-latency-update.dat', 'r').read().replace('\n', ' ').split(', ')[1])
  sum_update += update
  
  iteration_avg = insert * float(insertproportion) + read * float(readproportion) + scan * float(scanproportion) + update * float(updateproportion)
  print("Avg iteration", i, ':', iteration_avg)

total_avg = sum_insert/iterations * float(insertproportion) + sum_read/iterations * float(readproportion) + sum_scan/iterations * float(scanproportion) + sum_update/iterations * float(updateproportion)
print("Average Latency (", workload, experiment, '):', total_avg)

print()

for i in range(1, iterations+1):

  # Calculate global latency
  throughput = float(open('results/' + experiment + '/iteration' + str(i) + '/results-throughput.dat', 'r').read().replace('\n', ' ').split(', ')[1])
  sum_throughput += throughput

  print("Throughput iteration", i, ':', throughput)

print("Average throughput", ':', sum_throughput/iterations)
