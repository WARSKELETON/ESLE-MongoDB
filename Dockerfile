FROM openjdk:8-jdk-alpine
RUN apk --no-cache add python2 wget openssl ca-certificates && update-ca-certificates

ENV URL https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz

RUN wget -qO- $URL | tar zxv -C / && ln -nsf /ycsb* /ycsb

ADD runner-cloud.sh ./runner.sh
ADD concierge.sh ./
ADD janitor-cloud.py ./janitor.py
ADD workloads ./workloads
ADD populate.py ./
ADD esle-usl-1.0-SNAPSHOT.jar ./

RUN apk add --no-cache python2 \
&& python2 -m ensurepip \
&& pip install --upgrade pip setuptools \
&& rm -r /usr/lib/python*/ensurepip && \
if [ ! -e /usr/bin/pip ]; then ln -s pip /usr/bin/pip ; fi && \
if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python2 /usr/bin/python; fi && \
rm -r /root/.cache

RUN pip install pymongo

RUN apk update && apk add bash && apk add bc && apk add gnuplot
