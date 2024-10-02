import os
import time
import firebase_admin
from firebase_admin import credentials, storage

# Initialize Firebase Admin SDK
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred, {
    'storageBucket': 'genai-gp.appspot.com'
})

# Get reference to Firebase storage bucket
bucket = storage.bucket()

# Folder containing the pictures
folder_path = 'processed_frames'

# Track uploaded files to avoid duplicate uploads
uploaded_files = set()

def upload_to_firebase(file_path):
    try:
        # Create a blob (Firebase object reference)
        blob = bucket.blob(f'frames/{os.path.basename(file_path)}')
        
        # Upload the file to Firebase Storage
        blob.upload_from_filename(file_path)
        print(f"Uploaded: {file_path}")
    except Exception as e:
        print(f"Error uploading {file_path}: {e}")

def monitor_folder():
    while True:
        # Get the list of files in the folder
        files = os.listdir(folder_path)
        
        # Sort the files by modification time (latest first)
        files = sorted(files, key=lambda x: os.path.getmtime(os.path.join(folder_path, x)), reverse=True)
        
        for file_name in files:
            # Get the full path of the file
            file_path = os.path.join(folder_path, file_name)
            
            # Check if the file is new and not already uploaded
            if file_name not in uploaded_files:
                upload_to_firebase(file_path)
                uploaded_files.add(file_name)
        
        # Wait for 1 second before checking again
        time.sleep(1)

if __name__ == "__main__":
    monitor_folder()