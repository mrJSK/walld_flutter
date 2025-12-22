#!/usr/bin/env python3
import os
from pathlib import Path

# ============================================================================
# CONFIGURATION - Edit these values as needed
# ============================================================================

# Output file path where all content will be saved
OUTPUT_FILE = "combined_code.txt"

# Set to True to include a visual file tree at the top of the output file
INCLUDE_FILE_STRUCTURE = True

# Files and folders to process -----------------------------------------------

# Folders to scan FULLY RECURSIVELY (includes all subfolders and all files)
# Each file's path will be shown relative to the folder's parent
FULLY_RECURSIVE_FOLDERS = [
   "lib/dynamic_screen",
]

# Folders to scan NON-RECURSIVELY (only files directly in these folders)
# Each file's path will be shown as absolute path
NON_RECURSIVE_FOLDERS = [
]

# Specific individual files to include (full file paths)
# Use forward slashes / or raw strings r"..."
# INCLUDE_FILES = [
#     "pubspec.yaml",
#     "lib/firebase_options.dart",
#     "firebase.json",
#     "windows/runner/CMakeLists.txt",
#     "windows/flutter/CMakeLists.txt",
#     "windows/runner/main.cpp",
#     "windows/runner/flutter_window.cpp",
#     "windows/runner/flutter_window.h",
#     "windows/runner/win32_window.cpp",
#     "windows/runner/utils.cpp",
#     "windows/runner/utils.h",
# ]
INCLUDE_FILES = []
# File filtering --------------------------------------------------------------
 
# File extensions to include (empty list = include ALL files)
# Examples: ['.dart', '.java', '.cpp', '.h', '.py']
INCLUDE_EXTENSIONS = ['.dart', '.yaml', '.json', '.cpp', '.h', '.txt']

# Directory names to exclude from scanning (only applies to recursive mode)
EXCLUDE_DIRS = ['.git', 'node_modules', 'websocketpp-master', 'build', 'bin', 'obj', 'dist', '__pycache__', 'venv', '.vscode', '.idea', '.exe', 'WebSocket']

# ============================================================================
# SCRIPT LOGIC - No need to edit below this line
# ============================================================================

def get_comment_prefix(file_ext):
    """Return comment prefix based on file extension."""
    ext = file_ext.lower()
    if ext in {'.cpp', '.c', '.cc', '.cxx', '.h', '.hpp', '.hxx', '.java', '.cs', '.dart'}:
        return "//"
    if ext in {'.py', '.sh', '.bash', '.yaml', '.yml', '.ini', '.cfg', '.conf'}:
        return "#"
    if ext in {'.js', '.ts', '.jsx', '.tsx', '.php'}:
        return "//"
    if ext in {'.css', '.scss', '.sass'}:
        return "/*"
    if ext in {'.html', '.xml', '.svg'}:
        return "<!--"
    if ext in {'.md', '.txt', '.rst'}:
        return "#"
    return "#"  # default

def generate_tree(dir_path, prefix=""):
    """Generates a string representation of the file structure."""
    tree_str = ""
    path_obj = Path(dir_path)
    
    if not path_obj.exists():
        return f"{prefix}[Dir Not Found: {dir_path}]\n"

    # Get all items in directory
    try:
        items = list(path_obj.iterdir())
    except PermissionError:
        return f"{prefix}[Permission Denied]\n"

    # Sort items: directories first, then files
    items.sort(key=lambda x: (not x.is_dir(), x.name.lower()))
    
    # Filter out excluded directories
    items = [i for i in items if i.name not in EXCLUDE_DIRS]

    count = len(items)
    for i, item in enumerate(items):
        connector = "└── " if i == count - 1 else "├── "
        
        if item.is_dir():
            tree_str += f"{prefix}{connector}{item.name}/\n"
            extension = "    " if i == count - 1 else "│   "
            tree_str += generate_tree(item, prefix + extension)
        else:
            # Only show files if they match extensions (if filter is active)
            if not INCLUDE_EXTENSIONS or item.suffix.lower() in [e.lower() for e in INCLUDE_EXTENSIONS]:
                tree_str += f"{prefix}{connector}{item.name}\n"
                
    return tree_str

def process_file(file_path, comment_prefix, display_path, combined_lines, processed_files):
    """Process a single file and add its content to combined_lines."""
    try:
        text = file_path.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}")
        return False

    combined_lines.append(f"{comment_prefix} File: {display_path}\n")
    combined_lines.append(text)
    if not text.endswith("\n"):
        combined_lines.append("\n")
    combined_lines.append("\n" + "=" * 80 + "\n\n")
    
    processed_files.add(file_path.resolve())
    return True

