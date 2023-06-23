#!/bin/bash

CONTAINER_NAME="postgres_demo_db"

docker pull postgres

docker run --name $CONTAINER_NAME --rm -p 5432:5432 \
  -e POSTGRES_USER=test_sde \
  -e POSTGRES_PASSWORD=@sde_password012 \
  -e POSTGRES_DB=demo \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -v $HOME/sde_test_db/sql:/var/lib/postgresql/data \
  -d postgres

sleep 10

docker exec $CONTAINER_NAME psql -U test_sde \
  -d demo -f /var/lib/postgresql/data/init_db/demo.sql
