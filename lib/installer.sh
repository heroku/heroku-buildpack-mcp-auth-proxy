#!/usr/bin/env bash

install_proxy() {
  local app_dir="$BUILD_DIR/mcp-auth-proxy"

  echo "-----> Installing MCP Auth Proxy application"

  # Create application directory
  mkdir -p "$app_dir"

  # Copy the entire Node.js application from source or release
  if [[ -d "$CACHE_DIR/source" ]]; then
    echo "-----> Copying application from git source"
    cp -r "$CACHE_DIR/source/." "$app_dir/"
  elif [[ -d "$CACHE_DIR/mcp-auth-proxy" ]]; then
    echo "-----> Copying application from release"
    cp -r "$CACHE_DIR/mcp-auth-proxy/." "$app_dir/"
  else
    echo "ERROR: Could not find MCP Auth Proxy application source"
    echo "       Cache contents:"
    ls -la "$CACHE_DIR"
    exit 1
  fi

  # Verify critical files exist
  if [[ -f "$app_dir/package.json" && -f "$app_dir/index.js" && -d "$app_dir/node_modules" ]]; then
    echo "-----> MCP Auth Proxy application installed to mcp-auth-proxy/"
    echo "-----> Installation verified successfully"
  else
    echo "ERROR: Installation verification failed"
    echo "       Expected: package.json, index.js, and node_modules/"
    echo "       Application directory contents:"
    ls -la "$app_dir"
    exit 1
  fi
}
