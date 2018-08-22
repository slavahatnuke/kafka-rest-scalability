#!/usr/bin/env bash

# create consumer 2
# create consumer +  "auto.commit.enable": "false"
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"name": "my_consumer_instance_2",  "auto.commit.enable": "false", "format": "json", "auto.offset.reset": "earliest"}' \
      http://localhost:28082/consumers/my_json_consumer

# subscribe
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
    --data '{"topics":["jsontest"]}' \
 http://localhost:28082/consumers/my_json_consumer/instances/my_consumer_instance_2/subscription