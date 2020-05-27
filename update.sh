#!/bin/bash
set -e

defaultImage='openjdk:8-alpine'
declare -A images=(
	[2.0.0]='openjdk:8-alpine'
	[2.0.1]='openjdk:8-alpine'
	[2.1.0]='openjdk:8-alpine'
	[2.1.1]='openjdk:8-alpine'
	[2.1.2]='openjdk:8-alpine'
	[2.1.4]='openjdk:8-alpine'
	[2.1.5]='openjdk:8-alpine'
	[2.1.6]='adoptopenjdk/openjdk9:alpine'
)

declare -A urlBlazeGraphSuites=(
	[2.0.0]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_0_0/blazegraph.jar'
	[2.0.1]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_0_1/blazegraph.jar'
	[2.1.0]='https://sourceforge.net/projects/bigdata/files/bigdata/2.1.0/blazegraph.jar/download'
	[2.1.1]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_1_1/blazegraph.jar'
	[2.1.2]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_1_2/blazegraph.jar'
	[2.1.4]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_1_4/blazegraph.jar'
	[2.1.5]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_1_5/blazegraph.jar'
	[2.1.6]='https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_2_1_6_RC/bigdata.jar'
)

versions=( "$@" )

if [ ${#versions[@]} -eq 0 ]; then
	versions=("${!urlBlazeGraphSuites[@]}")
fi
versions=( "${versions[@]%/}" )
for version in "${versions[@]}"; do
    echo "produce $version"
    dockerfiles=()
    if [ ! -e "$version" ]; then
        mkdir "$version"
    fi

    # prepare Dockerfile
    mkdir -p "$version/docker-entrypoint-initdb.d/kb"
	{ cat Dockerfile.template; } > "$version/Dockerfile"
	{ cat README.template; } > "$version/README.md"
	{ cat RWStore.properties; } > "$version/docker-entrypoint-initdb.d/kb/RWStore.properties"

    cp  \
            docker-entrypoint.sh \
            "$version/"

    image="${images[$version]:-$defaultImage}"
    url="${urlBlazeGraphSuites[$version]}"
    fullVersion="${version}"
    dockerfiles+=( "$version/Dockerfile" )

    for f in "${version}"/*; do
        if [ ! -d "${f}" ]; then
            (
                sed -ri \
                    -e 's!%%BLAZEGRAPH_VERSION%%!'"$fullVersion"'!' \
                    -e 's!%%BLAZEGRAPH_URL%%!'"$url"'!' \
                    -e 's!%%IMAGE%%!'"$image"'!' \
                    ${f}
            )
        fi
    done
done