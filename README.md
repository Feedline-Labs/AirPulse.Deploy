# AirPulse.Deploy

Official and community-maintained deployment resources for **Feedline Labs AirPulse**.

This repository keeps installation scripts, service definitions, deployment helpers, and platform-specific setup documentation separate from the AirPulse C# source repositories. It provides one clear place for the community to propose improvements while ensuring that only reviewed and tested files are promoted into official Feedline Labs releases.

## Repository model

AirPulse.Deploy has two intentionally separate areas:

```text
AirPulse.Deploy/
├── FeedlineLabs/
└── Community/
```

### `FeedlineLabs`

The `FeedlineLabs` directory contains the official deployment files maintained, reviewed, and tested by Feedline Labs.

Files in this directory may be included in AirPulse release packages or synchronized into projects such as `AirPulse.Updater`. Changes should only be promoted here after they have been reviewed and tested on the intended operating system and hardware.

**The presence of a file in `FeedlineLabs` means it is an approved Feedline Labs deployment file.**

### `Community`

The `Community` directory is for alternative installers, experiments, improvements, and platform support contributed by AirPulse users and developers.

Community contributions:

- may support additional Linux distributions, existing Raspberry Pi installations, custom usernames, or nonstandard installation paths;
- may combine several installation steps into a simpler installer;
- may be incomplete, experimental, or tested only in a limited environment;
- are not automatically included in official AirPulse releases;
- are not supported by Feedline Labs unless they are reviewed, tested, and promoted into `FeedlineLabs`.

Nothing under `Community` should ever be executed or shipped automatically by an official AirPulse build.

## Supported platform folders

Both `FeedlineLabs` and `Community` contain matching folders for the five AirPulse deployment targets:

```text
RaspberryPi-ARM64/
Linux-x64/
Windows-x64/
macOS-ARM64/
macOS-x64/
```

Some folders may initially contain only a `README.md`. Git does not preserve empty directories, so these files keep the complete platform structure visible in GitHub until deployment files are added.

## Recommended contribution workflow

```text
Community proposal
        ↓
Pull request and review
        ↓
Testing on the intended platform
        ↓
Testing of upgrade and rollback behavior
        ↓
Feedline Labs adapts or promotes the approved work
        ↓
Files are placed in FeedlineLabs
        ↓
A tested repository tag is created
        ↓
AirPulse release tooling consumes that exact tag
```

Community changes should not be copied blindly into official deployment files. Feedline Labs should retain final control over structure, naming, behavior, safety checks, and supportability.

## Important portability requirement

Official Linux and Raspberry Pi scripts should not assume that AirPulse is installed for a user named `airpulse-user`.

Deployment scripts should support:

- a normal existing user account;
- installation through `sudo`;
- an explicitly supplied AirPulse username;
- a configurable installation directory;
- a home directory discovered from the operating system rather than constructed manually.

A typical pattern is:

```bash
AIRPULSE_USER="${AIRPULSE_USER:-${SUDO_USER:-$USER}}"
AIRPULSE_HOME="$(getent passwd "$AIRPULSE_USER" | cut -d: -f6)"
AIRPULSE_DIR="${AIRPULSE_DIR:-$AIRPULSE_HOME/airpulse}"
```

Every script and generated service file should use those resolved values instead of hard-coded paths such as:

```text
/home/airpulse-user
```

Before promotion into `FeedlineLabs`, this behavior should be tested with at least:

```text
/home/airpulse-user/airpulse
/home/pi/airpulse
/home/<existing-user>/airpulse
```

## How official files should be consumed

`AirPulse.Deploy` should be the authoritative source for deployment files. The AirPulse C# repositories should contain only a synchronized release copy when packaging requires local files.

Recommended process:

1. Update and test files in `AirPulse.Deploy`.
2. Commit the approved changes.
3. Create a release tag, for example `deploy-2026.7.1`.
4. Synchronize only the contents of `FeedlineLabs` from that exact tag into the required C# project.
5. Build and test the AirPulse release.
6. Do not consume the moving `main` branch during a production build.

This keeps deployment work independent from application code while preserving reproducible releases.

## Testing expectations

Before a deployment file is promoted into `FeedlineLabs`, test as applicable:

- clean operating-system installation;
- existing machine with an established user account;
- installation under a username other than `airpulse-user`;
- paths containing the expected user home directory;
- repeated execution of the installer;
- service installation and startup;
- service shutdown and restart behavior;
- upgrade from the current production release;
- failure and rollback behavior;
- required permissions and file ownership;
- network loss or interrupted download;
- platform architecture detection;
- shell syntax and line endings.

A script should fail clearly and safely when a prerequisite is missing. It should not leave a partially configured service running without reporting the problem.

## Branch and release guidance

A simple repository policy is recommended:

- `main` contains reviewed repository content.
- Pull requests are required for changes.
- Only trusted Feedline Labs maintainers may modify `FeedlineLabs`.
- Community contributors submit work under `Community`.
- Official builds use a tested tag rather than the latest branch state.

GitHub branch protection should prevent direct pushes to `main` once the repository is established.

## Line endings

The included `.gitattributes` forces Linux shell scripts and service files to use LF line endings. This prevents Windows Git clients from converting them to CRLF and breaking execution on Linux.

## Security

Deployment scripts run with significant privileges. Review every command that:

- uses `sudo`;
- creates or edits a system service;
- changes device permissions;
- installs packages;
- downloads or executes external files;
- modifies users or groups;
- removes files or directories.

Downloads should use trusted HTTPS sources and should be pinned or verified when practical. Never promote a community script into `FeedlineLabs` without understanding every command it runs.

## Licensing

No open-source license is included by default. Feedline Labs should choose and add the appropriate license before accepting broad third-party contributions. Until a license is added, contributors should not assume that repository content may be redistributed outside the terms stated by Feedline Labs.

## Repository ownership

Official deployment files are maintained by Feedline Labs. Community submissions remain proposals until they are explicitly reviewed, tested, and promoted.
