FROM docker.elastic.co/logstash/logstash-oss:8.15.0-amd64 

ENV LS_JAVA_OPTS="-Xmx4g -Xms4g"

RUN bin/logstash-plugin install logstash-output-opensearch 
