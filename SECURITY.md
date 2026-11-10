# Security

If you find a security issue, please open a private [GitHub Security Advisory](https://github.com/themanoftalent/Bootayar/security/advisories/new).

## Notes

- Bootayar runs locally and only reads/writes local `launchd` plists, crontabs, and process tables.
- System-level changes (`/Library/LaunchAgents`, `/Library/LaunchDaemons`, `/etc/crontab`) prompt for macOS admin privileges and quote all shell arguments.
- Update checks only accept HTTPS releases from `github.com/themanoftalent/Bootayar`.
