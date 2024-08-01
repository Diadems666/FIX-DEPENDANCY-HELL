#!/bin/bash

LOG_FILE="dependency_fix.log"
PACKAGE_LIST_BACKUP="package_list_backup.txt"
RETRY_LIMIT=3
PPAS=("ppa:kisak/kisak-mesa" "ppa:oibaf/graphics-drivers")
COMMON_PACKAGES=("libglx-mesa0" "libgbm1" "openjdk-21-jdk" "libegl-mesa0" "vlc-plugin-video-output")

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Function to fix broken dependencies using dpkg
fix_broken() {
    log "Attempting to fix broken dependencies..."
    if ! sudo dpkg --configure -a | tee -a $LOG_FILE; then
        log "Failed to reconfigure packages."
        return 1
    fi
    if ! sudo apt-get install -f -y | tee -a $LOG_FILE; then
        log "Failed to fix broken dependencies."
        return 1
    fi
    return 0
}

# Function to remove a problematic package using dpkg
remove_package() {
    package=$1
    log "Removing package $package using dpkg..."
    if ! sudo dpkg --remove --force-remove-reinstreq $package | tee -a $LOG_FILE; then
        log "Failed to remove package $package."
        return 1
    fi
    return 0
}

# Function to install a package using dpkg
install_package() {
    package=$1
    log "Installing package $package using dpkg..."
    if ! sudo apt-get download $package; then
        log "Failed to download package $package."
        return 1
    fi
    if ! sudo dpkg -i ${package}_*.deb | tee -a $LOG_FILE; then
        log "Failed to install package $package."
        return 1
    fi
    if ! sudo apt-get install -f -y | tee -a $LOG_FILE; then
        log "Failed to fix broken dependencies after installing package $package."
        return 1
    fi
    return 0
}

# Function to clean up the package cache using apt-get and dpkg
clean_package_cache() {
    log "Cleaning package cache..."
    if ! sudo apt-get clean | tee -a $LOG_FILE; then
        log "Failed to clean package cache."
        return 1
    fi
    if ! sudo apt-get autoremove -y | tee -a $LOG_FILE; then
        log "Failed to remove unnecessary packages."
        return 1
    fi
    return 0
}

# Function to update and upgrade packages using apt-get
update_and_upgrade() {
    log "Updating package list..."
    if ! sudo apt-get update | tee -a $LOG_FILE; then
        log "Failed to update package list."
        return 1
    fi

    log "Upgrading packages..."
    if ! sudo apt-get upgrade -y | tee -a $LOG_FILE; then
        log "Failed to upgrade packages."
        return 1
    fi
    return 0
}

# Function to identify broken packages using dpkg
identify_broken_packages() {
    log "Identifying broken packages..."
    broken_packages=$(dpkg -l | grep -E '^iU' | awk '{print $2}')
    echo $broken_packages
}

# Function to retry fixing broken packages
retry_fix() {
    package=$1
    attempt=$2

    log "Attempt $attempt to fix $package"

    if fix_broken && remove_package $package && install_package $package; then
        if ! dpkg -l | grep -E "^iU" | grep -q $package; then
            log "Successfully fixed $package"
            return 0
        fi
    fi
    log "Failed to fix $package in attempt $attempt"
    return 1
}

# Function to remove problematic PPA
remove_ppa() {
    ppa=$1
    log "Removing PPA $ppa..."
    if ! sudo add-apt-repository --remove $ppa -y | tee -a $LOG_FILE; then
        log "Failed to remove PPA $ppa."
        return 1
    fi
    if ! sudo apt-get update | tee -a $LOG_FILE; then
        log "Failed to update package list after removing PPA $ppa."
        return 1
    fi
    return 0
}

# Function to add a PPA
add_ppa() {
    ppa=$1
    log "Adding PPA $ppa..."
    if ! sudo add-apt-repository $ppa -y | tee -a $LOG_FILE; then
        log "Failed to add PPA $ppa."
        return 1
    fi
    if ! sudo apt-get update | tee -a $LOG_FILE; then
        log "Failed to update package list after adding PPA $ppa."
        return 1
    fi
    return 0
}

# Function to check if a package is installed using dpkg
check_package_installed() {
    package=$1
    dpkg -l | grep -qw $package
    return $?
}

