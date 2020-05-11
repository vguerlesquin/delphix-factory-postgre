#!/bin/bash
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
# Program Name : provision_postgres131.sh
# Description  : Delphix API for Provisioning a Postgres DB  
# Author       : Alan Bitterman
# Created      : 2020-03-10
# Version      : v1.1
#
# Requirements :
#  1.) curl and jq command line libraries 
#  2.) Populate Delphix Engine Connection Information . ./delphix_engine.conf
#
# Interactive Usage: 
#   ./provision_postgres131.sh
#
# Command Line Usage:
#   ./provision_postgres131.sh [source_db] [vdb_name] [vdb_group] [target_host] [repository] [vdb_mount_path] [vdb_port] 
#  Examples
#   ./provision_postgres131.sh pgSource pgVDB NBC awsCentos "Postgres vFiles (10.12)" /mnt/provision/pgVDB 5434
#   ./provision_postgres131.sh pgSource pgVDB1 NBC awsCentos "Postgres vFiles (10.12)" /mnt/provision/pgVDB1 5435
#   ./provision_postgres131.sh pgVDB pgVDB2 NBC awsCentos "Postgres vFiles (10.12)" /mnt/provision/pgVDB2 5436
#
# Note: The current paramaters for the provisioned VDB are coded in the JSON string variable line later in this script ...
#       The "configSettingsStg" is a array of objects that have the propertyName and value respective data.
#       Please add/change as needed.
#
#   ,\"parameters\": {\"postgresPort\":${VDB_PORT},\"configSettingsStg\":[{\"propertyName\":\"listen_addresses\",\"value\":\"*\"}]}
# 
#########################################################
#                   DELPHIX CORP                        #
# Please make changes to the parameters below as req'd! #
#########################################################

#########################################################
## Parameter Initialization ...

if [[ "${API_PATH}" == "" ]]
then
   API_PATH="."
fi

. ${API_PATH}/delphix_engine.conf

#
# Stop Interactive Mode and use the following default hard coded variables ...
#
#DEF_SOURCE_DB="pgSource"                   	 	# Source DB
#DEF_VDB_NAME="pgVDB"					# VDB Name
#DEF_VDB_MOUNT_PATH="/mnt/delphix/pgvdb"     		# VDB Mount Path
#DEF_VDB_GROUP="NBC"					# VDB Delphix Group
#DEF_VDB_ENV="awsCentos"				# VDB Host Env
#DEF_VDB_REPOSITORY="Postgres vFiles (10.12)"		# VDB Host Env Repository Name
#DEF_VDB_PORT=5434					# VDB Port

#########################################################
#         NO CHANGES REQUIRED BELOW THIS POINT          #
#########################################################

#########################################################
## Subroutines ...

. ${API_PATH}/jqJSON_subroutines.sh

#########################################################
## Authentication ...

echo "Authenticating on ${BaseURL}"

RESULTS=$( RestSession "${DMUSER}" "${DMPASS}" "${BaseURL}" "${COOKIE}" "${CONTENT_TYPE}" )
#echo "Results: ${RESULTS}"
if [[ "${RESULTS}" != "OK" ]]
then
   echo "Error: Exiting ... ${RESULTS}"
   exit 1;
fi

echo "Session and Login Successful ..."

#########################################################
## Get Database ...

STATUS=`curl -s -X GET -k ${BaseURL}/database -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

SOURCE_DB="${1}"
if [[ "${SOURCE_DB}" == "" ]]
then
   ZTMP="Enter dSource or VDB Name to Provision"
   if [[ "${DEF_SOURCE_DB}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.namespace==null) | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read SOURCE_DB
      if [[ "${SOURCE_DB}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      SOURCE_DB=${DEF_SOURCE_DB}
   fi
fi


CONTAINER_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_DB}"'" and .type=="AppDataContainer") | .reference '`
echo "container reference: ${CONTAINER_REF}"

#########################################################
## VDB Name from Command Line Parameters ...

