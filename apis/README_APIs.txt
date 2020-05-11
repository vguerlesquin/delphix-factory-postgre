
Filename                   | Description 
---------------------------+-------------------------------------------------------------------
delphix_engine.conf        | Delphix Connection Parameters <-- CHANGE for your Delphix Engine
jqJSON_subroutines.sh      | Subroutines (typicall no need to change)
                           
provision_postgres131.sh   | Provision a VDB using the Delphix PostgresDB 1.3.1 plugin version
                           | ... edit provision_postgres131.sh hard coded parameters ...

vdb_operations.sh          | VDB Operations; sync (snapshot), rollback (rewind) and refresh
vdb_init.sh                | VDB States; start,stop,enable,disable,status,delete


############################################################################# 

#
# Set API Path for include files ...
#

API_PATH=`pwd`


#
# Provision VDB ...
#
# ... edit provision_postgres131.sh hard coded parameters ...
#
# SOURCE_DB="pgSource"                            # Source DB
# VDB_NAME="pgVDB"                                # VDB Name
# VDB_MOUNT_PATH="/mnt/delphix/pgvdb"             # VDB Mount Path
# VDB_GROUP="NBC"                                 # VDB Delphix Group
# VDB_ENV="awsCentos"                             # VDB Host Env
# VDB_REPOSITORY="Postgres vFiles (10.12)"        # VDB Host Env Repository Name
#

./provision_postgres131.sh  


#
# VDB Operations ...
#
#./vdb_operations.sh sync [vdb_name]
#./vdb_operations.sh rollback [vdb_name]
#./vdb_operations.sh refresh [vdb_name]
#

./vdb_operations.sh sync pgVDB
./vdb_operations.sh rollback pgVDB
./vdb_operations.sh refresh pgVDB


#
# Start Stop VDB ...
#
/usr/pgsql-10/bin/pg_ctl -D /mnt/delphix/pgvdb -l /mnt/delphix/pgvdb/logfile start
/usr/pgsql-10/bin/pg_ctl -D /mnt/delphix/pgvdb stop


#
# Delete ...
#
# ./vdb_init.sh delete [vdb_name]

./vdb_init.sh delete pgVDB



*** End of File ***

