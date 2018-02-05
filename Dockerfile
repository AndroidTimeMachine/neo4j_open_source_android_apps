FROM neo4j:3.3

COPY data /tmp/import
RUN bin/neo4j-admin import \
        --database=graph.db \
        --multiline-fields=true \
        --nodes '/tmp/import/apps.csv' \
        --nodes '/tmp/import/branches.csv' \
        --nodes '/tmp/import/commits/.*.csv' \
        --nodes '/tmp/import/contributors.csv' \
        --nodes '/tmp/import/play_pages.csv' \
        --nodes '/tmp/import/repos.csv' \
        --nodes '/tmp/import/tags.csv' \
        --relationships '/tmp/import/contribute_relations/.*.csv' \
        --relationships '/tmp/import/general_relations/.*.csv' \
        --relationships '/tmp/import/implemented_relations.csv' \
    && mkdir -p /var/persist_graph \
    && neo4j-admin dump \
        --database=graph.db \
        --to=/var/persist_graph/android_apps.dump \
    && rm -rf /tmp/import

# This is used to restore a dump of the database when
# running the container. The entry point of the parent
# image (/docker-entrypoint.sh) sources the script
# specified in EXTENSION_SCRIPT.
COPY scripts/load_db.sh /var/persist_graph/load_db.sh
ENV EXTENSION_SCRIPT=/var/persist_graph/load_db.sh

CMD ["neo4j"]
