#!/usr/bin/env bash

# delete consumer 2
curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" \
      http://localhost:28082/consumers/my_json_consumer/instances/my_consumer_instance_2

