# Requirements Document

## Introduction

This document specifies the requirements for implementing Flutter APK building with split-per-abi configuration. The feature enables building separate APK files for different CPU architectures (armeabi-v7a, arm64-v8a, x86_64) instead of a single universal APK. This approach reduces download sizes for end users, as they only download the APK matching their device's architecture, and improves installation performance by eliminating unnecessary native libraries.

## Glossary

- **Build_System**: The Flutter build toolchain that compiles and packages the application
- **Split_APK**: An APK file containing native libraries for a single CPU architecture
- **ABI**: Application Binary Interface - defines the CPU architecture (armeabi-v7a, arm64-v8a, x86_64)
- **Universal_APK**: A single APK file containing native libraries for all supported architectures (also called "fat APK")
- **Build_Configuration**: The set of parameters and flags passed to the Flutter build command
- **Output_Artifacts**: The APK files produced by the build process
- **Build_Validator**: Component that verifies the correctness of generated APK files
- **Architecture_Detector**: Component that identifies which architectures are present in an APK

## Requirements

### Requirement 1: Execute Split-Per-ABI Build Command

**User Story:** As a developer, I want to execute the Flutter build command with split-per-abi configuration, so that I can generate separate APK files for each supported architecture.

#### Acceptance Criteria

1. WHEN the build command is invoked with the --split-per-abi flag, THE Build_System SHALL execute `flutter build apk --split-per-abi`
2. WHEN the build completes successfully, THE Build_System SHALL produce multiple APK files in the build output directory
3. WHEN the build fails, THE Build_System SHALL return a non-zero exit code and display error messages
4. THE Build_System SHALL preserve all existing build flags and configuration options when adding --split-per-abi
5. WHEN the build is executed, THE Build_System SHALL output progress information to the console

### Requirement 2: Generate Architecture-Specific APK Files

**User Story:** As a developer, I want the build system to generate separate APK files for each architecture, so that users download only the APK matching their device.

#### Acceptance Criteria

1. WHEN the split-per-abi build completes, THE Build_System SHALL generate an APK file for armeabi-v7a architecture
2. WHEN the split-per-abi build completes, THE Build_System SHALL generate an APK file for arm64-v8a architecture
3. WHEN the split-per-abi build completes, THE Build_System SHALL generate an APK file for x86_64 architecture
4. THE Output_Artifacts SHALL include only the native libraries for the corresponding architecture in each APK
5. WHEN examining any Split_APK, THE Architecture_Detector SHALL identify exactly one ABI type
6. FOR ALL generated Split_APKs, the sum of file sizes SHALL be less than the size of an equivalent Universal_APK

### Requirement 3: Maintain APK Naming Convention

**User Story:** As a developer, I want APK files to follow a clear naming convention, so that I can easily identify which architecture each file targets.

#### Acceptance Criteria

1. WHEN a Split_APK is generated for armeabi-v7a, THE Build_System SHALL include "armeabi-v7a" in the filename
2. WHEN a Split_APK is generated for arm64-v8a, THE Build_System SHALL include "arm64-v8a" in the filename
3. WHEN a Split_APK is generated for x86_64, THE Build_System SHALL include "x86_64" in the filename
4. THE Build_System SHALL follow the Flutter standard naming pattern: app-{architecture}-release.apk
5. FOR ALL Split_APKs, parsing the filename SHALL correctly identify the target architecture

### Requirement 4: Preserve Application Functionality Across Architectures

**User Story:** As a developer, I want each architecture-specific APK to contain all necessary application code and resources, so that the app functions identically regardless of which APK is installed.

#### Acceptance Criteria

1. FOR ALL Split_APKs, THE Build_System SHALL include identical Dart code and assets
2. FOR ALL Split_APKs, THE Build_System SHALL include identical Android manifest configurations
3. FOR ALL Split_APKs, THE Build_System SHALL include identical application resources (images, fonts, strings)
4. WHEN comparing any two Split_APKs, THE Build_Validator SHALL verify that only native library files differ
5. FOR ALL Split_APKs, the application version code and version name SHALL be identical

### Requirement 5: Validate Build Output Correctness

**User Story:** As a developer, I want to verify that generated APKs are valid and installable, so that I can confidently distribute them to users.

#### Acceptance Criteria

1. FOR ALL generated Split_APKs, THE Build_Validator SHALL verify the APK signature is valid
2. FOR ALL generated Split_APKs, THE Build_Validator SHALL verify the APK can be parsed without errors
3. FOR ALL generated Split_APKs, THE Build_Validator SHALL verify the AndroidManifest.xml is well-formed
4. WHEN extracting native libraries from a Split_APK, THE Build_Validator SHALL verify they match the declared architecture
5. FOR ALL Split_APKs, THE Build_Validator SHALL verify the APK contains no native libraries for other architectures

