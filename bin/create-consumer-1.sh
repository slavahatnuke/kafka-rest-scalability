#!/usr/bin/env bash

# create consumer 1
# "auto.commit.enable": "false"
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"name": "my_consumer_instance_1",  "auto.commit.enable": "false", "format": "json", "auto.offset.reset": "earliest"}' \
      http://localhost:18082/consumers/my_json_consumer

printf "\n"

# subscribe
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
    --data '{"topics":["jsontest"]}' \
 http://localhost:18082/consumers/my_json_consumer/instances/my_consumer_instance_1/subscription

printf "\n"