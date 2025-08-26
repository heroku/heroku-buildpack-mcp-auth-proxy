#!/usr/bin/env bash

resolve_version() {
  local method=${MCP_PROXY_DOWNLOAD_METHOD:-"release"}

  case "$method" in
    "release")
      if [[ -s "$ENV_DIR/MCP_PROXY_VERSION" ]]; then
        VERSION=$(cat "$ENV_DIR/MCP_PROXY_VERSION")
        echo "-----> Using release version: $VERSION"
      else
        VERSION="latest"
        echo "-----> Using latest release"
      fi
      ;;
    "git")
      if [[ -s "$ENV_DIR/MCP_PROXY_GIT_REF" ]]; then
        GIT_REF=$(cat "$ENV_DIR/MCP_PROXY_GIT_REF")
        echo "-----> Using git reference: $GIT_REF"
      else
        GIT_REF="main"
        echo "-----> Using default branch: main"
      fi
      ;;
    *)
      echo "ERROR: Unknown download method: $method"
      exit 1
      ;;
  esac
}
