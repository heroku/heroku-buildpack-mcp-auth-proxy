# Minimal HTTP MCP Server (Streamable HTTP)

This example is a tiny Node.js MCP server exposing a single `echo` tool over the Streamable HTTP transport at `/mcp`. It is intended to demonstrate a remote MCP server running on Heroku using the Heroku MCP Auth Proxy Buildpack running any HTTP-transport MCP server behind the MCP Auth Proxy buildpack on Heroku.

## Local run

```bash
npm install
PORT=3000 npm start
# POST and GET /mcp per Streamable HTTP,
# use MCP Inspector to connect: `npx @modelcontextprotocol/inspector http://localhost:3000/mcp --transport http`
```

## Heroku (with Auth Proxy buildpack)

### One-time app setup on Heroku

```bash
# 1) Create app (in a Private Space)
heroku apps:create <your-app> --space <your-private-space>

# 2) Add Redis for session storage (alias ensures MCP_AUTH_PROXY_REDIS_URL is set)
heroku addons:create heroku-redis:private-3 --as=MCP_AUTH_PROXY_REDIS -a <your-app>

# 3) Buildpacks (if your MCP server repo is private, add netrc first; otherwise skip)
heroku buildpacks:add --index 1 https://github.com/heroku/heroku-buildpack-github-netrc.git -a <your-app>
heroku buildpacks:add --index 2 heroku/nodejs -a <your-app>
heroku buildpacks:add --index 3 https://github.com/heroku/heroku-buildpack-mcp-auth-proxy -a <your-app>
```

Assuming this example directory is included in your Heroku slug (e.g. under `/app/examples/example-http-mcp-server`), set the following config with the Auth Proxy buildpack installed last:

```bash
# Base URL must match your app hostname
heroku config:set \
  BASE_URL=https://<your-app>.herokuapp.com \
  -a <your-app>

# Provider JWKS for the proxy
heroku config:set \
  OIDC_PROVIDER_JWKS="[$(jwkgen --jwk)]" \
  -a <your-app>

# Identity provider (example)
heroku config:set \
  IDENTITY_SERVER_URL=https://identity.example.com \
  IDENTITY_CLIENT_ID=xxxx \
  IDENTITY_CLIENT_SECRET=yyyy \
  IDENTITY_SCOPE="openid profile email offline_access" \
  -a <your-app>

# Point the proxy to the local MCP server and how to start it
heroku config:set \
  MCP_SERVER_URL=http://localhost:3000/mcp \
  MCP_SERVER_RUN_COMMAND="npm" \
  MCP_SERVER_RUN_ARGS_JSON='["start"]' \
  MCP_SERVER_RUN_DIR="/app/examples/option-b-http-mcp-server" \
  MCP_SERVER_RUN_ENV_JSON='{"PORT":3000}' \
  -a <your-app>
```

Deploy and tail logs:

```bash
git push heroku main
heroku logs --tail -a <your-app>
```

Test with MCP Inspector:

```bash
npx -y @modelcontextprotocol/inspector https://<your-app>.herokuapp.com/mcp --transport http
```

Complete the OAuth flow in your browser and then use the Inspector to call the `echo` tool.

## Notes

- Uses `@modelcontextprotocol/sdk` v1.17.x Streamable HTTP server transport.
- Endpoint path is fixed to `/mcp` for both POST and GET per spec.
- Minimal example for demo purposes only.
