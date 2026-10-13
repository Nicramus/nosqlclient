#!/bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    echo $var
    echo "$var"
    echo $fileVar
    echo "$fileVar"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env 'MONGO_SCHEME'
file_env 'MONGO_USERNAME'
file_env 'MONGO_PASSWORD'
file_env 'MONGO_ADDRESSES'
file_env 'MONGO_OPT_PARAMS'
file_env 'MONGO_DATABASE'
file_env 'MONGO_TLS'
file_env 'MONGO_URL'

# The image has no embedded mongod: the app's internal DB must be external,
# given as MONGO_URL or built from MONGO_ADDRESSES (+ MONGO_USERNAME, ...).
if [ "${MONGO_URL}" == "" ] && [ "${MONGO_ADDRESSES}" == "" ]
then
    echo >&2 "error: MONGO_URL is not set."
    echo >&2 "Nosqlclient needs a MongoDB for its own data (connections, settings),"
    echo >&2 "e.g. -e MONGO_URL=mongodb://mongo:27017/nosqlclient (see docker-compose.yml)."
    exit 1
fi

MONGO_SCHEME=${MONGO_SCHEME:-mongodb}
MONGO_DATABASE=${MONGO_DATABASE:-meteor}

URL=
if [ "${MONGO_URL}" == "" ]
then
    URL=${MONGO_SCHEME}://
    if [ ! -z ${MONGO_USERNAME} ]
    then
        URL=${URL}${MONGO_USERNAME}
        if [ ! -z ${MONGO_PASSWORD} ]
    	then
    	    URL=${URL}:${MONGO_PASSWORD}
    	fi
        URL=${URL}@
    fi
    URL=${URL}${MONGO_ADDRESSES}/${MONGO_DATABASE}
    if [ -z ${MONGO_TLS} ]
    then
        URL="${URL}?ssl=false"
    else
        URL="${URL}?ssl=${MONGO_TLS}"
    fi
    if [ ! -z ${MONGO_OPT_PARAMS} ]
    then
        URL="${URL}&${MONGO_OPT_PARAMS}"
    fi
    MONGO_URL=${URL}
fi

file_env 'MONGOCLIENT_DEFAULT_CONNECTION_URL'

if [ "${MONGOCLIENT_DEFAULT_CONNECTION_URL}" == "" ]
then
	MONGOCLIENT_DEFAULT_CONNECTION_URL=$URL
fi

file_env 'MONGOCLIENT_USERNAME'
file_env 'MONGOCLIENT_PASSWORD'

# Set a delay to wait to start the Node process
if [[ $STARTUP_DELAY ]]; then
  echo "Delaying startup for $STARTUP_DELAY seconds..."
  sleep $STARTUP_DELAY
fi

# Start app
echo "=> Starting app on port $PORT..."
exec "$@"
