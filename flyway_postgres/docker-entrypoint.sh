#!/bin/sh
#export `/usr/bin/ssm-env --with-decryption env | grep -i HK_DB_PASSWORD`
#export `/usr/bin/ssm-env --with-decryption env | grep -i DF_DB_PASSWORD`
#export `/usr/bin/ssm-env --with-decryption env | grep -i HK_DB_USER`
#export `/usr/bin/ssm-env --with-decryption env | grep -i DF_DB_USER`



/flyway/flyway -user=bliss_admin -password=Amazon123 -table=flyway_schema_history -locations=filesystem:/flyway/sql/ADMIN -outOfOrder=true migrate
/flyway/flyway -user=myuser -password=myuser -table=flyway_myuser_ddl_history -locations=filesystem:/flyway/sql/SCHEMA -outOfOrder=true migrate
/flyway/flyway -user=myuser -password=myuser -table=flyway_myuser_dml_history -locations=filesystem:/flyway/sql/MY -outOfOrder=true migrate
/flyway/flyway -user=hkuser -password=hkuser -table=flyway_hkuser_ddl_history -locations=filesystem:/flyway/sql/SCHEMA -outOfOrder=true migrate
/flyway/flyway -user=hkuser -password=hkuser -table=flyway_hkuser_dml_history -locations=filesystem:/flyway/sql/HK -outOfOrder=true migrate
/flyway/flyway -user=sguser -password=sguser -table=flyway_sguser_ddl_history -locations=filesystem:/flyway/sql/SCHEMA -outOfOrder=true migrate
/flyway/flyway -user=sguser -password=sguser -table=flyway_sguser_dml_history -locations=filesystem:/flyway/sql/SG -outOfOrder=true migrate
