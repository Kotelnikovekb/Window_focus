## [1.1.0] - 2025-01-12
### Added
- **Debug Mode:**
    - Added the ability to enable debug mode (`debug`) via the plugin constructor or the `setDebug(bool debug)` method. In debug mode, detailed logs of user activity and window changes are printed to the console.

- **Customizable Idle Timeout:**
    - You can now set the user idle timeout (`idleThreshold`) in the plugin constructor or using the `setIdleThreshold(Duration duration)` method.

### Changed
- **Improved Project Structure:**
    - Updated project structure to improve readability and support for new features.
    - Methods for tracking user activity and active windows now work correctly on the Windows platform.

- **Documentation Updates:**
    - Added detailed descriptions for methods and classes, including usage examples.

### Fixed
- Fixed issues with tracking user activity on the Windows platform.
- Improved error handling for invalid arguments passed to native methods.

### Template
- Updated the usage example in the `example/` folder. The example demonstrates:
    - How to use the debug mode.
    - How to set and retrieve the idle timeout.
    - How to track active windows and user activity.

## 1.0.0

* Initial release
