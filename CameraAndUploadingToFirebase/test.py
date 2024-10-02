import os
import cv2
import time
from ultralytics import YOLO
from flask import Flask, Response, render_template_string

# Load YOLOv8 model for violence detection
yolo_model = YOLO('violence_weights.pt')

# Initialize Flask app
app = Flask(__name__)

# Define folders for saving frames and trigger file
output_folder = 'processed_frames'
os.makedirs(output_folder, exist_ok=True)

trigger_file_path = 'trigger_fb.txt'  # Trigger file to signal fb.py execution

# Replace with your video stream URL or video file path
stream_url = 0  # Use 0 for the default camera or replace with a live stream URL
cap = cv2.VideoCapture(stream_url)

# Check if the stream is opened successfully
if not cap.isOpened():
    print(f"Error: Could not open the video stream from {stream_url}")
    exit()

frame_idx = 0  # Frame index for saving frames
desired_width = 640
desired_height = 480

@app.route('/')
def index():
    return render_template_string('''<img src="/video_feed" width="720">''')

def generate_frames():
    global frame_idx
    last_saved_time = time.time()  # Initialize time for saving frames
    while True:
        start_time = time.time()  # Start time for FPS control
        ret, frame = cap.read()
        
        if not ret:
            print("Error: Failed to capture video frame.")
            break
        
        # Resize the frame to the desired size
        frame = cv2.resize(frame, (desired_width, desired_height))

        # Perform detection using YOLOv8 model
        results = yolo_model(frame)

        # Get boxes and their associated probabilities
        boxes = results[0].boxes
        if boxes is not None:
            # Extract class IDs and scores
            class_ids = boxes.cls
            scores = boxes.conf

            # Initialize violence probability
            violence_prob = 0.0

            # Check if any detections exist
            if len(class_ids) > 0:
                # Get the highest probability of violence detection
                for class_id, score in zip(class_ids, scores):
                    if class_id == 1:  # Class ID for violence
                        violence_prob = max(violence_prob, score.item() * 100)  # Convert to percentage
                        print("Detected violence with probability:", violence_prob)
            else:
                print("No detections made.")
        else:
            print("No detection boxes found.")

        # Save the original frame (without bounding boxes) with violence percentage in the filename
        current_time = time.strftime("%Y-%m-%d_%H-%M-%S")
        
        # Check if one second has passed to save the frame
        if time.time() - last_saved_time >= 1:  # Save every second
            frame_filename = os.path.join(output_folder, f'frame_{current_time}_violence_{violence_prob:.2f}.png')
            cv2.imwrite(frame_filename, frame)  # Save the unannotated frame
            
            # Create the trigger file only once when the first frame is captured with violence
            if violence_prob > 0 and not os.path.exists(trigger_file_path):
                with open(trigger_file_path, 'w') as f:
                    f.write("Trigger fb.py execution")  # Write something to the file

            last_saved_time = time.time()  # Update the last saved time

        # Convert the annotated frame (with bounding boxes) to JPEG format for live stream
        annotated_frame = results[0].plot()  # This will add the bounding boxes
        _, buffer = cv2.imencode('.jpg', annotated_frame)
        frame = buffer.tobytes()
        
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
        
        frame_idx += 1
        
        # Calculate elapsed time and adjust for FPS
        elapsed_time = time.time() - start_time
        time_to_wait = (1 / 60) - elapsed_time  # 60 FPS
        if time_to_wait > 0:
            time.sleep(time_to_wait)  # Wait for the remaining time to achieve the desired FPS

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(),
                    mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    try:
        app.run(host='0.0.0.0', port=5000, debug=True)  # Change host and port as needed
    finally:
        cap.release()  # Release the stream capture
