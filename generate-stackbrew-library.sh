#!/bin/bash


# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}


# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}


# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

# End Methods

set -eu

if [ "${1:-}" == '-v' ]; then
  set -x
	shift
fi

# declare -A aliases=()

DOCKER_REPO='jnbnyc'
GIT_REPO=$(git remote get-url origin)
GIT_ROOT=$(git rev-parse --show-toplevel)
MAINTAINERS=$(cat MAINTAINERS)  # default maintainers

self="$(basename "$BASH_SOURCE")"
self_commit="$(fileCommit "$self")"
# cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
cd ${1:-./}

versions=( */ )
versions=( "${versions[@]%/}" )

[ -f 'MAINTAINERS' ] && MAINTAINERS=$(cat MAINTAINERS)
cat <<-EOH
# this file is generated via ${GIT_REPO}/blob/$self_commit/$self

Maintainers: ${MAINTAINERS}
GitRepo: ${GIT_REPO%%.git}
EOH
[ -z "$DOCKER_REPO" ] || echo "Constraints: ${DOCKER_REPO}"


for version in "${versions[@]}"; do
	commit="$(dirCommit "$version")"

	fullVersion="$(git show "$commit":"./$version/Dockerfile" | awk '$1 == "ENV" && $2 == "THIS_VERSION" { print $3; exit }')"
	if [ -z "$fullVersion" ] && [ -f "./$version/version.txt" ]; then
		fullVersion="$(cat ./$version/version.txt)"
	fi

	declare -A aliases=()
	if [ -f "./$version/aliases" ]; then
		aliases[$version]="latest $(cat $version/aliases)"
	fi

	versionAliases=(
		$fullVersion
		$version
		${aliases[$version]:-}
	)

	echo
	cat <<-EOE
		Tags: $(join ', ' "${versionAliases[@]}")
		GitCommit: $commit
		Directory: $(git rev-parse --show-prefix)$version
	EOE

	for v in \
		slim alpine wheezy onbuild \
		windows/windowsservercore windows/nanoserver \
	; do
		dir="$version/$v"
		variant="$(basename "$v")"

		[ -f "$dir/Dockerfile" ] || continue

		commit="$(dirCommit "$dir")"

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			GitCommit: $commit
			Directory: $dir
		EOE
		[ "$variant" = "$v" ] || echo "Constraints: $variant"
	done
done
