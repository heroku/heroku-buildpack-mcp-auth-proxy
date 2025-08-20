#!/usr/bin/env bash

download_proxy() {
  local method=${MCP_PROXY_DOWNLOAD_METHOD:-"release"}

  case "$method" in
    "release")
      download_release "$VERSION"
      ;;
    "git")
      clone_git_version "$VERSION"
      ;;
    *)
      echo "ERROR: Unknown download method: $method"
      exit 1
      ;;
  esac
}

download_release() {
  local version=$1
  local repo="heroku/mcp-remote-auth-proxy"

  if [[ "$version" == "latest" ]]; then
    local download_url="https://github.com/$repo/releases/latest/download/mcp-auth-proxy.tar.gz"
  else
    local download_url="https://github.com/$repo/releases/download/$version/mcp-auth-proxy.tar.gz"
  fi

  echo "-----> Downloading from: $download_url"
  curl -L --fail --retry 3 "$download_url" | tar -xz -C "$CACHE_DIR" || {
    echo "ERROR: Failed to download release $version"
    exit 1
  }

  install_dependencies "$CACHE_DIR/mcp-auth-proxy"
}

clone_git_version() {
  local version=$1
  local repo_url="https://github.com/heroku/mcp-remote-auth-proxy.git"
  local source_dir="$CACHE_DIR/source"

  echo "-----> Cloning $repo_url at $version"
  git clone --depth 1 --branch "$version" "$repo_url" "$source_dir" || {
    echo "ERROR: Failed to clone version $version"
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
