ARG OSRM_BASE_IMAGE=ghcr.io/project-osrm/osrm-backend:v6.0.0
FROM ${OSRM_BASE_IMAGE}

ARG OSRM_DATA_BASENAME=tokyo
ENV OSRM_DATA_BASENAME=${OSRM_DATA_BASENAME}
ENV OSRM_ALGORITHM=mld

COPY tmp/osrm/*.osrm* /data/
COPY infrastructure/osrm/entrypoint.sh /usr/local/bin/osrm-entrypoint.sh
RUN chmod +x /usr/local/bin/osrm-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/osrm-entrypoint.sh"]
