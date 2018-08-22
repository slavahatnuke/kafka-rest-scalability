#!/usr/bin/env bash

# consume 1

curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
      http://localhost:18082/consumers/my_json_consumer/instances/my_consumer_instance_1/records?max_bytes=10