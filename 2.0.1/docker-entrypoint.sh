#!/bin/bash
set -eo pipefail
shopt -s nullglob

JAVA_OPTS=${JAVA_OPTS:--Xms512m -Xmx1g}

declare -g JOURNAL_ALREADY_EXISTS
if [ -f "$BLAZEGRAPH_HOME/blazegraph.jnl" ]; then
    JOURNAL_ALREADY_EXISTS='true'
fi

_loadData() {
    namespace=$(basename "$1")
    if [ ! -e "$1/RWStore.properties" ]; then
        echo >&2 'No configuration file for the namespace'
		exit 1
	fi
    if [ ! -e "$1/data" ]; then
        echo >&2 'No data dir for namespace to import'
	fi
    dataloader=( java ${JAVA_OPTS} -cp /usr/bin/blazegraph.jar com.bigdata.rdf.store.DataLoader -namespace ${namespace} $1/RWStore.properties $1/data/ )
    echo "Loading namespace $namespace ..."
    "${dataloader[@]}"
}

if [ "$1" = 'blazegraph' ]; then
    # there's no journal, so it needs to be initialized
    if [ -z "$JOURNAL_ALREADY_EXISTS" ]; then
        for f in /docker-entrypoint-initdb.d/*; do
            if [ -e $f ];then
                _loadData "$f"
            fi
        done
        echo
        echo 'Blazegraph init process done. Ready for start up.'
        echo
    fi

    # run blazegraph
    opts=()
    if [ -e /etc/blazegraph/override.xml ]; then
        opts+=( -Djetty.overrideWebXml=/etc/blazegraph/override.xml )
    fi
    blazegraph=( java ${JAVA_OPTS} ${opts[@]} -jar /usr/bin/blazegraph.jar )
    exec "${blazegraph[@]}"
else
    exec "$@"
fi