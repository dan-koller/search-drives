#!/bin/bash

#############################################
# This script searches for files and/or paths
# on macOS and Linux. Select a volume or a
# path and specify the file or pattern to
# search for. For forensic purposes only. Use
# at your own risk.
#
# Author: Dan Koller
# Date: 07.01.2024
# Version: 1.0
# License: MIT
#############################################

#############################################
# Miscelaneous variables for colors and
# formatting
#############################################

RED="\033[31m"       # Errors
YELLOW="\033[33m"    # Warnings
GREEN="\033[32m"     # Success
ENDCOLOR="\033[0m"   # Reset
NEWLINE="\n"         # New line

#############################################
# Global variables
#############################################

OPERATING_SYSTEM=$(uname -s)
DEFAULT_DRIVE_PATH_MAC="/System/Volumes/Data"
DEFAULT_DRIVE_PATH_LINUX="/"
DEFAULT_SEARCH_PATH=$(echo $HOME)

#############################################
# Main menu and prerequisites
#############################################

# Create a basic main menu
function main_menu() {
    check_sudo
    check_compatibilty
    clear
    echo "Search $OPERATING_SYSTEM"
    echo "---------"
    echo Select an option:
    echo "1) Search a volume"
    echo "2) Search a path"
    echo "3) Exit"
    read main_menu_option
    case $main_menu_option in
        1) select_volume ;;
        2) select_path ;;
        3) exit ;;
        *) echo "Invalid option" ; echo ; main_menu ;;
    esac
}

function check_sudo() {
    # If the user is not root, print a message saying that not all path may be accessible
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Not running as root, some paths may be inaccessible.${ENDCOLOR}"
        read -p "Press enter to continue..."
    fi
}

function check_compatibilty() {
    if [[ ! "$BASH_VERSION" ]]; then
        echo -e "${RED}Error: This script is only compatible with bash.${ENDCOLOR}"
        exit 1
    fi
}

#############################################
# Select volume section
#############################################

function select_volume() {
    echo -e "Available volumes:${NEWLINE}"
    
    # Use the list_mounted_drives function to get volumes
    volumes=$(list_mounted_drives)

    # Create an array to store volumes
    volumes_array=()

    # Print the volumes as a list like: Index | Mounting point | Volume path
    echo "Index | Mounting point                         | Volume path"
    echo "-----------------------------------------------------------------------------"
    i=1
    while read -r line; do
        drive_path=$(echo "$line" | awk -F ' | ' '{print $1}')
        volume_info=$(echo "$line" | awk -F ' | ' '{$1=""; print $0}')
        printf "%-6s| %-37s %s\n" "$i)" "$drive_path" "$volume_info"
        volumes_array[$i]=$volume_info
        ((i++))
    done <<< "$volumes"

    # Read the user input
    if [[ $OPERATING_SYSTEM == "Linux" ]]; then
        read -p "Select a volume by index or press enter to use the default volume ($DEFAULT_DRIVE_PATH_LINUX): " selected_volume_index
    else
        read -p "Select a volume by index or press enter to use the default volume ($DEFAULT_DRIVE_PATH_MAC): " selected_volume_index
    fi

    # If the user didn't select a volume, use the default volume
    if [[ -z $selected_volume_index ]]; then
        # Use the default volume
        volume_path=$DEFAULT_DRIVE_PATH_MAC
        if [[ $OPERATING_SYSTEM == "Linux" ]]; then
            volume_path=$DEFAULT_DRIVE_PATH_LINUX
        fi
    else
        while [[ ! $selected_volume_index =~ ^[0-9]+$ ]] || [[ $selected_volume_index -lt 1 ]] || [[ $selected_volume_index -gt $i ]]; do
            echo -e "${RED}Error: Invalid volume index.${ENDCOLOR}"
            if [[ $OPERATING_SYSTEM == "Linux" ]]; then
                read -p "Select a volume by index or press enter to use the default volume ($DEFAULT_DRIVE_PATH_LINUX): " selected_volume_index
            else
                read -p "Select a volume by index or press enter to use the default volume ($DEFAULT_DRIVE_PATH_MAC): " selected_volume_index
            fi
        done
        # Remove the first two characters from the volume path
        volume_path=${volumes_array[$selected_volume_index]:3}
    fi

    # Search the volume
    search "$volume_path"
}

# The list_mounted_drives function remains the same
function list_mounted_drives() {
  df -h | awk 'NR>1 {print $1 " | " $NF}'
}

#############################################
# Select path section
#############################################

# Search a path
function select_path() {
    while true; do
        read -p "Enter a path to search or press enter to use the default path ($DEFAULT_SEARCH_PATH): " search_path
        if [[ -z $search_path ]]; then
            search_path=$DEFAULT_SEARCH_PATH
        fi

        # Check if the path exists
        if check_path "$search_path"; then
            break  # Break out of the loop if the path is valid
        else
            echo -e "${RED}Error: The path does not exist.${ENDCOLOR}"
        fi
    done

    # Search the path
    search "$search_path"
}

function check_path() {
    local path_to_check=$1
    # Check if the path exists
    [[ -e $path_to_check ]]
}

#############################################
# Common search functions
#############################################

function search() {
    search_path=$1
    
    # Read the search pattern
    read -p "Enter the search pattern (e.g., image.jpg, *.txt, enter for all files): " search_pattern

    # Search all files if the user didn't enter a search pattern
    if [[ -z $search_pattern ]]; then
        search_pattern="*"
    fi

    filename="search_results-$(date +%Y%m%d%H%M%S).txt"

    # Search the volume
    echo -e "${NEWLINE}Searching for $search_pattern in $search_path...${NEWLINE}"

    # Build the find command
    find_command="find \"$search_path\""

    # Split every search term into a token. The delimiter is an empty space
    IFS=' ' read -r -a search_pattern <<< "$search_pattern"

    # Use build the find command by adding '-name <term> -o' for each term
    for term in "${search_pattern[@]}"; do
        find_command+=" -name \"$term\" -o"
    done
    # Remove the last '-o'
    find_command=${find_command%-*}

    # Execute the find command and save results to the file
    echo -e "Executing: $find_command${NEWLINE}"
    eval "$find_command" > "$filename"

    # Count the number of results
    results_count=$(wc -l < "$filename")

    echo -e "${NEWLINE}Search complete. $results_count results found.${NEWLINE}"
    echo -e "Results saved to $filename${NEWLINE}"

    # Ask the user if they want to copy the results to a path if results were found
    if [[ $results_count -gt 0 ]]; then
        copy_results_to_path
    fi
}

#############################################
# Common utility functions
#############################################

function copy_results_to_path() {
    read -p "Do you want to copy the results to a path? (y/n): " copy_results_to_path_option
    case $copy_results_to_path_option in
        y|Y) ;; # continue
        n|N) exit ;; # exit
        *) echo -e "${RED}Error: Invalid option.${ENDCOLOR}" ; copy_results_to_path ;;
    esac

    # Ask the user for the path
    read -p "Enter the path to copy the results to: " copy_results_to_path

    # Check if the path exists
    if check_path "$copy_results_to_path"; then
        # Copy every file in the results file to the path
        while read -r line; do
            cp "$line" "$copy_results_to_path"
        done < "$filename"
        echo -e "${GREEN}Results copied to $copy_results_to_path.${ENDCOLOR}"
    else
        echo -e "${RED}Error: The path does not exist.${ENDCOLOR}"
        copy_results_to_path
    fi
}

#############################################
# Program entry point
#############################################
main_menu
