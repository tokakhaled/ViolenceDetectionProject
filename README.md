# ViolenceDetectionProject

## Features:
1. **Real-time Object Detection**: The YOLO model processes live stream frames from the camera, detecting and identifying objects or violent actions in real time.
2. **Video Content Captioning**: The BLIP model generates captions for each frame, providing context and descriptions of the video content.
3. **Violence Detection**: Violence percentage is calculated based on a predefined threshold, analyzing consecutive frames for consistent violent activity.
4. **Report Generation**: Reports are generated through the BART model, providing detailed summaries of the detected violence, while TF-IDF is used for efficient query analysis.
5. **Data Storage and Retrieval**: All frames, reports, and queries are stored in Firebase, allowing seamless data retrieval and real-time updates.
6. **User-Friendly Interface**: A Flutter-based UI allows users to interact with the system, view live stream analysis, query results, and generated reports.

This project provides a powerful system for detecting and analyzing violence in video streams, combining advanced machine learning models with a robust storage and interaction framework.

The Video of the project will be found in https://drive.google.com/file/d/1SSAZ-oZBoTOWnsnwi2Oryh6x2nnQ6wha/view
