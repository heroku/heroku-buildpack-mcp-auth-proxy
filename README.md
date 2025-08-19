# Heroku Buildpack: MCP Auth Proxy

A standalone Heroku buildpack that downloads and installs the MCP (Model Context Protocol) Auth Proxy from releases, enabling flexible deployment and version management.

## Overview

This buildpack provides a clean separation between application code and buildpack functionality by downloading the MCP auth proxy from the main repository releases. It supports multiple version pinning strategies and download methods.

## Quick Start

### 1. Detection

The buildpack automatically detects MCP proxy applications by looking for:
- `mcp-proxy.yml` configuration file
- `app.json` containing `mcp-auth-proxy` reference

### 2. Usage

Add this buildpack to your Heroku app:

```bash
heroku buildpacks:set https://github.com/heroku/heroku-buildpack-mcp-auth-proxy
```

### 3. Version Configuration

Specify the MCP proxy version in your `app.json`:

```json
{
  "env": {
    "MCP_PROXY_VERSION": "v1.2.3"
  }
}
```

Or use environment variables:

```bash
heroku config:set MCP_PROXY_VERSION=v1.2.3
```

## Configuration Options

### Version Pinning

- `MCP_PROXY_VERSION`: Git tag, commit hash, or "latest" (default: "latest")
- `MCP_PROXY_DOWNLOAD_METHOD`: "release", "git", or "url" (default: "release")
- `MCP_PROXY_URL`: Direct download URL (for "url" method)

### Version Resolution Precedence

1. Environment variables (highest priority)
2. `app.json` configuration
3. "latest" default (lowest priority)

## Download Methods

### Release Downloads (Default)
```bash
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=release
heroku config:set MCP_PROXY_VERSION=v1.2.3
```

### Git Cloning
```bash
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=git
heroku config:set MCP_PROXY_VERSION=main
```

### Custom URL
```bash
heroku config:set MCP_PROXY_DOWNLOAD_METHOD=url
heroku config:set MCP_PROXY_URL=https://example.com/custom-build.tar.gz
```

## Development

### Repository Structure

```
heroku-buildpack-mcp-auth-proxy/
├── bin/
│   ├── compile           # Main build script
│   ├── detect            # App detection logic
│   └── release           # Runtime configuration
├── lib/                  # Library functions (TBD)
│   ├── version-resolver.sh
│   ├── downloader.sh
│   └── installer.sh
├── README.md
└── CHANGELOG.md
```

### Testing

The buildpack can be tested locally or with Heroku CLI:

```bash
# Test detection
./bin/detect /path/to/test/app

# Test compilation (requires Heroku environment)
./bin/compile /path/to/build/dir /path/to/cache/dir /path/to/env/dir
```

## Contributing

Please refer to the main MCP Remote Auth Proxy repository for contribution guidelines and development setup.

## License

This buildpack follows the same licensing as the main MCP Remote Auth Proxy project.
