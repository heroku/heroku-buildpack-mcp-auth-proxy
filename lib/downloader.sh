#!/usr/bin/env bash

download_proxy() {
  local method=${MCP_PROXY_DOWNLOAD_METHOD:-"release"}

  case "$method" in
    "release")
      download_release "$VERSION"
      ;;
    "git")
      clone_git_ref "$GIT_REF"
      ;;
    *)
      echo "ERROR: Unknown download method: $method"
      exit 1
      ;;
  esac
}

download_release() {
  local repo="heroku/mcp-remote-auth-proxy"
  local version="$1"

  if [[ "$version" == "latest" ]]; then
    version=$(get_latest_release_tag "$repo")
  fi

  local download_url="https://github.com/$repo/archive/$version.tar.gz"

  echo "-----> Downloading from: $download_url"
  curl -L --fail --retry 3 "$download_url" | tar -xz -C "$CACHE_DIR" || {
    echo "ERROR: Failed to download release $version"
    exit 1
  }

  # Find the extracted directory (GitHub archives extract to repo-name-version format)
  local extracted_dir=$(find "$CACHE_DIR" -maxdepth 1 -name "mcp-remote-auth-proxy-*" -type d | head -1)
  if [[ -z "$extracted_dir" ]]; then
    echo "ERROR: Could not find extracted source directory"
    exit 1
  fi

  install_dependencies "$extracted_dir"

  # Move to expected location for installer
  local target_dir="$CACHE_DIR/mcp-auth-proxy"
  if [[ -d "$target_dir" ]]; then
    rm -rf "$target_dir"
  fi
  mv "$extracted_dir" "$target_dir"
}

get_latest_release_tag() {
  local repo=$1

  # Make API request
  local api_response=$(curl -s \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    --max-time 30 \
    --retry 3 \
    "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null)

  local curl_exit_code=$?

  # Check if curl succeeded
  # Check if the curl command failed (non-zero exit code indicates an error)
  if [[ $curl_exit_code -ne 0 ]]; then
    echo "ERROR: Failed to fetch latest release for $repo (curl exit code: $curl_exit_code)" >&2
    return 1
  fi

  # Check for authentication errors
  if echo "$api_response" | jq -e '.message' >/dev/null 2>&1; then
    local error_msg=$(echo "$api_response" | jq -r '.message')

    if [[ "$error_msg" == "Not Found" ]]; then
      echo "ERROR: Repository $repo not found or private." >&2
      echo "       For private repositories, install the GitHub netrc buildpack:" >&2
      echo "       heroku buildpacks:add -i 1 https://github.com/heroku/heroku-buildpack-github-netrc.git" >&2
      echo "       heroku config:set GITHUB_AUTH_TOKEN=<your_token>" >&2
      return 1
    else
      echo "ERROR: GitHub API error for $repo: $error_msg" >&2
      return 1
    fi
  fi

  # Extract and validate tag_name
  echo "$api_response" | jq -r '.tag_name'
}

clone_git_ref() {
  local git_ref=$1
  local repo_url="https://github.com/heroku/mcp-remote-auth-proxy.git"
  local source_dir="$CACHE_DIR/source"

  echo "-----> Cloning $repo_url at $git_ref into $source_dir"
  if [[ -d "$source_dir" ]]; then
    rm -rf "$source_dir"
  fi
  git clone --depth 1 --branch "$git_ref" "$repo_url" "$source_dir" || {
    echo "ERROR: Failed to clone git reference $git_ref"
    exit 1
  }

  install_dependencies "$source_dir"
}

install_dependencies() {
  local source_dir=$1 # Directory containing package.json

  echo "-----> Installing npm dependencies"
  cd "$source_dir" || {
    echo "ERROR: Could not enter source directory"
    exit 1
  }

  npm install --production || {
    echo "ERROR: npm install failed"
    exit 1
  }

  echo "-----> MCP Auth Proxy application ready"
}
