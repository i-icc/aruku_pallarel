#!/bin/sh
set -e

data_basename="${OSRM_DATA_BASENAME:-tokyo}"
algorithm="${OSRM_ALGORITHM:-mld}"
port="${PORT:-8080}"

exec osrm-routed --algorithm "${algorithm}" --port "${port}" "/data/${data_basename}.osrm"
