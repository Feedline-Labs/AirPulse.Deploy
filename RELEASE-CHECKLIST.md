# AirPulse.Deploy Release Checklist

Use this checklist before creating a deployment tag consumed by an official AirPulse release.

## Review

- [ ] Every changed command has been reviewed.
- [ ] No official script references an unintended test URL, branch, or local path.
- [ ] No Linux script hard-codes `airpulse-user` or `/home/airpulse-user`.
- [ ] Required architecture and operating-system checks are present.
- [ ] Downloads use trusted sources and are verified when practical.
- [ ] File ownership and permissions are correct.
- [ ] Service restart behavior matches AirPulse requirements.
- [ ] Failure messages are clear and actionable.

## Testing

- [ ] Clean installation tested.
- [ ] Existing-user installation tested.
- [ ] Username other than `airpulse-user` tested.
- [ ] Re-running the installer tested.
- [ ] Upgrade from current production version tested.
- [ ] Service start tested.
- [ ] Service stop and shutdown tested.
- [ ] Reboot recovery tested.
- [ ] Interrupted or failed installation behavior tested.
- [ ] Rollback or recovery procedure tested.
- [ ] Final deployed AirPulse runtime tested.

## Release

- [ ] Only approved files are under `FeedlineLabs`.
- [ ] Community files are not included in the official deployment package.
- [ ] Repository changes are committed.
- [ ] A versioned deployment tag is created.
- [ ] The AirPulse build consumes that exact tag.
- [ ] The final AirPulse package is tested after synchronization.
