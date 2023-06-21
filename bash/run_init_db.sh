#!/bin/bash

#docker run --rm --name sqldocker -e POSTGRES_PASSWORD="@sde_password012" -e POSTGRES_USER=test_sde -e POSTGRES_DB=demo -d -p 5432:5432 -v $(pwd)/sql:/var/lib/postgresql/sql postgres
#
#docker run --rm --name sqldocker -e POSTGRES_PASSWORD="@sde_password012" -e POSTGRES_USER=test_sde -e POSTGRES_DB=demo -d -p 5432:5432 -v $pwd\sql:/var/lib/postgresql/sql postgres
#
#
#psql demo -h localhost -U test_sde -w -f "C:\Users\potpushchennikov\Desktop\Git\SDE\sde_test_db\sql\init_db\demo.sql"
#
#
#docker exec -it sqldocker psql -d demo -U test_sde -f "C:\Users\potpushchennikov\Desktop\Git\SDE\sde_test_db\sql\init_db\demo.sql"
#docker exec -it sqldocker psql -d demo -U test_sde -f "$(pwd)\sql\init_db\demo.sql"

docker run --name sqldocker -e POSTGRES_PASSWORD="@sde_password012" -e POSTGRES_USER=test_sde -e POSTGRES_DB=demo -d -p 5432:5432 -v $pwd\sql:/var/lib/postgresql/sql postgres
docker exec -it sqldocker psql -d demo -U test_sde -f /var/lib/postgresql/sql/init_db/demo.sql