#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if heroku CLI is available
if ! command -v heroku &> /dev/null; then
    log_error "Heroku CLI not found. Please install it first."
    exit 1
fi

create_local_test_app() {
	local package_json='
	{
		"name": "hb-mcp-auth-proxy-test",
		"version": "0.1.0",
		"description": "A Heroku Buildpack MCP auth proxy test app",
		"main": "index.js",
		"engines": {
			"node": ">=22.16.0"
		},
		"type": "module",
		"scripts": {
			"start": "node index.js"
		}
	}'
	local index_js='console.log("Hello, world!");'
	# remove if it exists
	if [ -d "$TEST_APP_DIR" ]; then
		rm -rf "$TEST_APP_DIR"
	fi
	# Create test app directory
	mkdir -p "$TEST_APP_DIR"
	# Create package.json
	echo "$package_json" > "$TEST_APP_DIR/package.json"
	# Create index.js
	echo "$index_js" > "$TEST_APP_DIR/index.js"
	# CD to test app directory and init git
	cd "$TEST_APP_DIR"
	git init
	git add .
	git commit -m "Initial commit"
}

setup_heroku_app() {
	local app_name=$1
	local team_name=$2
	if heroku apps:info "$app_name" &>/dev/null; then
		heroku apps:destroy "$app_name" --confirm "$app_name"
	fi
	log_info "Creating heroku app"
	log_info "heroku create $app_name --team $team_name"
	heroku create "$app_name" --team "$team_name"
	log_info "Setting config variables"
	# Set config variables
	heroku config:set -a "$app_name" BASE_URL=https://example-mcp-server-with-auth-proxy-5f63807b3fb0.herokuapp.com GITHUB_AUTH_TOKEN="$GITHUB_AUTH_TOKEN"
	log_info "Setting buildpacks"
	heroku buildpacks:add --index 1 https://github.com/heroku/heroku-buildpack-github-netrc.git
	heroku buildpacks:set --index 2 heroku/nodejs
	log_info "Setting buildpack for MCP Auth Proxy"
	heroku buildpacks:set --index 3 https://github.com/heroku/heroku-buildpack-mcp-auth-proxy.git#"$CURRENT_BRANCH"
}

deploy_release_mode() {
	local version=$1
	heroku config:set MCP_PROXY_DOWNLOAD_METHOD=release MCP_PROXY_VERSION="$version"
	# empty commit to trigger a new release
	git commit --allow-empty -m "Trigger release of version $version"
	git push heroku main -f
}

deploy_git_mode() {
	local git_ref=$1
	heroku config:set MCP_PROXY_DOWNLOAD_METHOD=git MCP_PROXY_GIT_REF="$git_ref"
	# empty commit to trigger a new release
	git commit --allow-empty -m "Trigger release of git ref deployment $git_ref"
	git push heroku main -f
}

load_env() {
	export $(grep -v '^#' .env | xargs)
}

# Loading variables from .env
log_info "Loading env from .env"
load_env

# Get the test app name from BUILDPACK_TEST_APP, defaults to hb-mcp-auth-proxy
TEST_APP="${BUILDPACK_TEST_APP:-hb-mcp-auth-proxy-test}"
TEST_APP_TEAM="${BUILDPACK_TEST_APP_TEAM:-heroku-dev-tools}"
TEST_APP_DIR="tests/test-app"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log_info "Using test app: $TEST_APP ($TEST_APP_TEAM)"

# Create local test app
log_info "Creating test app"
create_local_test_app
log_info "Setting up heroku app"
setup_heroku_app "$TEST_APP" "$TEST_APP_TEAM"
# Add heroku remote
log_info "Adding heroku remote"
heroku git:remote -a "$TEST_APP"
log_info "Deploying in release mode (latest)"
deploy_release_mode "latest"
log_info "Deploying in release mode (v0.1.0)"
deploy_release_mode "v0.1.0"
log_info "Deploying in git mode (main branch)"
deploy_git_mode "main"
log_info "Deploying in git mode (v0.1.0 tag)"
deploy_git_mode "v0.1.0"
# Clean up
log_info "Cleaning up"
heroku apps:destroy "$TEST_APP" --confirm "$TEST_APP"
cd ../ && rm -rf "$TEST_APP_DIR"
log_info "Test has completed successfully"
