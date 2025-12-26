import shutil
import os
from datetime import datetime

def zip_folder(source_folder, output_path):
    """
    Compresses the source folder into a zip file and saves it to output_path.
    
    Args:
        source_folder (str): Path to the folder to zip
        output_path (str): Directory where the zip file will be saved
    """
    if not os.path.exists(source_folder):
        print(f"Error: Source folder '{source_folder}' does not exist!")
        return False
    
    # Create timestamped filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    folder_name = os.path.basename(source_folder)
    zip_filename = f"{folder_name}_{timestamp}.zip"
    zip_fullpath = os.path.join(output_path, zip_filename)
    
    try:
        # Ensure output directory exists
        os.makedirs(output_path, exist_ok=True)
        
        # Create zip archive
        shutil.make_archive(zip_fullpath[:-4], 'zip', source_folder)
        print(f"✅ Folder '{source_folder}' successfully zipped to '{zip_fullpath}'")
        print(f"📁 Zip file size: {os.path.getsize(zip_fullpath):,} bytes")
        return True
        
    except Exception as e:
        print(f"❌ Error creating zip: {str(e)}")
        return False

# === CONFIGURATION - SET YOUR PATHS HERE ===
SOURCE_FOLDER_PATH = r"F:\WALLD_Flutter\walld_flutter\build\windows\x64\runner\Release"  # Folder to compress (CHANGE THIS)
OUTPUT_ZIP_PATH = r"F:\WALLD_Flutter\walld_flutter"       # Where to save the zip (CHANGE THIS)

# Run the zipping process
if __name__ == "__main__":
    print("🚀 Folder Zipper Tool")
    print("=" * 40)
    
    success = zip_folder(SOURCE_FOLDER_PATH, OUTPUT_ZIP_PATH)
    
    if success:
        print("\n✅ Process completed successfully!")
    else:
        print("\n❌ Process failed!")
