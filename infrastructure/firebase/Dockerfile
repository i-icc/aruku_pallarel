FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-17-jre-headless \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g firebase-tools@13.11.2

WORKDIR /workspace

EXPOSE 8080 9099

CMD ["firebase", "emulators:start"]
