# sing-packer
Helper scripts that automate downloading, configuring, and running [sing-box](https://github.com/SagerNet/sing-box) on Windows, Linux, and macOS

## Features
* Configure behavior through the included environment file
* Download sing-box directly from the official GitHub releases
    * Automatic architecture detection
    * Automatic re-download when the configured version changes
* Fetch config from a remote URL
    * Config expiration and automatic refresh support
    * Basic authentication support
* Run sing-box with the required privileges
    * macOS and Linux: `sudo`
    * Windows: UAC elevation
* Improved Windows experience
    * Starts with the console window minimized for a smoother experience
    * Prevents the console window from closing on errors to aid debugging

## Usage
1. Download the release for your operating system from the [releases page](https://github.com/red-bean-pasta/sing-packer/releases/latest)
2. Extract the archive
3. Follow the included instructions
    
## Note
This project is intended to facilitate using sing-box on operating systems without an official GUI, such as Windows, Linux, or older versions of macOS.
For Android and iOS, please refer to the official GUI apps.
