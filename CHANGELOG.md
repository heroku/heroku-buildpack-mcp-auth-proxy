# Changelog

All notable changes to the Heroku Buildpack MCP Auth Proxy will be documented in this file.

See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure with `bin/`, `lib/` directories
- Complete buildpack implementation with `compile`, `detect`, `release` scripts
- Environment variable-based app detection for MCP Auth Proxy applications
- Version resolution library (`lib/version-resolver.sh`) with ENV_DIR support
- Download strategy library (`lib/downloader.sh`) supporting release and git methods
- Installation library (`lib/installer.sh`) for Node.js application deployment
- Runtime configuration with `web: node mcp-auth-proxy/index.js` process type
- Comprehensive README.md with usage instructions and troubleshooting
- Support for release version pinning via `MCP_PROXY_VERSION`
- Support for git reference targeting via `MCP_PROXY_GIT_REF`
- Automatic npm dependency installation for both download methods
- Build caching and error handling with retry logic

### Changed
- N/A (initial release)

## v0.0.0

* initial release

---

## Versioning Strategy

This buildpack will follow semantic versioning:
- **MAJOR**: Incompatible buildpack API changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

Version tags will be in the format `vX.Y.Z` (e.g., `v1.0.0`).