### Requirement 6: Verify Architecture-Library Correspondence

**User Story:** As a developer, I want to ensure each APK contains only the correct native libraries, so that installation size is minimized and there are no architecture mismatches.

#### Acceptance Criteria

1. WHEN examining the armeabi-v7a APK, THE Architecture_Detector SHALL find only armeabi-v7a .so files
2. WHEN examining the arm64-v8a APK, THE Architecture_Detector SHALL find only arm64-v8a .so files
3. WHEN examining the x86_64 APK, THE Architecture_Detector SHALL find only x86_64 .so files
4. FOR ALL Split_APKs, THE Build_Validator SHALL verify no lib/{other-abi}/ directories exist
5. FOR ALL native libraries in a Split_APK, parsing the ELF header SHALL confirm the architecture matches the APK's declared ABI

### Requirement 7: Handle Build Configuration Persistence

**User Story:** As a developer, I want build configurations to be preserved across builds, so that I don't need to specify --split-per-abi every time.

#### Acceptance Criteria

1. WHERE a build configuration file exists, THE Build_System SHALL read the split-per-abi setting from the configuration
2. WHERE a build configuration file exists with split-per-abi enabled, THE Build_System SHALL apply --split-per-abi without requiring the command-line flag
3. WHEN the --split-per-abi flag is provided via command line, THE Build_System SHALL override any configuration file settings
4. THE Build_Configuration SHALL support both enabled and disabled states for split-per-abi builds
5. WHEN the configuration changes from split to universal or vice versa, THE Build_System SHALL clean previous build artifacts

### Requirement 8: Report Build Metrics and Output Locations

**User Story:** As a developer, I want to see build metrics and output locations, so that I can verify the build succeeded and locate the APK files.

#### Acceptance Criteria

1. WHEN the build completes successfully, THE Build_System SHALL display the file path for each generated Split_APK
2. WHEN the build completes successfully, THE Build_System SHALL display the file size for each generated Split_APK
3. WHEN the build completes successfully, THE Build_System SHALL display the total build time
4. THE Build_System SHALL display the size reduction compared to a Universal_APK build
5. WHEN multiple APKs are generated, THE Build_System SHALL display a summary table with architecture, filename, and size for each APK

### Requirement 9: Maintain Build Reproducibility

**User Story:** As a developer, I want builds to be reproducible, so that rebuilding with the same source code and configuration produces identical APKs.

#### Acceptance Criteria

1. WHEN building twice with identical source code and configuration, THE Build_System SHALL produce Split_APKs with identical content hashes
2. FOR ALL Split_APKs from the same build, the build timestamp SHALL be identical
3. WHEN comparing two builds from the same source, THE Build_Validator SHALL verify that file ordering within APKs is deterministic
4. THE Build_System SHALL use deterministic compilation flags for native code
5. FOR ALL Split_APKs, parsing and re-serializing the manifest SHALL produce identical output (round-trip property)

### Requirement 10: Handle Build Errors Gracefully

**User Story:** As a developer, I want clear error messages when builds fail, so that I can quickly identify and fix issues.

#### Acceptance Criteria

1. WHEN the Flutter SDK is not found, THE Build_System SHALL display an error message indicating the SDK path is invalid
2. WHEN native compilation fails for a specific architecture, THE Build_System SHALL display which architecture failed and the compiler error
3. WHEN disk space is insufficient, THE Build_System SHALL display an error message indicating insufficient storage
4. WHEN dependencies are missing, THE Build_System SHALL display which dependencies need to be installed
5. IF a build error occurs, THEN THE Build_System SHALL clean up partial build artifacts and return a non-zero exit code

### Requirement 11: Support Integration with CI/CD Pipelines

**User Story:** As a DevOps engineer, I want the build command to work in automated environments, so that I can integrate it into continuous integration pipelines.

#### Acceptance Criteria

1. THE Build_System SHALL support non-interactive execution without requiring user input
2. WHEN executed in a CI environment, THE Build_System SHALL detect and use CI-specific environment variables
3. THE Build_System SHALL provide machine-readable output formats (JSON or structured logs) for build results
4. WHEN the build completes, THE Build_System SHALL exit with status code 0 for success and non-zero for failure
5. THE Build_System SHALL support parallel builds when multiple architectures are being compiled

## Notes

### Build Output Location

By default, Flutter places split APK files in:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Size Reduction Benefits

Split APKs typically reduce download size by 30-50% compared to universal APKs, as each APK contains only one set of native libraries instead of three.

### Distribution Considerations

When distributing split APKs, developers should use Google Play's App Bundle format or provide a mechanism for users to select the correct APK for their device architecture.
