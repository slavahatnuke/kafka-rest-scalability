#!/usr/bin/env bash

# produce 10 records: {v: 0} ... {v: 9}
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"records":[{"value":{"v":"0"}}, {"value":{"v":"1"}}, {"value":{"v":"2"}}, {"value":{"v":"3"}}, {"value":{"v":"4"}}, {"value":{"v":"5"}}, {"value":{"v":"6"}}, {"value":{"v":"7"}}, {"value":{"v":"8"}}, {"value":{"v":"9"}}]}' \
      "http://localhost:18082/topics/jsontest"
