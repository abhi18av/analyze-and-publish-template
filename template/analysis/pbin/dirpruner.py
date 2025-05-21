#!/usr/bin/env python3

"""
USAGE: ./pbin/dirpruner.py data
"""


import os
import sys
from functools import reduce
from typing import List, Callable


def list_directory_contents(directory: str) -> List[str]:
    """Return full paths of all files and directories in the given directory."""
    try:
        return [os.path.join(directory, item) for item in os.listdir(directory)]
    except (PermissionError, FileNotFoundError):
        return []


def is_directory(path: str) -> bool:
    """Check if a path points to a directory."""
    return os.path.isdir(path)


def should_prune(directory: str) -> bool:
    """Check if a directory contains only a .gitkeep file."""
    contents = list_directory_contents(directory)
    return (len(contents) == 1 and
            os.path.isfile(contents[0]) and
            os.path.basename(contents[0]) == '.gitkeep')


def remove_file(file_path: str) -> bool:
    """Remove a file and return True if successful."""
    try:
        os.remove(file_path)
        return True
    except (PermissionError, FileNotFoundError):
        return False


def remove_directory(directory: str) -> bool:
    """Remove a directory and return True if successful."""
    try:
        os.rmdir(directory)
        return True
    except (PermissionError, FileNotFoundError):
        return False


def prune_directory(directory: str) -> bool:
    """Remove .gitkeep file and its containing directory if it should be pruned."""
    if not should_prune(directory):
        return False

    gitkeep_path = os.path.join(directory, '.gitkeep')
    return remove_file(gitkeep_path) and remove_directory(directory)


def get_all_subdirectories(base_dir: str) -> List[str]:
    """Recursively get all subdirectories in a directory."""
    if not is_directory(base_dir):
        return []

    # Get immediate subdirectories
    subdirs = filter(is_directory, list_directory_contents(base_dir))

    # Recursively get all subdirectories
    all_subdirs = list(subdirs)
    for subdir in subdirs:
        all_subdirs.extend(get_all_subdirectories(subdir))

    return all_subdirs


def prune_directories(directories: List[str]) -> List[str]:
    """Prune all eligible subdirectories and return a list of pruned directories."""
    # Get all subdirectories for all input directories
    all_subdirs = reduce(
        lambda acc, dir: acc + get_all_subdirectories(dir),
        directories,
        []
    )

    # Sort by depth (longest path first) to handle nested directories properly
    all_subdirs.sort(key=lambda x: x.count(os.sep), reverse=True)

    # Prune eligible directories and collect results
    pruned = filter(
        lambda subdir: prune_directory(subdir),
        all_subdirs
    )

    return list(pruned)


def parse_directories() -> List[str]:
    """Parse directories from command line or use defaults."""
    # Default directories if none provided
    default_dirs = [os.getcwd()]

    # Check if directories were provided as command line arguments
    if len(sys.argv) > 1:
        dirs = sys.argv[1].split(',')
        return [dir.strip() for dir in dirs if dir.strip()]

    return default_dirs


def main():
    """Main function to coordinate the directory pruning."""
    print("Starting directory pruning...")

    # Get directories to scan
    directories = parse_directories()
    print(f"Scanning directories: {', '.join(directories)}")

    # Prune directories and collect results
    pruned_dirs = prune_directories(directories)

    # Report results
    print(f"Pruned {len(pruned_dirs)} directories containing only .gitkeep files:")
    for dir in pruned_dirs:
        print(f"  - {dir}")

    print("Directory pruning completed.")


if __name__ == "__main__":
    main()
