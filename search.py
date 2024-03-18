#############################################
# This script searches for files and/or paths
# on any system using Python. Select a volume
# or a path and specify the file or pattern
# to search for.
#
# Author: Dan Koller
# Date: 14.03.2024
# Version: 1.0
# License: MIT
#############################################

import os
import shutil
from datetime import datetime
import fnmatch
import platform
import psutil

def main():
    # Main menu loop
    timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M-%S")
    results_file = f"results-{timestamp}.txt"
    
    while True:
        print("Select an option:")
        print("1. Search for a drive")
        print("2. Search for a path")
        print("3. Exit")
        option = input("Enter an option: ")

        if option == "1":
            selected_drive = select_drive()
            if selected_drive:
                search(selected_drive, results_file)
                copy_option(results_file)
        elif option == "2":
            selected_path = select_path()
            if selected_path:
                search(selected_path, results_file)
                copy_option(results_file)
        elif option == "3":
            break
        else:
            print("Invalid option. Please select a valid option.")

def select_path():
    # Prompt the user to enter a path
    while True:
        selected_path = input("Enter the path: ")
        if os.path.isdir(selected_path):
            print(f"Selected path: {selected_path}")
            return selected_path
        else:
            print("Invalid path. Please provide a valid path like C:\\Users\\ or D:\\.")

def select_drive():
    # Get all connected drives and their labels on Windows
    if platform.system() == 'Windows':
        print("Listing Available Drives:")
        print("-------------------------")
        drives = [drive.strip() for drive in os.popen("wmic logicaldisk get caption").read().split()[1:]]
        print("\n".join(drives))

        while True:
            selected_drive = input("Enter a drive letter (e.g., C:, D:, E:) or press enter to set a path: ").upper()
            if selected_drive in drives or os.path.isdir(selected_drive):
                print(f"Selected drive: {selected_drive}")
                return selected_drive
            else:
                print("Invalid drive letter or path. Please select a valid drive like C:, D:, E: or provide a valid path.")
    # Get volumes on Unix-like systems
    else:
        print("Listing Available Volumes:")
        print("--------------------------")
        volumes = [volume.mountpoint for volume in psutil.disk_partitions()]
        print("\n".join(volumes))
        while True:
            selected_volume = input("Enter a volume (e.g., /, /home, /mnt/data) or press enter to set a path: ")
            if selected_volume in volumes or os.path.isdir(selected_volume):
                print(f"Selected volume: {selected_volume}")
                return selected_volume
            else:
                print("Invalid volume or path. Please select a valid volume or provide a valid path.")

def search(target, results_file):
    # Search for files in the selected drive or path
    search_terms_input = input("Enter the search pattern (e.g., image.jpg, *.txt, enter for all files): ").strip()
    search_terms = search_terms_input.split()
    if not search_terms:
        search_terms = ["*"]

    print(f"Searching for: {', '.join(search_terms)}")
    with open(results_file, "w") as f:
        for root, _, files in os.walk(target):
            for file in files:
                for term in search_terms:
                    if fnmatch.fnmatch(file, term):
                        result_path = os.path.join(root, file)
                        f.write(result_path + "\n")

    count = sum(1 for _ in open(results_file))
    print(f"Found {count} results in {target}.")
    os.startfile(results_file)

def copy_option(results_file):
    # Ask the user if they want to copy the results to another location
    if os.path.getsize(results_file) == 0:
        return

    copy_results = input("Do you want to copy the results to a folder? (Y/N): ").upper()
    if copy_results == "Y":
        copy_results_to_folder(results_file)
    elif copy_results == "N":
        pass
    else:
        print("Invalid input. Please enter Y or N.")

def copy_results_to_folder(results_file):
    # Copy the results to another location
    while True:
        copy_path = input("Enter the path to copy the results to: ")
        if os.path.isdir(copy_path):
            with open(results_file) as f:
                for line in f:
                    src_file = line.strip()
                    dest_file = os.path.join(copy_path, os.path.basename(src_file))
                    if os.path.exists(dest_file):
                        overwrite = input(f"File {os.path.basename(src_file)} already exists. Overwrite? (Y/N): ").upper()
                        if overwrite != "Y":
                            continue
                    try:
                        shutil.copy(src_file, copy_path)
                    except Exception as e:
                        print(f"Error copying file: {e}")
                    else:
                        print(f"File {os.path.basename(src_file)} copied to {copy_path}.")
            break
        else:
            print("Invalid path. Please provide a valid path like C:\\Users\\ or D:\\.")

if __name__ == "__main__":
    main()
