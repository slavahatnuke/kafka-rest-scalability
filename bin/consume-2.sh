#!/usr/bin/env bash

# consume 2

curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
      http://localhost:28082/consumers/my_json_consumer/instances/my_consumer_instance_2/records?max_bytes=10