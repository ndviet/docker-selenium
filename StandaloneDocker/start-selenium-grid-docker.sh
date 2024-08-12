#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Standalone Docker..."

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
  else
    export SE_OPTS
    echo "Selenium option: ${option} already set in env variable SE_OPTS. Skipping new option: ${option} ${value}"
  fi
}

if [ ! -z "$SE_NODE_GRID_URL" ]; then
  echo "Appending Grid url: ${SE_NODE_GRID_URL}"
  SE_GRID_URL="--grid-url ${SE_NODE_GRID_URL}"
fi

append_se_opts "--enable-managed-downloads" "${SE_NODE_ENABLE_MANAGED_DOWNLOADS}"
append_se_opts "--enable-cdp" "${SE_NODE_ENABLE_CDP}"
append_se_opts "--register-period" "${SE_NODE_REGISTER_PERIOD}"
append_se_opts "--register-cycle" "${SE_NODE_REGISTER_CYCLE}"
append_se_opts "--heartbeat-period" "${SE_NODE_HEARTBEAT_PERIOD}"
append_se_opts "--log-level" "${SE_LOG_LEVEL}"
append_se_opts "--http-logs" "${SE_HTTP_LOGS}"
append_se_opts "--structured-logs" "${SE_STRUCTURED_LOGS}"
append_se_opts "--external-url" "${SE_EXTERNAL_URL}"
append_se_opts "--session-request-timeout" "${SE_SESSION_REQUEST_TIMEOUT}"
append_se_opts "--session-retry-interval" "${SE_SESSION_RETRY_INTERVAL}"
append_se_opts "--relax-checks" "${SE_RELAX_CHECKS}"

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
  ${EXTRA_LIBS} standalone \
  --detect-drivers false \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${SE_GRID_URL} ${SE_OPTS}
