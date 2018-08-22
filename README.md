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

Steps to reproduce:
1/