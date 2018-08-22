## kafka-rest-scalability

### case1

`First` KAFKA REST Proxy 1 locks `Second` KAFKA REST Proxy 2

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
[ok] consume records  |                |          |   [stuck] consume records
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
      ## KAFKA_REST_CONSUMER_THREADS: "10" ## does not work too


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
      ## KAFKA_REST_CONSUMER_THREADS: "10" ## does not work too
```

`docker-compose up`

- **2/ Create topic with partitions**