# Function to show the status of common packages
show_package_status() {
    echo "Common Packages Status:"
    for package in "${COMMON_PACKAGES[@]}"; do
        if check_package_installed $package; then
            echo "Package $package is installed."
        else
            echo "Package $package is not installed."
        fi
    done
}

# Function to show the status of PPAs
show_ppa_status() {
    echo "PPA Status:"
    for ppa in "${PPAS[@]}"; do
        if grep -q "^deb .*$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            echo "PPA $ppa is added."
        else
            echo "PPA $ppa is not added."
        fi
    done
}

# Function to show a menu for adding or removing PPAs
manage_ppas() {
    while true; do
        echo "Manage PPAs:"
        echo "1) Add Kisak PPA"
        echo "2) Remove Kisak PPA"
        echo "3) Add Oibaf PPA"
        echo "4) Remove Oibaf PPA"
        echo "5) Show PPA Status"
        echo "6) Back to Main Menu"
        read -p "Choose an option: " choice
        case $choice in
            1)
                add_ppa "ppa:kisak/kisak-mesa"
                ;;
            2)
                remove_ppa "ppa:kisak/kisak-mesa"
                ;;
            3)
                add_ppa "ppa:oibaf/graphics-drivers"
                ;;
            4)
                remove_ppa "ppa:oibaf/graphics-drivers"
                ;;
            5)
                show_ppa_status
                ;;
            6)
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# Function to handle package dependency issues
handle_dependencies() {
    broken_packages=$(identify_broken_packages)
    if [ -z "$broken_packages" ]; then
        log "No broken packages found."
        return
    fi

    log "Broken packages found: $broken_packages"
    for package in $broken_packages; do
        log "Processing package $package..."

        for attempt in $(seq 1 $RETRY_LIMIT); do
            if retry_fix $package $attempt; then
                break
            fi
        done

        if dpkg -l | grep -E "^iU" | grep -q $package; then
            log "Could not fix $package after $RETRY_LIMIT attempts. Manual intervention may be required."

            # Ask user if they want to remove the PPA
            ppa=$(grep -l $package /etc/apt/sources.list.d/*.list | head -n 1)
            if [ ! -z "$ppa" ]; then
                echo "Package $package is associated with PPA $ppa"
                read -p "Do you want to remove the PPA $ppa? (y/n): " response
                if [ "$response" == "y" ]; then
                    if remove_ppa $ppa; then
                        handle_dependencies
                    else
                        log "Failed to remove PPA $ppa. Manual intervention may be required."
                    fi
                fi
            fi
        fi
    done
}

# Function to provide a summary of actions taken
summary() {
    echo "Summary of actions taken:"
    grep -i "fixing broken dependencies" $LOG_FILE
    grep -i "reconfiguring packages" $LOG_FILE
    grep -i "removing package" $LOG_FILE
    grep -i "reinstalling package" $LOG_FILE
    grep -i "cleaning package cache" $LOG_FILE
    grep -i "updating package list" $LOG_FILE
    grep -i "upgrading packages" $LOG_FILE
    grep -i "removing ppa" $LOG_FILE
}

# Function to provide user guidance
user_guidance() {
    echo "User Guidance:"
    echo "If you encounter persistent issues, consider the following steps:"
    echo "1. Check the logs in $LOG_FILE for detailed error messages."
    echo "2. Ensure your network connection is stable for downloading packages."
    echo "3. Try manually removing and reinstalling problematic packages using dpkg."
    echo "4. If a specific PPA is causing issues, consider removing it and then re-adding it if necessary."
    echo "5. For further assistance, refer to Ubuntu forums or support channels."
}

# Main menu
main_menu() {
    while true; do
        echo "Dependency Fix Menu:"
        echo "1) Show Common Package Status"
        echo "2) Manage PPAs"
        echo "3) Fix Broken Dependencies"
        echo "4) Clean Package Cache"
        echo "5) Update and Upgrade Packages"
        echo "6) Show Summary"
        echo "7) User Guidance"
        echo "8) Exit"
        read -p "Choose an option: " choice
        case $choice in
            1)
                show_package_status
                ;;
            2)
                manage_ppas
                ;;
            3)
                handle_dependencies
                ;;
            4)
                clean_package_cache
                ;;
            5)
                update_and_upgrade
                ;;
            6)
                summary
                ;;
            7)
                user_guidance
                ;;
            8)
                exit 0
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# Start the script
log "Starting dependency resolution process..."
main_menu