VDB_NAME="${2}"
ZTMP="New VDB Name"
if [[ "${VDB_NAME}" == "" ]]
then
   if [[ "${DEF_VDB_NAME}" == "" ]]
   then
      echo "---------------------------------"
      echo "Please Enter ${ZTMP} (case-sensitive): "
      read VDB_NAME
      if [[ "${VDB_NAME}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_NAME=${DEF_VDB_NAME}
   fi
fi
echo "${ZTMP}: ${VDB_NAME}"

#########################################################
## Get Group Reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/group -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )

VDB_GROUP="${3}"
if [[ "${VDB_GROUP}" == "" ]]
then
   ZTMP="Delphix Target Group/Folder"
   if [[ "${DEF_VDB_GROUP}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.namespace==null) | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read VDB_GROUP
      if [[ "${VDB_GROUP}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_GROUP=${DEF_VDB_GROUP}
   fi
fi

GROUP_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${VDB_GROUP}"'") | .reference '`
echo "group reference: ${GROUP_REF}"

#########################################################
## Get Environment primaryUser

STATUS=`curl -s -X GET -k ${BaseURL}/environment -b "${COOKIE}" -H "${CONTENT_TYPE}"`

#echo "Environment Status: ${STATUS}"
RESULTS=$( jqParse "${STATUS}" "status" )

VDB_ENV="${4}"
if [[ "${VDB_ENV}" == "" ]]
then
   ZTMP="Target Environment"
   if [[ "${DEF_VDB_ENV}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select (.type=="UnixHostEnvironment" and .namespace==null) | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read VDB_ENV
      if [[ "${VDB_ENV}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_ENV=${DEF_VDB_ENV}
   fi
fi

#
# Parse out primaryUser name ...
#
PRIMARYUSER=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${VDB_ENV}"'") | .primaryUser '`
echo "primaryUser reference: ${PRIMARYUSER}"

ENV_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${VDB_ENV}"'") | .reference '`
echo "environment reference: ${ENV_REF}"

#########################################################
## Get repositor reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/repository -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

VDB_REPOSITORY="${5}"
if [[ "${VDB_REPOSITORY}" == "" ]]
then
   ZTMP="Target Home Repository"
   if [[ "${DEF_VDB_REPOSITORY}" == "" ]]
   then
      TMP=`echo "${STATUS}" | jq --raw-output '.result[] | select(.type=="AppDataRepository" and .environment=="'"${ENV_REF}"'" and .namespace==null) | .name '`
      echo "---------------------------------"
      echo "${ZTMP}s: [copy-n-paste]"
      echo "${TMP}"
      echo " "
      echo "Please Enter ${ZTMP} (case sensitive): "
      read VDB_REPOSITORY
      if [[ "${VDB_REPOSITORY}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_REPOSITORY=${DEF_VDB_REPOSITORY}
   fi
fi

REP_REF=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${VDB_REPOSITORY}"'") | .reference '`
echo "repository reference: ${REP_REF}"

#########################################################
## Get sourceconfig reference ...

STATUS=`curl -s -X GET -k ${BaseURL}/sourceconfig -b "${COOKIE}" -H "${CONTENT_TYPE}"`
RESULTS=$( jqParse "${STATUS}" "status" )
#echo "${STATUS}" | jq "."

SOURCE_CFG=`echo ${STATUS} | jq --raw-output '.result[] | select(.name=="'"${SOURCE_DB}"'") | .reference '`
echo "sourceconfig reference: ${SOURCE_CFG}"

#########################################################
## Get Remaining Command Line Parameters ...

VDB_MOUNT_PATH="${6}"
ZTMP="VDB Mount Path"
if [[ "${VDB_MOUNT_PATH}" == "" ]]
then
   if [[ "${DEF_VDB_MOUNT_PATH}" == "" ]]
   then
      echo "Example: /mnt/provision/pgVDB"
      echo "---------------------------------"
      echo "Please Enter ${ZTMP}: "
      read VDB_MOUNT_PATH
      if [[ "${VDB_MOUNT_PATH}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_MOUNT_PATH=${DEF_VDB_MOUNT_PATH}
   fi
fi
echo "${ZTMP}: ${VDB_MOUNT_PATH}"

VDB_PORT="${7}"
ZTMP="VDB Port"
if [[ "${VDB_PORT}" == "" ]]
then
   if [[ "${DEF_VDB_PORT}" == "" ]]
   then
      echo "Example: 8434"    
      echo "---------------------------------"
      echo "Please Enter ${ZTMP}: "
      read VDB_PORT
      if [[ "${VDB_PORT}" == "" ]]
      then
         echo "No ${ZTMP} Provided, Exiting ..."
         exit 1;
      fi
   else
      echo "No ${ZTMP} Provided, using Default ..."
      VDB_PORT=${DEF_VDB_PORT}
   fi
fi
echo "${ZTMP}: ${VDB_PORT}"

#########################################################
## Provision AppData ...

json="{
  \"type\":\"AppDataProvisionParameters\"
  ,\"masked\": false
  ,\"container\":{
      \"type\":\"AppDataContainer\"
     ,\"group\":\"${GROUP_REF}\"
     ,\"name\":\"${VDB_NAME}\"
     ,\"sourcingPolicy\":{\"logsyncEnabled\":false,\"type\":\"SourcingPolicy\"}
  }
  ,\"source\":{
      \"type\":\"AppDataVirtualSource\"
     ,\"name\":\"${VDB_NAME}\"
     ,\"operations\":{
         \"type\": \"VirtualSourceOperations\"
        ,\"configureClone\":[]
        ,\"preRefresh\":[],\"postRefresh\":[],\"preRollback\":[],\"postRollback\":[],\"preSnapshot\":[]
        ,\"postSnapshot\":[],\"preStart\":[],\"postStart\":[],\"preStop\":[],\"postStop\":[]
     }
     ,\"parameters\": {\"postgresPort\":${VDB_PORT},\"configSettingsStg\":[{\"propertyName\":\"listen_addresses\",\"value\":\"*\"}]}
     ,\"additionalMountPoints\":[]
     ,\"allowAutoVDBRestartOnHostReboot\":false
  }
  ,\"sourceConfig\":{
    \"path\":\"${VDB_MOUNT_PATH}\"
    ,\"name\":\"${VDB_NAME}\"
    ,\"repository\":\"${REP_REF}\"
    ,\"linkingEnabled\":true
    ,\"environmentUser\":\"${PRIMARYUSER}\"
    ,\"type\":\"AppDataDirectSourceConfig\"
  }
  ,\"timeflowPointParameters\":{
     \"type\": \"TimeflowPointSemantic\"
    ,\"container\": \"${CONTAINER_REF}\"
  }
}"

echo "JSON: $json" 

echo " "
echo "Provision AppData ... "
STATUS=`curl -s -X POST -k --data @- $BaseURL/database/provision -b "${COOKIE}" -H "${CONTENT_TYPE}" <<EOF
${json}
EOF
`

RESULTS=$( jqParse "${STATUS}" "status" )
echo ${STATUS} | jq "."

#########################################################
## Get Job Number ...

JOB=$( jqParse "${STATUS}" "job" )
echo "Job: ${JOB}"

jqJobStatus "${JOB}"            # Job Status Function ...

#########################################################
## The End is Here ...

echo " "
echo "Done "
exit 0;
