# Ubuntu Dependency Fixer

A comprehensive script for resolving dependency issues on Ubuntu systems. This tool provides diagnostics, error handling, and user guidance to fix broken dependencies, manage PPAs, and update packages.

## Features

- **Fix Broken Dependencies**: Automatically detects and fixes broken dependencies using `dpkg` and `apt-get`.
- **Manage PPAs**: Add or remove common PPAs (Kisak and Oibaf) and show the status of these PPAs.
- **Clean Package Cache**: Clean and remove unnecessary packages to free up space.
- **Update and Upgrade Packages**: Update the package list and upgrade all packages to their latest versions.
- **Diagnostics**: Identifies common package issues and provides detailed logging.
- **User Guidance**: Offers steps and advice to the end user for troubleshooting persistent issues.
- **Detailed Summary**: Provides a summary of all actions taken during the script execution.

## Usage

1. **Copy the Script to a USB Drive**:
   - Insert the USB drive into your computer.
   - Open a terminal and identify your USB drive using `lsblk`.
   - Mount the USB drive if it's not already mounted:
     ```bash
     sudo mount /dev/sdX1 /mnt/usb
     ```
     Replace `/dev/sdX1` with the correct device identifier for your USB drive.
   - Copy the script to the USB drive:
     ```bash
     cp fix_dependency_hell.sh /mnt/usb/
     ```
   - Unmount the USB drive:
     ```bash
     sudo umount /mnt/usb
     ```

2. **Run the Script on the Target Machine**:
   - Insert the USB drive into the target machine.
   - Open a terminal and create a mount point:
     ```bash
     sudo mkdir -p /mnt/usb
     ```
   - Mount the USB drive:
     ```bash
     sudo mount /dev/sdX1 /mnt/usb
     ```
     Replace `/dev/sdX1` with the correct device identifier for your USB drive on the target machine.
   - Navigate to the mounted USB drive:
     ```bash
     cd /mnt/usb
     ```
   - Make the script executable and run it:
     ```bash
     chmod +x fix_dependency_hell.sh
     sudo ./fix_dependency_hell.sh
     ```

## Menu Options

1. **Show Common Package Status**: Displays the installation status of common packages.
2. **Manage PPAs**: Add, remove, or check the status of Kisak and Oibaf PPAs.
3. **Fix Broken Dependencies**: Automatically detects and fixes broken dependencies.
4. **Clean Package Cache**: Cleans and removes unnecessary packages.
5. **Update and Upgrade Packages**: Updates the package list and upgrades all packages.
6. **Show Summary**: Displays a summary of all actions taken during the script execution.
7. **User Guidance**: Provides troubleshooting steps and advice for persistent issues.
8. **Exit**: Exits the script.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or suggestions.

## Support

If you encounter any issues or have any questions, please open an issue on the [GitHub repository](https://github.com/Diadems666/FIX-DEPENDANCY-HELL).

