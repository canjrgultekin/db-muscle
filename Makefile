
LOG_DIR=logs
TIMESTAMP=$$(date +'%Y-%m-%d_%H-%M-%S')

.PHONY: pg-up pg-down pg-bench pg-ha-up pg-ha-down pg-ha-fail mssql-up mssql-down mssql-bench mongo-up mongo-init mongo-bench mongo-fail mongo-down cb-up cb-down cb-bench cb-fail

# PostgreSQL Tek Node
pg-up:
	mkdir -p $(LOG_DIR)
	docker compose -f postgres.yml up -d
pg-down:
	docker compose -f postgres.yml down -v
pg-bench:
	mkdir -p $(LOG_DIR)
	docker exec -it pg16 bash -lc "apt-get update && apt-get install -y postgresql-contrib"
	docker exec -it pg16 pgbench -i -s 50 -U dev appdb | tee $(LOG_DIR)/pgbench_init_$(TIMESTAMP).log
	docker exec -it pg16 pgbench -c 20 -j 4 -T 60 -U dev appdb | tee $(LOG_DIR)/pgbench_run_$(TIMESTAMP).log

# PostgreSQL Patroni HA
pg-ha-up:
	mkdir -p $(LOG_DIR)
	docker compose -f postgres-patroni.yml up -d
pg-ha-down:
	docker compose -f postgres-patroni.yml down -v
pg-ha-fail:
	mkdir -p $(LOG_DIR)
	@echo "Primary node pg01 durduruluyor, failover süresi ölçülüyor..."
	START=$$(date +%s%3N); \	docker stop pg01; \	sleep 10; \	docker start pg01; \	END=$$(date +%s%3N); \	ELAPSED=$$((END-START)); \	echo "Failover süresi: $${ELAPSED} ms" | tee $(LOG_DIR)/pg_failover_$(TIMESTAMP).log

# MSSQL
mssql-up:
	mkdir -p $(LOG_DIR)
	docker compose -f mssql.yml up -d
mssql-down:
	docker compose -f mssql.yml down -v
mssql-bench:
	@echo "HammerDB veya ostress yük testi manuel yapılmalı"
mssql-fail:
	@echo "MSSQL failover testi için AG topolojisi gerekli, Docker'da tek node olduğu için atlandı."

# MongoDB RS
mongo-up:
	mkdir -p $(LOG_DIR)
	docker compose -f mongodb-rs.yml up -d
mongo-init:
	docker exec -it mongo1 mongosh --eval 'rs.initiate({_id:"rs0",members:[{_id:0,host:"mongo1:27017"},{_id:1,host:"mongo2:27017"},{_id:2,host:"mongo3:27017"}]})'
mongo-bench:
	@echo "YCSB yük testi manuel yapılmalı, mongodb/bench/ycsb.md dosyasına bak"
mongo-fail:
	mkdir -p $(LOG_DIR)
	@echo "Primary node mongo1 durduruluyor, election süresi ölçülüyor..."
	START=$$(date +%s%3N); \	docker stop mongo1; \	sleep 10; \	docker start mongo1; \	END=$$(date +%s%3N); \	ELAPSED=$$((END-START)); \	echo "Election süresi: $${ELAPSED} ms" | tee $(LOG_DIR)/mongo_failover_$(TIMESTAMP).log
mongo-down:
	docker compose -f mongodb-rs.yml down -v

# Couchbase
cb-up:
	mkdir -p $(LOG_DIR)
	docker compose -f couchbase.yml up -d
cb-bench:
	cbc-pillowfight -U couchbase://cb1,cb2,cb3/app -u Administrator -P AdminPass -I 200000 -B 100 -t 8 | tee $(LOG_DIR)/cb_pillowfight_$(TIMESTAMP).log
cb-fail:
	mkdir -p $(LOG_DIR)
	@echo "cb1 node durduruluyor, rebalance/failover süresi ölçülüyor..."
	START=$$(date +%s%3N); \	docker stop cb1; \	sleep 10; \	docker start cb1; \	END=$$(date +%s%3N); \	ELAPSED=$$((END-START)); \	echo "Failover/Rebalance süresi: $${ELAPSED} ms" | tee $(LOG_DIR)/cb_failover_$(TIMESTAMP).log
cb-down:
	docker compose -f couchbase.yml down -v
