#!/bin/bash

# $1: GitHub owner name

# Get repository list (default limit is 30, so increase to handle many repos)
repos=$(gh repo list "$1" --limit 1000 --json name -q '.[].name')
echo "owner: $1"

# Set secrets in repositories
for repo in $repos; do
  # Skip terraform-github repository
  if [ "$repo" == "terraform-github" ]; then
    echo "Skipping terraform-github"
    continue
  fi

  echo ""
  echo "Setting secret for $repo"

  gh secret set GHA_APP_ID --repo "$1/$repo" --body "$GHA_APP_ID"
  gh secret set GHA_APP_PRIVATE_KEY --repo "$1/$repo" --body "$GHA_APP_PRIVATE_KEY"
  gh secret set OPENAI_API_KEY --repo "$1/$repo" --body "$OPENAI_API_KEY"
done
