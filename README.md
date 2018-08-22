## KAFKA REST Proxy scalability issues

Cases describe issues related to `"auto.commit.enable": "false"` and scalability.

### Case #1

`First` KAFKA REST Proxy 1 locks `Second` KAFKA REST Proxy 2.

```
                            +---------------------+
                            |  CURL produce       |
                            |  topic: jsontest    |
                            +----------+----------+
                                       |   [ok] produce 10 records
                                       |
              +-------------------+    |   +-------------------+
              | CURL consumer 1   |    |   | CURL consumer 2   |
              |                   |    |   |                   |
              +-------+-----------+    |   +------+------------+
[ok] create consumer  |                |          |   [ok] create consumer
[ok] subscribe        |                |          |   [ok] subscribe
[ok] consume records  |                |          |   [hung] consume records
                      |                |          |
                +-----v-------+        |     +----v--------+
                |  Kafka REST <--------+     |  Kafka REST |
                |  port:18082 |              |  port:28082 |
                +------+------+              +------+------+
                       |                            |
                       |                            |
                       |                            |
              +--------v----------------------------v------------+
              |              Kafka                               |
              |              port:9092                           |
              +----------------+---------------------------------+
                               |
              +----------------v---------------------------------+
              |              Zookeeper                           |
              |              port:2181                           |
              +--------------------------------------------------+
```

#### Steps:
- **1/ Start services**

*docker-compose.yml*
```yml
version: "3.5"

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:5.0.0
    ports:
      - "2181:2181"
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:5.0.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: 'zookeeper:2181'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0


  kafka-rest-1:
    image: confluentinc/cp-kafka-rest:5.0.0
    depends_on:
      - kafka
    ports:
      - 18082:8082

    environment:
      KAFKA_REST_ID: "1"
      KAFKA_REST_HOST_NAME: kafka-rest-1

      KAFKA_REST_BOOTSTRAP_SERVERS: 'kafka:9092'
      KAFKA_REST_LISTENERS: "http://0.0.0.0:8082"
      KAFKA_REST_PRODUCER_THREADS: "10"


  kafka-rest-2:
    image: confluentinc/cp-kafka-rest:5.0.0
    depends_on:
      - kafka
    ports:
      - 28082:8082

    environment:
      KAFKA_REST_ID: "2"
      KAFKA_REST_HOST_NAME: kafka-rest-2

      KAFKA_REST_BOOTSTRAP_SERVERS: 'kafka:9092'
      KAFKA_REST_LISTENERS: "http://0.0.0.0:8082"
      KAFKA_REST_PRODUCER_THREADS: "10"
```

- Start services.
`docker-compose up`

- **2/ Create topic with partitions**
- topic + 10 partitions: `docker-compose exec kafka bash -c "kafka-topics --zookeeper zookeeper:2181 --topic jsontest --create --partitions 10 --replication-factor 1"`
- describe to be sure: `docker-compose exec kafka bash -c "kafka-topics --zookeeper zookeeper:2181 --topic jsontest --describe"`


- **3/ produce records**
- 10 simple records: produce 10 records: {v: 0} ... {v: 9}
- KAFKA REST `First` port `18082`
```bash
curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"records":[{"value":{"v":"0"}}, {"value":{"v":"1"}}, {"value":{"v":"2"}}, {"value":{"v":"3"}}, {"value":{"v":"4"}}, {"value":{"v":"5"}}, {"value":{"v":"6"}}, {"value":{"v":"7"}}, {"value":{"v":"8"}}, {"value":{"v":"9"}}]}' \
      "http://localhost:18082/topics/jsontest"
```

- **4/ Create CURL consumer #1**
- It creates consumer instance and subscribe topic `jsontest`.
Kafka REST 1 port: `18082`

```bash
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

```

- **5/ Consumer #1 reads records**
- It consumes from Kafka REST 1 port `18082`

```bash
# consume 1

curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
      http://localhost:18082/consumers/my_json_consumer/instances/my_consumer_instance_1/records?max_bytes=10
```

- Results looks like:
```
[{"topic":"jsontest","key":null,"value":{"v":"3"},"partition":4,"offset":0}]
[{"topic":"jsontest","key":null,"value":{"v":"2"},"partition":5,"offset":0}]
[{"topic":"jsontest","key":null,"value":{"v":"8"},"partition":6,"offset":0}]
```

- Or it could read multiple records if `max_bytes=20`

```bash
## Mesages from multiple partitions
[{"topic":"jsontest","key":null,"value":{"v":"3"},"partition":4,"offset":0},{"topic":"jsontest","key":null,"value":{"v":"2"},"partition":5,"offset":0}]
```

- What do you think is it ok that consumer reads multiple partitions at once?
when we use `"auto.commit.enable": "false"`. Seems it could be the issue.

- **6/ Create CURL consumer #2**
- It creates consumer instance and subscribe topic `jsontest`.
Kafka REST 2 port: `28082`

```bash
# create consumer 2
# "auto.commit.enable": "false"
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
      --data '{"name": "my_consumer_instance_2",  "auto.commit.enable": "false", "format": "json", "auto.offset.reset": "earliest"}' \
      http://localhost:28082/consumers/my_json_consumer

printf "\n"

# subscribe
curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" \
    --data '{"topics":["jsontest"]}' \
 http://localhost:28082/consumers/my_json_consumer/instances/my_consumer_instance_2/subscription
```

- **7/ Consumer #2 DOES NOT read records**
- It just hung and does not give any answer for long time (~5 mins).
- It seems like the `first` kafka instance locked (assigned) all topic partitions and `second` one waits.
- There is a problem with scalability, if we have multiple Kakfa REST proxies it does not bring value.
- And it looks like Kakfa REST Proxy only vertical scalable now.

```bash
# consume 2
curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" \
      http://localhost:28082/consumers/my_json_consumer/instances/my_consumer_instance_2/records?max_bytes=10
```

- **Opinion**
- I guess it could be wrong `kafka + kafka rest` configuration from my side that leads to behaviour described before.
- From my observations KAFKA Rest `consumer instance #1` reads records / messages from multiple partitions, it means that simple consumers (kafka clients) "take" partitions and the second `consumer instance #2` does not have ability read messages because all partitions are "busy".
- When I delete `consumer instance #1` second consumer `consumer instance #2` works as expected.

- **Questions**
- If I am wrong with `kafka or/and kafka rest` configuration could you suggest or correct this one to fix the issue?
- If it's the issue: What information can I add to easily reproduce a case or help?


