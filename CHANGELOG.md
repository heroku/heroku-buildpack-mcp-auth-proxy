# Changelog

All notable changes to the Heroku Buildpack MCP Auth Proxy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial repository structure with `bin/`, `lib/` directories
- Basic buildpack scripts: `compile`, `detect`, `release`
- App detection logic for `mcp-proxy.yml` and `app.json` configurations
- Runtime configuration with default web process type
- README.md with usage instructions and configuration options
- Support for multiple version resolution strategies (planned)
- Support for multiple download methods: release, git, url (planned)

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- N/A (initial release)

## [0.1.0] - TBD

### Added
- Initial buildpack structure and foundation
- Basic detection and placeholder compilation logic

---

## Versioning Strategy

This buildpack will follow semantic versioning:
- **MAJOR**: Incompatible buildpack API changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

Version tags will be in the format `vX.Y.Z` (e.g., `v1.0.0`).
