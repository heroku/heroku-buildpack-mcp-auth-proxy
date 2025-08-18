# Heroku Buildpack: MCP Auth Proxy

This [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) installs an OAuth proxy for remote MCP servers. It downloads and installs the [OAuth Proxy Remote MCP Servers](https://github.com/heroku/mcp-remote-auth-proxy) application during Heroku builds with independent version management.

## Quick Setup

This buildpack adds an OAuth2.1/OIDC authentication proxy to your Heroku-hosted Remote MCP Server. You can only use this buildpack in [Private Space](https://devcenter.heroku.com/articles/private-spaces) apps.

Ensure that `mcp-remote-auth-proxy` is always the last buildpack so that its [default web process](bin/release) launches.

```bash
# Key-Value Store is required for clients and authorizations storage.
heroku addons:create heroku-redis:private-3 --as=MCP_AUTH_PROXY_REDIS

# Install the Heroku .netrc buildpack (if installing from a private repository)
heroku buildpacks:add --index 1 https://github.com/heroku/heroku-buildpack-github-netrc.git
# Install the required nodejs dependency
heroku buildpacks:set --index 2 heroku/nodejs
# Add the buildpack last
heroku buildpacks:set --index 3 https://github.com/heroku/heroku-buildpack-mcp-auth-proxy

# Pin to a specific version (recommended)
heroku config:set MCP_PROXY_VERSION=v1.2.3

# Configure the auth proxy

# Deploy 🚀
git push heroku main
```

Your app now includes the MCP Auth Proxy application in the `mcp-auth-proxy/` directory and it's configured as your default web process.

## Configuration

Take the following steps to configure a new Heroku app created in a Private Space, for an MCP Server that requires authorization for MCP clients.

### Auth Proxy Base URL

Set the base URL for the auth proxy to the public-facing HTTPS hostname of the Heroku app. The base URL is self-referential in auth flow redirect URIs. If you plan to deploy the app, use a [custom domain name](https://devcenter.heroku.com/articles/custom-domains).

```bash
heroku config:set \
  BASE_URL=https://<app-subdomain>.herokuapp.com
```

### MCP Server URL and Command

Set the internal, local URL for the proxy to reach the MCP Server, and the command to start it, by overriding the `PORT` set by Heroku runtime. For example:

```bash
heroku config:set \
  MCP_SERVER_URL=http://localhost:3000/mcp \
  MCP_SERVER_RUN_COMMAND="npm" \
  MCP_SERVER_RUN_ARGS_JSON='["start"]' \
  MCP_SERVER_RUN_DIR="/app" \
  MCP_SERVER_RUN_ENV_JSON='{"PORT":3000,"BACKEND_API_URL":"https://mcp.example.com"}'
```

### Auth Proxy Provider Cryptography
Generate the [JSON Web Key Set](https://github.com/panva/node-oidc-provider/tree/main/docs#jwks) (jwks) for auth proxy cryptographic material with the [JSON Web Key Generator](https://github.com/rakutentech/jwkgen):
```bash
heroku config:set \
  OIDC_PROVIDER_JWKS="[$(jwkgen --jwk)]"
```

### Identity Provider OAuth Client

Generate a new static OAuth client for the identity provider. This client's redirect URI origin must match the [Auth Proxy Base URL](#auth-proxy-base-url) (`BASE_URL`) origin.

> Each identity provider has its own process and interface to create OAuth clients. See their documentation for instructions.
After creating it, set the client ID, secret, Identity Provider URL, and OAuth scope to be granted with config vars:

```bash
heroku config:set \
  IDENTITY_SERVER_URL=https://identity.example.com \
  IDENTITY_CLIENT_ID=yyyyy \
  IDENTITY_CLIENT_SECRET=zzzzz \
  IDENTITY_SCOPE=global
```

#### Non-OIDC Providers

Optionally, for identity providers that don't support OIDC discovery,
reference a [ServerMetadata JSON file](https://github.com/panva/openid-client/blob/v6.x/docs/interfaces/ServerMetadata.md) that contains the `"issuer"`, `"authorization_endpoint"`, `"token_endpoint"`, and `"scopes_supported"` fields.

### Customization

* [Auth Proxy Views Directory](https://github.com/heroku/mcp-remote-auth-proxy?tab=readme-ov-file#auth-proxy-views-directory)
* [Branding Customization](https://github.com/heroku/mcp-remote-auth-proxy?tab=readme-ov-file#branding-customization)

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


### Release Verification

This buildpack sets up a default [Release Phase](https://devcenter.heroku.com/articles/release-phase) process for the app, which verifies that the build of the server will lauch with the runtime config variables, before the release is launched in the app.

When Release Verification succeeds, the release log will end with:
```
Verified release launches. Exit status 0
```
…and then Heroku will launch the release.

If the release fails, the release logs will show error message to help correct the issue. Push new commits, or retry the release using the [CLI command `heroku releases:retry`](https://devcenter.heroku.com/articles/heroku-cli-commands#heroku-releases-retry).

If an app defines its own `release` process in `Procfile`, then this default behavior will be skipped. This verification may be added to a custom `release` process by adding the same command defined in this buildpack's [bin/release](bin/release):

```bash
MCP_AUTH_PROXY_VERIFY_RELEASE=true PORT=3001 node mcp-auth-proxy/index.js
```

## Compatibility

- :white_check_mark: Cedar: Common Runtime
- :white_check_mark: Cedar: Private Spaces
- :white_check_mark: CI/CD pipelines
- :x: Fir
