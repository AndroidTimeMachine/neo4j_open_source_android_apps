#!/bin/bash
#
# Load database dump into /data volume if no other database exists.

set -e
set -u

mkdir -p /data/databases
echo "Importing data ..."
neo4j-admin load \
        --from=/var/persist_graph/android_apps.dump \
        --database=graph.db \
    || echo "Continue without importing."
