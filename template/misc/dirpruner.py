#!/usr/bin/env python3

"""
USAGE: ./pbin/dirpruner.py data
"""


import os
import sys
from functools import reduce
from typing import List, Callable
import argparse


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


def prune_directory(directory: str, dryrun: bool = False) -> bool:
    """Remove .gitkeep file and its containing directory if it should be pruned. If dryrun, only print and do not delete."""
    if not should_prune(directory):
        return False

    if dryrun:
        print(f"[DRYRUN] Would prune: {directory}")
        return True

    gitkeep_path = os.path.join(directory, '.gitkeep')
    return remove_file(gitkeep_path) and remove_directory(directory)


def get_all_subdirectories(base_dir: str) -> List[str]:
    """Recursively get all subdirectories in a directory."""
    if not is_directory(base_dir):
        return []

    # Get immediate subdirectories as a list (not a filter object)
    subdirs = [item for item in list_directory_contents(base_dir) if is_directory(item)]

    # Recursively get all subdirectories
    all_subdirs = list(subdirs)
    for subdir in subdirs:
        all_subdirs.extend(get_all_subdirectories(subdir))

    return all_subdirs


def prune_directories(directories: List[str], dryrun: bool = False) -> List[str]:
    """Prune all eligible subdirectories and return a list of pruned directories. If dryrun, only print."""
    all_subdirs = reduce(
        lambda acc, dir: acc + get_all_subdirectories(dir),
        directories,
        []
    )
    all_subdirs.sort(key=lambda x: x.count(os.sep), reverse=True)
    pruned = filter(
        lambda subdir: prune_directory(subdir, dryrun=dryrun),
        all_subdirs
    )
    return list(pruned)


def parse_args():
    """Parse command line arguments for initial directory, multiple directories, and dryrun flag."""
    parser = argparse.ArgumentParser(description="Prune empty directories containing only .gitkeep files.")
    parser.add_argument('-d', '--directory', nargs='?', default=os.getcwd(),
                        help='Path of the initial directory to scan (default: current directory)')
    parser.add_argument('-D', '--directories', nargs='+',
                        help='One or more top-level directories to scan')
    parser.add_argument('-n', '--dryrun', action='store_true',
                        help='Only print directories that would be pruned, do not delete')
    return parser.parse_args()


def main():
    """Main function to coordinate the directory pruning."""
    args = parse_args()
    dryrun = args.dryrun
    if args.directories:
        directories = args.directories
    else:
        directories = [args.directory]
    print("Starting directory pruning..." + (" (dryrun mode)" if dryrun else ""))
    print(f"Scanning directories: {', '.join(directories)}")
    pruned_dirs = prune_directories(directories, dryrun=dryrun)
    if dryrun:
        print(f"[DRYRUN] {len(pruned_dirs)} directories would be pruned:")
    else:
        print(f"Pruned {len(pruned_dirs)} directories containing only .gitkeep files:")
    for dir in pruned_dirs:
        print(f"  - {dir}")
    print("Directory pruning completed." + (" (dryrun mode)" if dryrun else ""))


if __name__ == "__main__":
    main()
