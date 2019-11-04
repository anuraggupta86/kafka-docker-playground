#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
BUCKET_NAME=${1:-kafka-docker-playground}

${DIR}/../plaintext/start.sh "${PWD}/docker-compose.plaintext.yml"

if [ ! -f "${DIR}/data/input/csv-spooldir-source.csv" ]
then
     echo "Generating data"
     curl "https://api.mockaroo.com/api/58605010?count=1000&key=25fd9c80" > "${DIR}/data/input/csv-spooldir-source.csv"
fi

echo "Creating CSV Spool Dir Source connector"
docker exec connect \
     curl -X POST \
     -H "Content-Type: application/json" \
     --data '{
               "name": "CsvSchemaSpoolDir5",
               "config": {
                    "tasks.max": "1",
                    "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
                    "input.path": "/root/data/input",
                    "input.file.pattern": "csv-spooldir-source.csv",
                    "error.path": "/root/data/error",
                    "finished.path": "/root/data/finished",
                    "halt.on.error": "false",
                    "topic": "spooldir-testing-topic",
                    "csv.first.row.as.header": "true",
                    "key.schema": "{\n  \"name\" : \"com.example.users.UserKey\",\n  \"type\" : \"STRUCT\",\n  \"isOptional\" : false,\n  \"fieldSchemas\" : {\n    \"id\" : {\n      \"type\" : \"INT64\",\n      \"isOptional\" : false\n    }\n  }\n}",
                    "value.schema": "{\n  \"name\" : \"com.example.users.User\",\n  \"type\" : \"STRUCT\",\n  \"isOptional\" : false,\n  \"fieldSchemas\" : {\n    \"id\" : {\n      \"type\" : \"INT64\",\n      \"isOptional\" : false\n    },\n    \"first_name\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"last_name\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"email\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"gender\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"ip_address\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"last_login\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"account_balance\" : {\n      \"name\" : \"org.apache.kafka.connect.data.Decimal\",\n      \"type\" : \"BYTES\",\n      \"version\" : 1,\n      \"parameters\" : {\n        \"scale\" : \"2\"\n      },\n      \"isOptional\" : true\n    },\n    \"country\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    },\n    \"favorite_color\" : {\n      \"type\" : \"STRING\",\n      \"isOptional\" : true\n    }\n  }\n}"
          }}' \
     http://localhost:8083/connectors | jq .


sleep 5

echo "Verify we have received the data in spooldir-testing-topic topic"
docker exec schema-registry kafka-avro-console-consumer -bootstrap-server broker:9092 --topic spooldir-testing-topic --property schema.registry.url=http://schema-registry:8081 --from-beginning --max-messages 10