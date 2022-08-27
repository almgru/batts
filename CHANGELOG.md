# Changelog

## Unreleased

### Added

- Current and factory default capacity in Watt-hours for capacity health.

### Changed

- Update busted to v. 2.1.1.

### Fixed

- Systemd service not finding executable if it's not stored in /usr/bin or /usr/local/bin. Now searches in /opt/batts,
  $HOME/.bin and $HOME/.local/bin as well.

## [0.1.6] - 2022-08-27

### Changed

- Renames project to `batts`.
- Use tabs to improve readability of stats output.
- Reorder stats in stats output.

## [0.1.5] - 2022-08-26

### Added

- Standard deviation for extrapolated full charge discharge time.

## [0.1.4] - 2022-08-25

### Added

- Uncertainty/standard deviation for mean off-line power draw.

### Removed

- '===' after battery name.
- Filtering out outliers.

### Changed

- Use plus-minus sign instead of sigma sign for uncertainty.

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

