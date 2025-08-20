# Heroku Buildpack: MCP Auth Proxy

A [Heroku Buildpack](https://devcenter.heroku.com/articles/buildpacks) that installs an OAuth proxy for remote MCP servers.

Downloads and installs the [OAuth Proxy Remote MCP Servers](https://github.com/heroku/mcp-remote-auth-proxy) application during Heroku builds with independent version management.

## Quick Setup

```bash
# Add the buildpack
heroku buildpacks:set https://github.com/heroku/heroku-buildpack-mcp-auth-proxy

# Pin to a specific version (recommended)
heroku config:set MCP_PROXY_VERSION=v1.2.3

# Deploy
git push heroku main
```

Your app now includes the MCP Auth Proxy application in the `mcp-auth-proxy/` directory.

## Detection Logic

The buildpack activates when it finds any of these core runtime configuration vars set:
- `MCP_AUTH_PROXY_REDIS_URL`
- `IDENTITY_SERVER_URL`
- `MCP_SERVER_URL`

If all three are unset, the buildpack skips the app entirely.

## Version Control

```bash
# Release method
# Pin to tested release versions
heroku config:set MCP_PROXY_VERSION=v1.2.3
# Test latest stable release
heroku config:set MCP_PROXY_VERSION=latest

# Git Clone method
# Use a feature branch
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=git MCP_PROXY_GIT_REF=feature-auth-v2
# Use a specific commit
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=git MCP_PROXY_GIT_REF=abc123def
# Use a git tag
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=git MCP_PROXY_GIT_REF=v2.0.0-beta
```
> [!NOTE]
> - `MCP_PROXY_DOWNLOAD_METHOD` defaults to `release`
> - `MCP_PROXY_VERSION` defaults to `latest` (the most recent stable release)
> - `MCP_PROXY_GIT_REF` defaults to `main` (if using the `git` download method)

## Application Installation

The buildpack installs the MCP Auth Proxy (Node) application to `/app/mcp-auth-proxy/` in your slug.

The application is ready to run with `node index.js` and configured as your default web process.

## Compatibility

- :white_check_mark: Cedar: Common Runtime
- :white_check_mark: Cedar: Private Spaces
- :white_check_mark: CI/CD pipelines
- :x: Fir
