#!/bin/bash
/flyway/flyway -user=bliss_admin -password=Amazon123 -table=flyway_admin_history -locations=filesystem:/flyway/sql/ADMIN
/flyway/flyway -user=hkuser -password=hkuser@dm1n -table=flyway_hkuser_ddl_history -locations=filesystem:/flyway/sql/SCHEMA
/flyway/flyway -user=hkuser -password=hkuser@dm1n -table=flyway_hkuser_dml_history -locations=filesystem:/flyway/sql/HK
/flyway/flyway -user=sguser -password=sguser@dm1n -table=flyway_sguser_ddl_history -locations=filesystem:/flyway/sql/SCHEMA
#/flyway/flyway -user=sguser -password=sguser -table=flyway_sguser_dml_history -locations=filesystem:/flyway/sql/SG