def main():
    """Main function to combine all files."""
    combined_lines = []
    file_count = 0
    processed_files = set()  # Track processed files to avoid duplicates

    print("=" * 80)
    print("COMBINING FILES INTO SINGLE DOCUMENT")
    print("=" * 80)
    print(f"Output file: {OUTPUT_FILE}")
    print(f"Extensions filter: {INCLUDE_EXTENSIONS if INCLUDE_EXTENSIONS else 'ALL FILES'}")
    print(f"Excluded directories: {EXCLUDE_DIRS}")
    print(f"Include file structure: {INCLUDE_FILE_STRUCTURE}")
    print("-" * 80)

    # 1. Generate File Structure if enabled
    if INCLUDE_FILE_STRUCTURE and FULLY_RECURSIVE_FOLDERS:
        print("\n[Generating File Structure...]")
        combined_lines.append("================================================================================\n")
        combined_lines.append("PROJECT FILE STRUCTURE\n")
        combined_lines.append("================================================================================\n\n")
        
        for folder_path in FULLY_RECURSIVE_FOLDERS:
            folder = Path(folder_path)
            if folder.exists():
                combined_lines.append(f"Root: {folder.name} ({folder_path})\n")
                combined_lines.append(generate_tree(folder))
                combined_lines.append("\n")
        
        combined_lines.append("\n" + "=" * 80 + "\n\n")

    # 2. Process FULLY RECURSIVE folders
    if FULLY_RECURSIVE_FOLDERS:
        print("\n[Processing FULLY RECURSIVE folders...]")
        for folder_path in FULLY_RECURSIVE_FOLDERS:
            folder = Path(folder_path)
            if not folder.exists():
                print(f"Warning: Folder not found: {folder_path}")
                continue

            print(f"\nScanning: {folder_path}")
            for root, dirs, files in os.walk(folder_path):
                dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
                for name in files:
                    file_path = Path(root) / name
                    abs_path = file_path.resolve()

                    if abs_path in processed_files:
                        continue
                    if INCLUDE_EXTENSIONS and file_path.suffix.lower() not in [e.lower() for e in INCLUDE_EXTENSIONS]:
                        continue

                    comment_prefix = get_comment_prefix(file_path.suffix)
                    try:
                        display_path = file_path.relative_to(folder.parent)
                    except ValueError:
                        display_path = str(file_path)

                    if process_file(file_path, comment_prefix, display_path, combined_lines, processed_files):
                        file_count += 1
                        if file_count % 25 == 0:
                            print(f"  Processed {file_count} files...")

    # 3. Process NON-RECURSIVE folders
    if NON_RECURSIVE_FOLDERS:
        print("\n[Processing NON-RECURSIVE folders...]")
        for folder_path in NON_RECURSIVE_FOLDERS:
            folder = Path(folder_path)
            if not folder.exists():
                print(f"Warning: Folder not found: {folder_path}")
                continue

            print(f"\nScanning (non-recursive): {folder_path}")
            for file_path in folder.iterdir():
                if not file_path.is_file():
                    continue

                abs_path = file_path.resolve()
                if abs_path in processed_files:
                    continue
                if INCLUDE_EXTENSIONS and file_path.suffix.lower() not in [e.lower() for e in INCLUDE_EXTENSIONS]:
                    continue

                comment_prefix = get_comment_prefix(file_path.suffix)
                display_path = str(abs_path)

                if process_file(file_path, comment_prefix, display_path, combined_lines, processed_files):
                    file_count += 1
                    if file_count % 25 == 0:
                        print(f"  Processed {file_count} files...")

    # 4. Process specific individual files
    if INCLUDE_FILES:
        print("\n[Processing specific INCLUDE_FILES...]")
        for file_path_str in INCLUDE_FILES:
            file_path = Path(file_path_str)
            if not file_path.is_file():
                print(f"Warning: File not found: {file_path_str}")
                continue

            abs_path = file_path.resolve()
            if abs_path in processed_files:
                print(f"Note: Skipping duplicate file: {file_path_str}")
                continue

            if INCLUDE_EXTENSIONS and file_path.suffix.lower() not in [e.lower() for e in INCLUDE_EXTENSIONS]:
                continue

            comment_prefix = get_comment_prefix(file_path.suffix)
            display_path = str(abs_path)

            print(f"Adding: {file_path_str}")
            if process_file(file_path, comment_prefix, display_path, combined_lines, processed_files):
                file_count += 1

    # Write output file
    print("\n" + "-" * 80)
    print(f"Writing output file: {OUTPUT_FILE}")
    Path(OUTPUT_FILE).write_text("".join(combined_lines), encoding="utf-8")
    
    print("=" * 80)
    print(f"✅ SUCCESS! Combined {file_count} files into {OUTPUT_FILE}")
    print("=" * 80)

if __name__ == "__main__":
    main()
