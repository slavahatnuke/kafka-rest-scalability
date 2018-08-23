help:
	cat Makefile

start: stop
	docker-compose up

stop:
	docker-compose stop

console:
	docker-compose exec kafka bash

topic:
	docker-compose exec kafka bash -c "kafka-topics --zookeeper zookeeper:2181 --topic jsontest --create --partitions 2 --replication-factor 1"

topic.describe:
	docker-compose exec kafka bash -c "kafka-topics --zookeeper zookeeper:2181 --topic jsontest --describe"

remove:
	docker-compose stop -t 0
	docker-compose rm -f
	docker volume prune -f


docker.stats:
	docker stats

ps:
	docker-compose ps
