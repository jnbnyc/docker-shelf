#!/bin/bash
set -eu
# set -x

declare -A aliases=(
	[jessie]="latest $(cat jessie/version.txt)"
)

DOCKER_REPO='jnbnyc'
GIT_REPO=$(git remote get-url origin)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

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

cat <<-EOH
# this file is generated via ${GIT_REPO}/blob/$(fileCommit "$self")/$self

Maintainers: $(cat MAINTAINERS)
GitRepo: ${GIT_REPO%%.git}
EOH
[ -z "$DOCKER_REPO" ] || echo "Constraints: ${DOCKER_REPO}"

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	commit="$(dirCommit "$version")"

	fullVersion="$(git show "$commit":"$version/Dockerfile" | awk '$1 == "ENV" && $2 == "THIS_VERSION" { print $3; exit }')"

	versionAliases=(
		$fullVersion
		$version
		${aliases[$version]:-}
	)

	echo
	cat <<-EOE
		Tags: $(join ', ' "${versionAliases[@]}")
		GitCommit: $commit
		Directory: $version
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
