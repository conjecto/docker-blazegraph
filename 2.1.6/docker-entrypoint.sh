#!/bin/bash
set -eo pipefail
shopt -s nullglob

JAVA_PARAMS=""

if [ ! -z "$JAVA_XMS" ]; then
    JAVA_PARAMS+=( -Xms"${JAVA_XMS}" )
else
    JAVA_PARAMS+=( -Xms512m )
fi

if [ ! -z "$JAVA_XMX" ]; then
    JAVA_PARAMS+=( -Xmx"${JAVA_XMX}" )
else
    JAVA_PARAMS+=( -Xmx1g )
fi

declare -g JOURNAL_ALREADY_EXISTS
if [ -d "$BLAZEGRAPH_HOME/blazegraph.jnl" ]; then
    JOURNAL_ALREADY_EXISTS='true'
fi

_loadData() {
    namespace=$(basename "$1")
    if [ ! -e "$1/RWStore.properties" ]; then
        echo >&2 'No configuration file for the namespace'
		exit 1
	fi
    if [ ! -e -d "$1/data" ]; then
        echo >&2 'No data dir for namespace to import'
	fi
    dataloader=( java ${JAVA_PARAMS[@]} -cp /usr/bin/blazegraph.jar com.bigdata.rdf.store.DataLoader -namespace ${namespace} $1/RWStore.properties $1/data/ )
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
    conf=()
    if [ -e /etc/blazegraph/override.xml ]; then
        conf+=( -Djetty.overrideWebXml=/etc/blazegraph/override.xml )
    fi
    blazegraph=( java ${JAVA_PARAMS[@]} ${conf[@]} -jar /usr/bin/blazegraph.jar )
    exec "${blazegraph[@]}"
else
    exec "$@"
fi