main() {
  local last_tag
  local new_tag

  if [ -z "$(git tag)" ]; then
    last_tag="${INITIAL_VERSION_PREFIX}0.0.0"
  else
    last_tag=$(git describe --tags --abbrev=0)
  fi
  new_tag=$(semver bump "$semver_increment" "$last_tag")

  if [[ "$last_tag" == v* ]]; then
    tag_prefix="v"
  elif  [[ "$last_tag" == V* ]]; then
    tag_prefix="V"
  else
    tag_prefix=""
  fi

  release_github "${tag_prefix}${new_tag}"
}

release_github() {
  local new_tag
  new_tag="$1"
  local json

  release_changelog=""
  if [ "$CHANGELOG" == "1" ]; then
    if [ "$last_tag" == "${INITIAL_VERSION_PREFIX}0.0.0" ]; then
      release_changelog=$(git log --pretty=format:'* %s (%h)' HEAD)
    else
      release_changelog=$(git log --pretty=format:'* %s (%h)' "$last_tag"..HEAD)
    fi
  fi

  json=$(jq -n \
    --arg tag_name "$new_tag" \
    --arg target_commitish "$CIRCLE_SHA1" \
    --arg name "Release $new_tag" \
    --arg body "$release_changelog" \
    '{
      tag_name: $tag_name,
      target_commitish: $target_commitish,
      name: $name,
      body: $body,
      draft: false,
      prerelease: false
    }'
  )

  curl \
    -X POST \
    -S -s -o /dev/null \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$json" \
    "https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/releases"
  
  echo "Release $new_tag created."
}

get_semver_increment() {
  local commit_subject
  commit_subject=$(git log -1 --pretty=%s.)
  semver_increment=$(echo "$commit_subject" | sed -En 's/.*\[semver:(major|minor|patch|skip)\].*/\1/p')

  echo "Commit subject: $commit_subject"
  echo "SemVer increment: $semver_increment"

  if [ -z "$semver_increment" ]; then
    echo "Commit subject did not indicate which SemVer increment to make."
    echo "To create the tag and release, you can ammend the commit or push another commit with [semver:INCREMENT] in the subject where INCREMENT is major, minor, patch."
    echo "Note: To indicate intention to skip, include [semver:skip] in the commit subject instead."
  elif [ "$semver_increment" == "skip" ]; then
    echo "SemVer in commit indicated to skip release."
  fi
}

check_increment() {
  if [ -z "$semver_increment" ] || [ "$semver_increment" == "skip" ]; then
    echo "no"
  else
    echo "yes"
  fi
}

check_for_envs() {
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "The GITHUB_TOKEN environment variable is not set."
    echo "You must set a GITHUB_TOKEN environment variable."
    exit 1
  fi
}

check_for_programs() {
  if ! command -v curl &> /dev/null; then
    echo "You must have curl installed to use this orb."
    exit 1
  fi

  if [ "$(id -u)" == 0 ]; then 
    export SUDO=""
  else 
    export SUDO="sudo"
  fi

  if ! command -v semver &> /dev/null; then
    semver_version="3.2.0"
    echo "Installing semver version $semver_version"
    wget -qO- "https://github.com/fsaintjacques/semver-tool/archive/$semver_version.tar.gz" | tar xzf -
    chmod +x "semver-tool-$semver_version/src/semver"
    "$SUDO" cp "semver-tool-$semver_version/src/semver" /usr/local/bin
  fi

  if ! command -v jq &> /dev/null; then
    jq_version="1.6"
    echo "Installing jq version $jq_version"

    if [ "$(uname -m)" == "x86_64" ]; then
      arch="64"
    else
      arch="32"
    fi

    wget -qO jq "https://github.com/stedolan/jq/releases/download/jq-$jq_version/jq-linux$arch"
    chmod +x jq
    "$SUDO" cp jq /usr/local/bin
  fi
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
  get_semver_increment
  if [ "$(check_increment)" == "yes" ]; then
    check_for_envs
    check_for_programs
    main
  fi
fi
