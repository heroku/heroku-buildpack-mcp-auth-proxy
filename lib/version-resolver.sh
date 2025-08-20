#!/usr/bin/env bash

resolve_version() {
  # Check for version in environment directory
  if [[ -s "$ENV_DIR/MCP_PROXY_VERSION" ]]; then
    VERSION=$(cat "$ENV_DIR/MCP_PROXY_VERSION")
    echo "-----> Using version from environment: $VERSION"
    return
  fi

  # Default to latest release
  VERSION="latest"
  echo "-----> Using latest release"
}
