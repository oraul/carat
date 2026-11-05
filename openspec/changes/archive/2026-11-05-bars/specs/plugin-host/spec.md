## MODIFIED Requirements

### Requirement: The host refuses a newer major API version
The API SHALL have a version in `major.minor` form, 2.2 since the `set_segment` request lets a plugin give its status bar segment a priority. A manifest written against a different major version, or against the host's major version with a newer minor, SHALL be refused with a message naming the plugin, the version it needs, and the version the host has; a manifest with the same major and the host's minor or an older one SHALL be accepted.

#### Scenario: Newer major
- **WHEN** a plugin's manifest names API version "3.0"
- **THEN** the plugin is disabled and the host records that the plugin needs API 3.0 and the host has 2.2

#### Scenario: Older major
- **WHEN** a plugin's manifest names API version "1.3"
- **THEN** the plugin is disabled and the host records that it needs API 1.3

#### Scenario: Newer minor
- **WHEN** a plugin's manifest names API version "2.3"
- **THEN** the plugin is disabled and the host records that it needs API 2.3 and the host has 2.2

#### Scenario: Older minor
- **WHEN** a plugin's manifest names API version "2.1", the host's major with a minor older than the host's
- **THEN** the plugin is accepted

## ADDED Requirements

### Requirement: A plugin sets its status bar segment with a priority
A plugin SHALL set its own status bar segment with a text and a priority from 0 to 99 through `set_segment`; an empty text SHALL remove the segment, a priority outside 0 to 99 SHALL fail with "priority must be 0 to 99" and change nothing, and `set_status` SHALL set the segment at priority 10. The segments SHALL be shown in the order the plugins first set them and dropped by their priorities when the bar is narrow, and a disabled plugin's segment SHALL be removed.

#### Scenario: A segment with a priority
- **WHEN** a test plugin sets the segment "probe" with priority 95
- **THEN** the bar shows " probe " before the encoding and keeps it after the percent and the position have been dropped for width

#### Scenario: An out-of-range priority
- **WHEN** a test plugin sets a segment with priority 100
- **THEN** the response fails with "priority must be 0 to 99" and the bar shows no segment of that plugin

#### Scenario: set_status keeps working
- **WHEN** the hello plugin's greeting sets its status text "hello 1"
- **THEN** the bar shows " hello 1 " at priority 10
