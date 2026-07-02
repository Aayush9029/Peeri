# Security Policy

## Supported Versions

Peeri is currently pre-release software. Security fixes are handled on the
default branch until stable public releases are available.

| Version | Supported |
| ------- | --------- |
| Default branch | Yes |
| Public releases | Best effort |

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues.

If GitHub private vulnerability reporting is available for this repository,
use the private advisory flow at:

https://github.com/Aayush9029/Peeri/security/advisories/new

Otherwise, email the maintainer at aayushpokharel9029@gmail.com with:

- A short summary of the issue
- Steps to reproduce or proof-of-concept details
- The affected commit, release, or build
- Any known impact or mitigation

You should receive an acknowledgement within 7 days. After the issue is
validated, the maintainer will share the expected fix timeline and coordinate
public disclosure when appropriate.

## Scope

This policy covers vulnerabilities in Peeri's macOS app code, bundled daemon
integration, JSON-RPC usage, and dependency handling. Vulnerabilities in
upstream projects such as aria2 or yt-dlp should also be reported to those
projects directly; Peeri may ship updated bundled binaries or mitigations when
needed.
