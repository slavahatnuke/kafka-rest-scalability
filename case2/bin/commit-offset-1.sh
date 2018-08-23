#!/usr/bin/env bash

# commit & offsets
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"offsets": [ {"topic": "jsontest","partition":0,"offset":0} ]}' \
      http://localhost:18082/consumers/my_json_consumer/instances/my_consumer_instance_1/offsets

printf "\n"
