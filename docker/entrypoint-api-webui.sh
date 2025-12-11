#!/bin/sh
set -e

if [ -d "/app/webui" ]; then
  busybox httpd -p "${WEBUI_PORT:-4173}" -h /app/webui
  echo "Web UI available at port ${WEBUI_PORT:-4173}"
fi

exec yarn start
