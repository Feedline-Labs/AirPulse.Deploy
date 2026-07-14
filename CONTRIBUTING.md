# Contributing to AirPulse.Deploy

Thank you for helping improve AirPulse installation and deployment.

The goal of this repository is to welcome useful community work without allowing untested changes to flow directly into official AirPulse releases.

## Where contributions belong

Community contributions must be placed under the matching platform folder:

```text
Community/<Platform>/<Contribution-Name>/
```

Example:

```text
Community/
└── RaspberryPi-ARM64/
    └── existing-user-installer/
        ├── README.md
        ├── install.sh
        └── uninstall.sh
```

Use a descriptive folder name. Do not place unrelated alternatives directly beside one another without separate folders.

Do not modify files under `FeedlineLabs` unless a Feedline Labs maintainer specifically requests it.

## Required contribution documentation

Every contribution should include a `README.md` describing:

- what the contribution does;
- supported operating systems and versions;
- supported CPU architecture;
- hardware used for testing;
- whether it supports clean and existing installations;
- required packages and permissions;
- default installation path;
- how the target user is selected;
- how to install;
- how to uninstall or roll back;
- known limitations;
- exact tests performed.

## User and path requirements

Linux and Raspberry Pi contributions should not hard-code `airpulse-user` or `/home/airpulse-user`.

Prefer values derived from the operating system:

```bash
AIRPULSE_USER="${AIRPULSE_USER:-${SUDO_USER:-$USER}}"
AIRPULSE_HOME="$(getent passwd "$AIRPULSE_USER" | cut -d: -f6)"
AIRPULSE_DIR="${AIRPULSE_DIR:-$AIRPULSE_HOME/airpulse}"
```

Validate that the selected user exists before modifying the system.

## Script quality

Shell scripts should normally begin with:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Scripts should:

- use clear function names;
- quote variables;
- check prerequisites before making changes;
- report each major action;
- return a nonzero exit code on failure;
- avoid destructive commands unless absolutely necessary;
- be safe to run more than once when practical;
- preserve existing user data and settings;
- clearly explain any required reboot.

## Pull requests

A pull request should explain:

- the problem being solved;
- why the proposed approach is safe;
- the platforms and hardware tested;
- the exact test procedure;
- possible upgrade or compatibility risks;
- whether existing AirPulse installations were tested.

Submission does not make a script official. Feedline Labs may request changes, adapt only part of a contribution, or decline it.

## Promotion into FeedlineLabs

Only Feedline Labs maintainers may promote work into `FeedlineLabs`.

Promotion requires review and testing. The official implementation may differ from the community version so it remains consistent with AirPulse release and support requirements.
