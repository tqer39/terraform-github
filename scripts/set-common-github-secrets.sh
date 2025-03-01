#!/bin/bash

# $1: GitHub owner name

# Get repository list
repos=$(gh repo list "$1" --json name -q '.[].name')

# Set secrets in repositories
for repo in $repos; do
  echo "Setting secret for $repo"

  gh api -X PUT \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "/repos/$1/$repo/actions/secrets/GHA_APP_ID" \
    -f encrypted_value="$GHA_APP_ID" \
    -f key_id="$(gh api "/repos/$1/$repo/actions/secrets/public-key" | jq -r .key_id)"

  gh api -X PUT \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "/repos/$1/$repo/actions/secrets/GHA_APP_PRIVATE_KEY" \
    -f encrypted_value="$GHA_APP_PRIVATE_KEY" \
    -f key_id="$(gh api "/repos/$1/$repo/actions/secrets/public-key" | jq -r .key_id)"

  gh api -X PUT \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "/repos/$1/$repo/actions/secrets/OPENAI_API_KEY" \
    -f encrypted_value="$OPENAI_API_KEY" \
    -f key_id="$(gh api "/repos/$1/$repo/actions/secrets/public-key" | jq -r .key_id)"

done
