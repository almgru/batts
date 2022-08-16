# Changelog

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

