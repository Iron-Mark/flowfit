# Requirements Document

## Introduction

This feature enhances the Galaxy Watch application to collect accelerometer data for AI-powered activity classification and improves the watch UI/UX to meet WCAG accessibility standards with a cohesive blue color scheme. The watch will collect real sensor data (accelerometer + heart rate) and transmit it to the phone for AI inference, while providing users with a professional, accessible interface.

## Glossary

- **Watch Application**: The Flutter application running on the Galaxy Watch device
- **Phone Application**: The Flutter application running on the connected Android phone
- **Sensor Batch**: A collection of 32 accelerometer samples collected over approximately 1 second at 32Hz
- **AI Model**: The TensorFlow Lite model that classifies activities based on 4 features (accX, accY, accZ, BPM)
- **WCAG**: Web Content Accessibility Guidelines - standards for accessible digital content
- **Sensor Fusion**: Combining multiple sensor inputs (accelerometer + heart rate) for enhanced data analysis
- **Watch Bridge**: The communication channel between watch and phone using Android Wear MessageClient

## Requirements

### Requirement 1

**User Story:** As a watch wearer, I want the watch to collect my movement data using the accelerometer, so that the AI model can accurately classify my activities based on real wearable sensor data.

#### Acceptance Criteria

1. WHEN the user starts activity tracking THEN the Watch Application SHALL begin collecting accelerometer data at 32Hz sampling rate
2. WHEN accelerometer data is collected THEN the Watch Application SHALL buffer 32 samples before transmission
3. WHEN 32 samples are buffered AND at least 1 second has elapsed since last transmission THEN the Watch Application SHALL send the batch to the Phone Application
4. WHEN the user stops activity tracking THEN the Watch Application SHALL stop collecting accelerometer data and unregister sensor listeners
5. WHERE the accelerometer sensor is unavailable THEN the Watch Application SHALL display an error message to the user

### Requirement 2

**User Story:** As a developer, I want the watch to send combined sensor data packets to the phone, so that the AI model receives properly formatted input with all required features.

#### Acceptance Criteria

1. WHEN a sensor batch is ready for transmission THEN the Watch Application SHALL create a JSON packet containing accelerometer samples, current heart rate, timestamp, and sample count
2. WHEN creating the JSON packet THEN the Watch Application SHALL format accelerometer data as an array of [accX, accY, accZ] triplets
3. WHEN transmitting data THEN the Watch Application SHALL send the packet via the Watch Bridge using the "/sensor_data" message path
4. WHEN the Phone Application receives a sensor batch THEN the Phone Application SHALL parse the JSON and extract all sensor values
5. WHEN sensor data is extracted THEN the Phone Application SHALL combine each accelerometer sample with the heart rate value to create 4-feature input vectors for the AI Model

### Requirement 3

**User Story:** As a watch wearer, I want the watch UI to follow accessibility best practices, so that I can easily read and interact with the interface regardless of lighting conditions or visual abilities.

#### Acceptance Criteria

1. WHEN displaying text THEN the Watch Application SHALL use font sizes of at least 14sp for body text and 18sp for headings
2. WHEN displaying text on colored backgrounds THEN the Watch Application SHALL maintain a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text
3. WHEN displaying interactive elements THEN the Watch Application SHALL provide touch targets of at least 48x48 density-independent pixels
4. WHEN showing status information THEN the Watch Application SHALL use both color and icons to convey meaning
5. WHEN animations occur THEN the Watch Application SHALL limit animation duration to under 300ms to avoid motion sickness

### Requirement 4

**User Story:** As a watch wearer, I want a cohesive blue color scheme throughout the watch interface, so that the app has a professional and calming appearance.

#### Acceptance Criteria

1. WHEN the Watch Application displays any screen THEN the Watch Application SHALL use a primary blue color (#2196F3) for main interactive elements
2. WHEN displaying active states THEN the Watch Application SHALL use a darker blue (#1976D2) for pressed or selected states
3. WHEN displaying inactive or disabled states THEN the Watch Application SHALL use a light blue-grey (#90CAF9) with 60% opacity
4. WHEN showing success states THEN the Watch Application SHALL use a teal accent color (#00BCD4)
5. WHEN showing error states THEN the Watch Application SHALL use a red accent color (#F44336) that maintains sufficient contrast with backgrounds

### Requirement 5

**User Story:** As a watch wearer, I want to see real-time feedback about sensor collection status, so that I know the watch is actively collecting data for activity classification.

#### Acceptance Criteria

1. WHEN heart rate tracking is active THEN the Watch Application SHALL display a red heart icon with the current BPM value
2. WHEN accelerometer tracking is active THEN the Watch Application SHALL display a blue motion sensor icon with "Active" status text
3. WHEN either sensor is inactive THEN the Watch Application SHALL display the corresponding icon in grey with "Off" status text
4. WHEN sensor data is being transmitted THEN the Watch Application SHALL briefly animate the motion sensor icon
5. WHEN a sensor error occurs THEN the Watch Application SHALL display an error indicator with descriptive text

### Requirement 6

**User Story:** As a developer, I want the watch sensor service to integrate seamlessly with existing heart rate tracking, so that both sensors work together without conflicts or resource issues.

#### Acceptance Criteria

1. WHEN heart rate tracking starts THEN the Watch Application SHALL also start accelerometer tracking
2. WHEN heart rate tracking stops THEN the Watch Application SHALL also stop accelerometer tracking
3. WHEN a new heart rate value is received THEN the Watch Application SHALL update the sensor service with the latest BPM value
4. WHEN both sensors are active THEN the Watch Application SHALL maintain battery-efficient sampling rates
5. IF either sensor fails to initialize THEN the Watch Application SHALL continue operating with the available sensor and notify the user

### Requirement 7

**User Story:** As a watch wearer, I want proper Android permissions for sensor access, so that the watch can legally and securely access accelerometer and heart rate data.

#### Acceptance Criteria

1. WHEN the Watch Application is installed THEN the Watch Application SHALL declare BODY_SENSORS permission in the manifest
2. WHEN the Watch Application is installed THEN the Watch Application SHALL declare ACTIVITY_RECOGNITION permission in the manifest
3. WHEN the Watch Application starts THEN the Watch Application SHALL request runtime permissions if not already granted
4. WHEN permissions are denied THEN the Watch Application SHALL display a permission rationale screen explaining why sensors are needed
5. WHEN permissions are granted THEN the Watch Application SHALL proceed to sensor initialization

### Requirement 8

**User Story:** As a developer, I want clear visual indicators during development and testing, so that I can verify sensor data is being collected and transmitted correctly.

#### Acceptance Criteria

1. WHEN running in debug mode THEN the Watch Application SHALL log sensor collection events with timestamps
2. WHEN a sensor batch is transmitted THEN the Watch Application SHALL log the batch size and transmission status
3. WHEN the Phone Application receives sensor data THEN the Phone Application SHALL log the received sample count and heart rate
4. WHEN sensor errors occur THEN the Watch Application SHALL log detailed error information
5. WHEN testing THEN the Watch Application SHALL provide a test mode that displays raw sensor values on screen
