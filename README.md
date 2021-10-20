# MongoDB Scalability and Performance Evaluation - ESLE

## Structure

| Module               |      Description      |
| :------------------- | :-------------------: |
| [workloads](workloads)     |  Workload modules  |
| [runner](runner.sh)     | Workload runner script |
| [Docker Compose File](docker-compose.yml)     | Docker cluster definition |
| [concierge](concierge.sh) |   Workload module cleaner  |
| [janitor](janitor.py)|    Database cleaner   |
| [moca](moca.py)     |      Our own benchmark tool attempt       |
| [populate](populate.py)     |      Populate database script       |

## Workload Struture (Example)

| Module               |      Description      |
| :------------------- | :-------------------: |
| [outputs](workloads/workload1/outputs)     |  YCSB folder output  |
| [workload](workloads/workload1/workload1) |   Workload Definition   |
| [workload.gp](workloads/workload1/workload1.gp)|    Workload GNUPLOT file   |
| [workload.pdf](workloads/workload1/workload1.pdf)     |      PDF file with plots       |
| [results-throughput.dat](workloads/workload1/results-throughput.dat)     | Insert operation latency results |
| [results-latency-insert.dat](workloads/workload1/results-latency-insert.dat)     | Insert operation latency results |
| [results-latency-read.dat](workloads/workload1/results-latency-read.dat)     | Read operation latency results |
| [results-latency-scan.dat](workloads/workload1/results-latency-scan.dat)     | Scan operation latency results |
| [results-latency-update.dat](workloads/workload1/results-latency-update.dat)     | Update operation latency results |

## How to run a workload? _(workload1 example)_
In the project root folder, deploy with:

```shell script
docker-compose up -d
```

Setup the workload and outputs folder:

```shell script
mkdir workloads/workload1 | mkdir workloads/workload1/outputs
```

Create the workload in the folder generated previously, workloads/workload1.

Then, just run our runner script with the specific workload, in the root project folder:

```shell script
./runner.sh -w workload1 -x threads -y ops -n 100 -s 5 -r 3
```

This will run workload1 from 0 to 100 client threads in increments of 5, and will be repeating each workload 3 times.

----
## Authors

**Group 01**

### Team members

| Number | Name              | User                                 | Email                                       |
| -------|-------------------|--------------------------------------|---------------------------------------------|
| 90704  | Andre Augusto     | <https://github.com/AndreAugusto11>  | <mailto:andre.augusto@tecnico.ulisboa.pt>   |
| 90744  | Lucas Vicente     | <https://github.com/WARSKELETON>     | <mailto:lucasvicente@tecnico.ulisboa.pt>    |
| 90751  | Manuel Mascarenhas    | <https://github.com/Mascarenhas12>    | <mailto:manuel.d.mascarenhas@tecnico.ulisboa.pt> |
