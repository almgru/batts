# Changelog

## Unreleased

### Removed

- '===' after battery name.

### Fixed

- If 59 minutes where rounded to 60, duration showed as "X hours, 60 minutes" instead of "X+1 hours, 0 minutes".
- Inconsistent hour/minutes output formatting.

## [0.1.3] - 2022-08-23

Remove support for other platforms.

### Removed

- Support for aarch64 and 32-bit x86 and ARM.

### Added

- runit service file.

### Fixed

- Crash when parsing log file if battery status was "Not charging".

## [0.1.2] - 2022-08-16

Adds support for x86 and armv7a.

### Added

- Support for 32-bit x86.
- Support for 32-bit armv7.

## [0.1.1] - 2022-08-16

Multiarch support.

### Added

- Adds support for ARMv8.

### Fixed

- Issue that caused `systemctl stop batstat-daemon` to occasionally timeout.

## [0.1.0] - 2022-08-16

Initial release.

### Added

- Command `batstat daemon`, which logs battery status, capacity and power draw for each connected battery.
- Command `batstat stats`, which prints statistics about the collected battery data.

