# Heroku Buildpack: MCP Auth Proxy

A [Heroku Buildpack](https://devcenter.heroku.com/articles/buildpacks) that installs an OAuth proxy for remote MCP servers.

Downloads and installs the [OAuth Proxy Remote MCP Servers](https://github.com/heroku/mcp-remote-auth-proxy) application during Heroku builds with independent version management.

## Quick Setup

This buildpack adds an OAuth2.1/OIDC authentication proxy to your Heroku-hosted Remote MCP Server (Private Spaces is required).

Ensure that `mcp-remote-auth-proxy` is always the last buildpack so that its [default web process](bin/release) is launched.

```bash
# Key-Value store is required for clients & authorizations storage.
heroku addons:create heroku-redis:private-3 --as=MCP_AUTH_PROXY_REDIS

# Install the Heroku .netrc buildpack (if installing from a private repository)
heroku buildpacks:add --index 1 https://github.com/heroku/heroku-buildpack-github-netrc.git
# Install the required nodejs dependency
heroku buildpacks:set --index 2 heroku/nodejs
# Add the buildpack last
heroku buildpacks:set --index 3 https://github.com/heroku/heroku-buildpack-mcp-auth-proxy

# Pin to a specific version (recommended)
heroku config:set MCP_PROXY_VERSION=v1.2.3

# Configure the auth proxy using the instructions below 👇

# Deploy 🚀
git push heroku main
```

Your app now includes the MCP Auth Proxy application in the `mcp-auth-proxy/` directory and is configured as your default web process.

## Configuration

With a new Heroku app, created in a Private Space, for an MCP Server repo like [mcp-heroku-com](https://github.com/heroku/mcp-heroku-com).

### Auth Proxy Base URL

Set the base URL for the auth proxy to the public-facing https hostname of the Heroku app. Should be a custom domain name for real deployments. This is self-referential in auth flow redirect URIs:

```bash
heroku config:set \
  BASE_URL=https://<app-subdomain>.herokuapp.com
```

### MCP Server URL & Command

Set the internal, local URL for the proxy to reach the MCP Server, and the command to start it, overriding whatever the `PORT` is already set to be by Heroku runtime. For example:

```bash
heroku config:set \
  MCP_SERVER_URL=http://localhost:3000/mcp \
  MCP_SERVER_RUN_COMMAND="npm" \
  MCP_SERVER_RUN_ARGS_JSON='["start"]' \
  MCP_SERVER_RUN_DIR="/app/mcp-heroku-com" \
  MCP_SERVER_RUN_ENV_JSON='{"PORT":3000,"HEROKU_API_URL":"https://api.staging.herokudev.com"}'
```

### Auth Proxy Provider Cryptography

Generate the cryptographic material for the auth proxy using [jwkgen](https://github.com/rakutentech/jwkgen) to generate [jwks](https://github.com/panva/node-oidc-provider/tree/main/docs#jwks):

```bash
heroku config:set \
  OIDC_PROVIDER_JWKS="[$(jwkgen --jwk)]"
```

### Heroku Identity Provider OAuth Client

Generate a new static OAuth client for the Identity provider. This client's redirect URI origin must match the [Auth Proxy Base URL](#auth-proxy-base-url) `BASE_URL` origin.

```bash
heroku clients:create mcp-heroku-com-with-auth-proxy 'https://<app-subdomain>.herokuapp.com/interaction/identity/callback'
```

Once created, set the client ID & secret in the config vars, along with the Identity Provider's URL & OAuth scope to be granted.

```bash
heroku config:set \
  IDENTITY_SERVER_URL=https://identity.staging.herokudev.com \
  IDENTITY_CLIENT_ID=yyyyy \
  IDENTITY_CLIENT_SECRET=zzzzz \
  IDENTITY_SCOPE=global
```

#### Non-OIDC Providers

Optionally, for Identity providers that do not support OIDC discovery,
reference a [ServerMetadata JSON file](https://github.com/panva/openid-client/blob/v6.x/docs/interfaces/ServerMetadata.md), containing: `"issuer"`, `"authorization_endpoint"`, `"token_endpoint"`, & `"scopes_supported"`.

For example, Heroku Identity staging (or production) requires,

```bash
heroku config:set \
  IDENTITY_SERVER_METADATA_FILE='/app/mcp-auth-proxy/heroku_identity_staging_metadata.json'
```

### View Customization

1. [Auth Proxy Views Directory](https://github.com/heroku/mcp-remote-auth-proxy?tab=readme-ov-file#auth-proxy-views-directory)
2. [Branding Customization](https://github.com/heroku/mcp-remote-auth-proxy?tab=readme-ov-file#branding-customization)

> [!NOTE]
> **Credential Handling with TLS**
>
> While MCP Auth Proxy exists in a controlled environment via Private Space, developers may want to use their own self-signed certificates. To support this flexibility, the MCP Auth Proxy sets `rejectUnauthorized` to `false` for all TLS configuration settings.

## Version Control

```bash
# Release method
# Pin to tested release versions (https://github.com/heroku/mcp-remote-auth-proxy/releases)
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
> - `MCP_PROXY_VERSION` defaults to `latest` (the most recent [release](https://github.com/heroku/mcp-remote-auth-proxy/releases/latest))
> - `MCP_PROXY_GIT_REF` defaults to `main` (if using the `git` download method)

## Application Installation

The buildpack installs the MCP Auth Proxy (Node) application to `/app/mcp-auth-proxy/` in your slug.

## Compatibility

- :white_check_mark: Cedar: Common Runtime
- :white_check_mark: Cedar: Private Spaces
- :white_check_mark: CI/CD pipelines
- :x: Fir
