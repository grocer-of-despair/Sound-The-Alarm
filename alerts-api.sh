#!/bin/bash

API_KEY=''
POLICY=''
counter=0
NOTIFICATION=''

for i in "$@"
do
case $i in
  --admin-key=*|-k=*)
  API_KEY="${i#*=}"
  shift # past argument=value
  ;;
  --entity-name=*|-e=*)
  ENTITY="${i#*=}"
  shift # past argument=value
  ;;
  --notification=*|-n=*)
  NOTIFICATION="${i#*=}"
  shift # past argument=value
  ;;
  --policy-name=*|-p=*)
  POLICY="${i#*=}"
  shift # past argument=value
  ;;
esac
done

if [[ -z $ENTITY ]]; then
    ENTITY='SoundTheAlarm'
fi
echo ""
echo -e "\e[1m\e[34mCreating new Alerts Policy called '${POLICY}'\e[0m\e[30m"
echo ""

HTTP_RESPONSE=$(curl -X POST 'https://api.newrelic.com/v2/alerts_policies.json' \
     -H 'X-Api-Key:'${API_KEY}'' \
     -H 'Content-Type: application/json' \
     -d \
'{
  "policy": {
    "incident_preference": "PER_CONDITION_AND_TARGET",
    "name": "'${POLICY}'"
  }
}')

HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
POLICY_ID=$(echo ${HTTP_BODY} | jq '.["policy"]' | jq '.["id"]')

if [ !  -z  $POLICY_ID ]; then
    echo ""
    echo -e "\e[1m\e[92mNew Policy created with ID: ${POLICY_ID}\e[0m\e[30m"
    echo ""
    echo -e "\e[1m\e[34mCreating Notification Channel\e[0m\e[30m"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://api.newrelic.com/v2/alerts_channels.json' \
         -H 'X-Api-Key:391d36df4eb86e867cd2e687d8851565' \
         -H 'Content-Type: application/json' \
         -d \
    '{
      "channel": {
        "name": "'${NOTIFICATION}'",
        "type": "email",
        "configuration": {
          "recipients" : "'${NOTIFICATION}'",
          "include_json_attachment" : true
        }
      }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    CHANNEL_ID=$(echo ${HTTP_BODY} | jq '.["channels"]' | jq '.[0]' | jq '.["id"]')
    echo ""
    echo -e "\e[1m\e[92mNew Notification Channel created with ID: ${CHANNEL_ID}\e[0m\e[30m"
    echo ""
    echo -e "\e[1m\e[34mAdding Notification Channel to policy!\e[0m\e[30m"
    echo ""
    HTTP_RESPONSE=$(curl -X PUT 'https://api.newrelic.com/v2/alerts_policy_channels.json' \
     -H 'X-Api-Key:'${API_KEY}'' -i \
     -H 'Content-Type: application/json' \
     -G -d 'policy_id='${POLICY_ID}'&channel_ids='${CHANNEL_ID}'')
    echo ""
    echo -e "\e[1m\e[92mNotification Channel added to policy!\e[0m\e[30m"
    echo ""
    echo -e "\e[1m\e[34mPointing Conditions at '${ENTITY}' entity!\e[0m\e[30m"
    echo ""
    echo -e "\e[1m\e[34mCreating HNR condition\e[0m\e[30m (1 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_host_not_reporting",
          "name":"'${POLICY}' - Host Not Reporting '\>' 5 mins",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "critical_threshold":{
             "duration_minutes":5
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating Memory Virtual Size Bytes using API
    echo ""
    echo -e "\e[1m\e[34mCreating 'stress-ng' Memory Virtual Size Bytes condition!\e[0m\e[30m  (2 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - stress-ng Memory Virtual Size Bytes '\>' 200MB",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'' AND `processDisplayName` LIKE '\''%stress-ng%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"ProcessSample",
          "select_value":"memoryVirtualSizeBytes",
          "comparison":"above",
          "critical_threshold":{
             "value":200000000,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating Disk Used using API
    echo ""
    echo -e "\e[1m\e[34mCreating Disk Used Condition!\e[0m\e[30m (3 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - Disk Used '\>' 40%",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"StorageSample",
          "select_value":"diskUsedPercent",
          "comparison":"above",
          "critical_threshold":{
             "value":40,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating Total Utilization using API
    echo ""
    echo -e "\e[1m\e[34mCreating Total Utilization Condition!\e[0m\e[30m (4 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - Total Utilization '\>' 80%",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"StorageSample",
          "select_value":"totalUtilizationPercent",
          "comparison":"above",
          "critical_threshold":{
             "value":80,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating CPU using API
    echo ""
    echo -e "\e[1m\e[34mCreating CPU Condition!\e[0m\e[30m (5 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - CPU '\>' 80%",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"SystemSample",
          "select_value":"cpuPercent",
          "comparison":"above",
          "critical_threshold":{
             "value":80,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating Memory Used using API
    echo ""
    echo -e "\e[1m\e[34mCreating Memory Condition!\e[0m\e[30m (6 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - Memory Used '\>' 50%",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"SystemSample",
          "select_value":"memoryUsedBytes/memoryTotalBytes*100",
          "comparison":"above",
          "critical_threshold":{
             "value":50,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Creating Read/Write Bytes using API
    echo ""
    echo -e "\e[1m\e[34mCreating Read/Write Condition!\e[0m\e[30m (7 of 7)"
    echo ""
    HTTP_RESPONSE=$(curl -X POST 'https://infra-api.newrelic.com/v2/alerts/conditions' \
         -H 'X-Api-Key:'${API_KEY}'' \
         -H 'Content-Type: application/json' \
         -d \
    '{
       "data":{
          "type":"infra_metric",
          "name":"'${POLICY}' - Read/Write Bytes '\>' 50MB",
          "enabled":true,
          "where_clause":"(`entityName` LIKE '\''%'${ENTITY}'%'\'')",
          "policy_id":'${POLICY_ID}',
          "event_type":"StorageSample",
          "select_value":"readBytesPerSecond+writeBytesPerSecond",
          "comparison":"above",
          "critical_threshold":{
             "value":50000000,
             "duration_minutes":2,
             "time_function":"all"
          }
       }
    }')
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    HTTP_DATA=$(echo ${HTTP_BODY} | jq 'keys | .[]')
    echo ""
    # echo $HTTP_DATA
    # echo $HTTP_RESPONSE
    if [[ $HTTP_DATA =~ .*data.* ]]; then
      counter=$((counter+1))
      echo -e "\e[1m\e[92mCondition created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31mCondition not created!\e[0m\e[30m"
      echo -e "\e[1m\e[31m${HTTP_DATA}\e[0m\e[30m"
    fi

    # Check if all conditions have been created
    if [[ $counter == 7 ]]; then
      echo ""
      echo -e "\e[1m\e[92mAll Conditions created successfully!\e[0m\e[30m"
    else
      echo -e "\e[1m\e[31m${counter} of 7 Conditions created. See errors above!\e[0m\e[30m"
    fi

else
    echo -e "\e[1m\e[31mNo Policy was created!\e[0m\e[30m"
fi
