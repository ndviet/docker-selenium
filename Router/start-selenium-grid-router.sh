#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Router..."

function append_se_opts() {
  local option="${1}"
  local value="${2:-""}"
  local allow_empty="${3:-false}"
  local log_message="${4:-true}"
  if [ "${allow_empty}" = "false" ] && [ -z "${value}" ]; then
    return
  fi
  if [[ "${SE_OPTS}" != *"${option}"* ]]; then
    if [ "${log_message}" = "true" ]; then
      echo "Appending Selenium option: ${option} ${value}"
    fi
    SE_OPTS="${SE_OPTS} ${option}"
    if [ ! -z "${value}" ]; then
      SE_OPTS="${SE_OPTS} ${value}"
    fi
    export SE_OPTS
  else
    echo "Selenium option: ${option} already set in env variable SE_OPTS. Skipping new option: ${option} ${value}"
  fi
}

if [[ -z "${SE_SESSIONS_MAP_HOST}" ]]; then
  echo "SE_SESSIONS_MAP_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSIONS_MAP_PORT}" ]]; then
  echo "SE_SESSIONS_MAP_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_DISTRIBUTOR_HOST}" ]]; then
  echo "DISTRIBUTOR_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_DISTRIBUTOR_PORT}" ]]; then
  echo "DISTRIBUTOR_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_HOST}" ]]; then
  echo "SE_SESSION_QUEUE_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_PORT}" ]]; then
  echo "SE_SESSION_QUEUE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ ! -z "$SE_SUB_PATH" ]; then
  echo "Using SE_SUB_PATH: ${SE_SUB_PATH}"
  SUB_PATH_CONFIG="--sub-path ${SE_SUB_PATH}"
fi

if [ ! -z "$SE_ROUTER_HOST" ]; then
  echo "Using SE_ROUTER_HOST: ${SE_ROUTER_HOST}"
  HOST_CONFIG="--host ${SE_ROUTER_HOST}"
fi

if [ ! -z "$SE_ROUTER_PORT" ]; then
  echo "Using SE_ROUTER_PORT: ${SE_ROUTER_PORT}"
  PORT_CONFIG="--port ${SE_ROUTER_PORT}"
fi

append_se_opts "--log-level" "${SE_LOG_LEVEL}"
append_se_opts "--http-logs" "${SE_HTTP_LOGS}"
append_se_opts "--structured-logs" "${SE_STRUCTURED_LOGS}"
append_se_opts "--external-url" "${SE_EXTERNAL_URL}"

if [ "${SE_ENABLE_TLS}" = "true" ]; then
  # Configure truststore for the server
  if [ ! -z "$SE_JAVA_SSL_TRUST_STORE" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
  fi
  if [ -f "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Getting Truststore password from ${SE_JAVA_SSL_TRUST_STORE_PASSWORD} to set Java options: -Djavax.net.ssl.trustStorePassword"
    SE_JAVA_SSL_TRUST_STORE_PASSWORD="$(cat ${SE_JAVA_SSL_TRUST_STORE_PASSWORD})"
  fi
  if [ ! -z "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStorePassword"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${SE_JAVA_SSL_TRUST_STORE_PASSWORD}"
  fi
  echo "Appending Java options: -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  # Configure certificate and private key for component communication
  append_se_opts "--https-certificate" "${SE_HTTPS_CERTIFICATE}"
  append_se_opts "--https-private-key" "${SE_HTTPS_PRIVATE_KEY}"
fi

append_se_opts "--registration-secret" "${SE_REGISTRATION_SECRET}"
append_se_opts "--disable-ui" "${SE_DISABLE_UI}"
append_se_opts "--username" "${SE_ROUTER_USERNAME}"
append_se_opts "--password" "${SE_ROUTER_PASSWORD}"
append_se_opts "--session-request-timeout" "${SE_SESSION_REQUEST_TIMEOUT}"
append_se_opts "--session-retry-interval" "${SE_SESSION_RETRY_INTERVAL}"
append_se_opts "--relax-checks" "false"

EXTRA_LIBS=""

if [ "$SE_ENABLE_TRACING" = "true" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  [ -n "$EXTRA_LIBS" ] && [ -n "${EXTERNAL_JARS}" ] && EXTRA_LIBS=${EXTRA_LIBS}:
  EXTRA_LIBS="--ext "${EXTRA_LIBS}${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
  if [ -n "$SE_OTEL_SERVICE_NAME" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.resource.attributes=service.name=${SE_OTEL_SERVICE_NAME}"
  fi
  if [ -n "$SE_OTEL_TRACES_EXPORTER" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.traces.exporter=${SE_OTEL_TRACES_EXPORTER}"
  fi
  if [ -n "$SE_OTEL_EXPORTER_ENDPOINT" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.exporter.otlp.endpoint=${SE_OTEL_EXPORTER_ENDPOINT}"
  fi
  if [ -n "$SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.java.global-autoconfigure.enabled=${SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED}"
  fi
  if [ -n "$SE_OTEL_JVM_ARGS" ]; then
    echo "List arguments for OpenTelemetry: ${SE_OTEL_JVM_ARGS}"
    SE_JAVA_OPTS="$SE_JAVA_OPTS ${SE_OTEL_JVM_ARGS}"
  fi
else
  append_se_opts "--tracing" "false"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Dwebdriver.remote.enableTracing=false"
  echo "Tracing is disabled"
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "All Selenium options: ${SE_OPTS}"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} router \
  --sessions-host "${SE_SESSIONS_MAP_HOST}" --sessions-port "${SE_SESSIONS_MAP_PORT}" \
  --distributor-host "${SE_DISTRIBUTOR_HOST}" --distributor-port "${SE_DISTRIBUTOR_PORT}" \
  --sessionqueue-host "${SE_SESSION_QUEUE_HOST}" --sessionqueue-port "${SE_SESSION_QUEUE_PORT}" \
  --bind-host ${SE_BIND_HOST} \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SUB_PATH_CONFIG} \
  ${SE_OPTS}
