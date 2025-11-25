# Implementation Plan

- [x] 1. Add Android permissions and dependencies




  - Add BODY_SENSORS and ACTIVITY_RECOGNITION permissions to AndroidManifest.xml
  - Add Wearable MessageClient dependency to build.gradle
  - Verify permissions are properly declared in manifest
  - _Requirements: 7.1, 7.2_

- [ ] 2. Create WatchSensorService for accelerometer collection
  - [ ] 2.1 Implement WatchSensorService class with SensorEventListener
    - Create WatchSensorService.kt in android/app/src/main/kotlin/com/example/flowfit/
    - Implement sensor registration at SENSOR_DELAY_GAME (~50Hz)
    - Add buffer for collecting 32 accelerometer samples
    - Add currentHeartRate property for storing latest BPM
    - Implement startTracking() and stopTracking() methods
    - _Requirements: 1.1, 1.2_

  - [ ]* 2.2 Write property test for buffer size
    - **Property 2: Buffer size before transmission**
    - **Validates: Requirements 1.2**

  - [ ] 2.3 Implement batch transmission logic
    - Create sendBatchToPhone() method
    - Get connected phone node using Wearable.getNodeClient()
    - Create JSON packet with type, timestamp, bpm, sample_rate, count, accelerometer array
    - Send via MessageClient to "/sensor_data" path
    - Clear buffer after successful transmission
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ]* 2.4 Write property test for JSON packet completeness
    - **Property 5: JSON packet completeness**
    - **Validates: Requirements 2.1**

  - [ ]* 2.5 Write property test for accelerometer data format
    - **Property 6: Accelerometer data format**
    - **Validates: Requirements 2.2**

  - [ ] 2.6 Implement transmission timing constraint
    - Add lastSendTime tracking
    - Check that at least 1000ms has elapsed before sending
    - Ensure batches are sent approximately every 1 second
    - _Requirements: 1.3_

  - [ ]* 2.7 Write property test for transmission timing
    - **Property 3: Transmission timing constraint**
    - **Validates: Requirements 1.3**

- [ ] 3. Integrate WatchSensorService with HealthTrackingManager
  - [ ] 3.1 Add WatchSensorService instance to HealthTrackingManager
    - Create WatchSensorService instance in HealthTrackingManager constructor
    - Pass context to sensor service
    - _Requirements: 6.1, 6.2_

  - [ ] 3.2 Enhance startTracking() to start accelerometer
    - Call sensorService.startTracking() after heart rate starts successfully
    - Handle accelerometer initialization errors gracefully
    - _Requirements: 6.1_

  - [ ]* 3.3 Write property test for coupled sensor start
    - **Property 19: Coupled sensor start**
    - **Validates: Requirements 6.1**

  - [ ] 3.4 Enhance stopTracking() to stop accelerometer
    - Call sensorService.stopTracking() when heart rate stops
    - Ensure both sensors are stopped together
    - _Requirements: 6.2_

  - [ ]* 3.5 Write property test for coupled sensor stop
    - **Property 20: Coupled sensor stop**
    - **Validates: Requirements 6.2**

  - [ ] 3.6 Update processDataPoint() to sync heart rate with sensor service
    - Extract heart rate value from DataPoint
    - Update sensorService.currentHeartRate with latest BPM
    - _Requirements: 6.3_

  - [ ]* 3.7 Write property test for heart rate synchronization
    - **Property 21: Heart rate synchronization**
    - **Validates: Requirements 6.3**

- [ ] 4. Checkpoint - Verify watch-side sensor collection
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Enhance PhoneDataListener to handle sensor batches
  - [ ] 5.1 Add sensor batch event channel
    - Create EventChannel for "/sensor_data" messages
    - Add SensorBatch model class in lib/models/
    - _Requirements: 2.4, 2.5_

  - [ ] 5.2 Implement sensor batch parsing
    - Add _handleSensorBatch() method to parse JSON
    - Extract bpm, accelerometer array, timestamp, count
    - Validate all required fields are present
    - _Requirements: 2.4_

  - [ ]* 5.3 Write property test for JSON parsing round-trip
    - **Property 8: JSON parsing round-trip**
    - **Validates: Requirements 2.4**

  - [ ] 5.4 Implement feature vector construction
    - Create 4-feature vectors [accX, accY, accZ, bpm] for each sample
    - Combine each accelerometer triplet with heart rate value
    - Emit SensorBatch with constructed feature vectors
    - _Requirements: 2.5_

  - [ ]* 5.5 Write property test for feature vector construction
    - **Property 9: Feature vector construction**
    - **Validates: Requirements 2.5**

  - [ ] 5.6 Add error handling for malformed JSON
    - Catch JSON parsing exceptions
    - Log error with raw data for debugging
    - Continue listening for next batch
    - _Requirements: 2.4_

- [ ] 6. Update WearHeartRateScreen UI with accessibility improvements
  - [ ] 6.1 Define WCAG-compliant color constants
    - Create color constants: primaryBlue (#2196F3), darkBlue (#1976D2), lightBlueGrey (#90CAF9), teal (#00BCD4), errorRed (#F44336)
    - Verify contrast ratios meet WCAG 2.1 Level AA requirements
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 6.2 Write property test for color theme consistency
    - **Property 15: Color theme consistency**
    - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**

  - [ ] 6.3 Create sensor status indicator widget
    - Build _buildSensorStatus() widget
    - Display heart rate icon (red when active, grey when inactive) with BPM value
    - Display accelerometer icon (blue when active, grey when inactive) with status text
    - Use minimum font size of 14sp for status text
    - _Requirements: 5.1, 5.2, 5.3, 3.1_

  - [ ]* 6.4 Write property test for sensor status indicator completeness
    - **Property 16: Sensor status indicator completeness**
    - **Validates: Requirements 5.1, 5.2, 5.3**

  - [ ] 6.5 Ensure touch target sizes meet accessibility standards
    - Set all button sizes to minimum 48x48dp
    - Add padding to ensure touch targets are large enough
    - Test with Android Accessibility Scanner
    - _Requirements: 3.3_

  - [ ]* 6.6 Write property test for touch target size compliance
    - **Property 12: Touch target size compliance**
    - **Validates: Requirements 3.3**

  - [ ] 6.7 Implement transmission animation
    - Add animation trigger when sensor batch is transmitted
    - Animate motion sensor icon briefly (under 300ms)
    - Use scale or fade animation
    - _Requirements: 5.4, 3.5_

  - [ ]* 6.8 Write property test for animation duration limit
    - **Property 14: Animation duration limit**
    - **Validates: Requirements 3.5**

  - [ ] 6.9 Add error display with descriptive text
    - Create error indicator widget
    - Display error icon and descriptive error message
    - Use errorRed color with sufficient contrast
    - _Requirements: 5.5_

  - [ ]* 6.10 Write property test for error display completeness
    - **Property 18: Error display completeness**
    - **Validates: Requirements 5.5**

  - [ ] 6.11 Update color scheme throughout UI
    - Apply primaryBlue to Start button
    - Apply darkBlue to pressed/active states
    - Apply lightBlueGrey to disabled states
    - Apply teal to success messages
    - Apply errorRed to error messages
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [ ]* 6.12 Write property test for contrast ratio compliance
    - **Property 11: Contrast ratio compliance**
    - **Validates: Requirements 3.2**

- [ ] 7. Implement permission handling flow
  - [ ] 7.1 Add permission check on app start
    - Check BODY_SENSORS and ACTIVITY_RECOGNITION permissions
    - Request permissions if not granted
    - _Requirements: 7.3_

  - [ ]* 7.2 Write property test for permission request on missing grant
    - **Property 22: Permission request on missing grant**
    - **Validates: Requirements 7.3**

  - [ ] 7.3 Create permission rationale screen
    - Display rationale when permissions are denied
    - Explain why sensor access is needed for activity tracking
    - Provide button to retry or open settings
    - _Requirements: 7.4_

  - [ ]* 7.4 Write property test for rationale display on denial
    - **Property 23: Rationale display on denial**
    - **Validates: Requirements 7.4**

  - [ ] 7.5 Implement sensor initialization after permission grant
    - Proceed to sensor initialization when permissions granted
    - Connect to Samsung Health SDK
    - Initialize accelerometer sensor
    - _Requirements: 7.5_

  - [ ]* 7.6 Write property test for initialization after grant
    - **Property 24: Initialization after grant**
    - **Validates: Requirements 7.5**

- [ ] 8. Add comprehensive logging for debugging
  - [ ] 8.1 Add logging to WatchSensorService
    - Log sensor collection events with timestamps
    - Log batch transmission with batch size and status
    - Log sensor errors with detailed information
    - _Requirements: 8.1, 8.2, 8.4_

  - [ ] 8.2 Add logging to PhoneDataListener
    - Log received sensor batches with sample count and heart rate
    - Log parsing errors with raw data
    - _Requirements: 8.3_

  - [ ]* 8.3 Write property test for logging completeness
    - **Property 25: Logging completeness**
    - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**

- [ ] 9. Checkpoint - Verify end-to-end sensor data flow
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Add error handling for edge cases
  - [ ] 10.1 Handle accelerometer unavailable
    - Check if accelerometer sensor is null
    - Display error message to user
    - Continue with heart rate only
    - _Requirements: 1.5_

  - [ ] 10.2 Handle phone disconnection
    - Detect when phone is not connected
    - Display "Phone disconnected" status
    - Continue collecting data (discard if buffer full)
    - _Requirements: Communication errors_

  - [ ] 10.3 Handle sensor initialization failures
    - Catch exceptions during sensor registration
    - Display error message with retry option
    - Log detailed error information
    - _Requirements: 6.5_

  - [ ]* 10.4 Write unit tests for error scenarios
    - Test accelerometer unavailable scenario
    - Test phone disconnection scenario
    - Test sensor initialization failure scenario
    - _Requirements: 1.5, 6.5_

- [ ] 11. Create test mode for debugging
  - [ ] 11.1 Add test mode toggle in UI
    - Add debug button to enable test mode
    - Display raw sensor values on screen when enabled
    - Show transmission status and batch count
    - _Requirements: 8.5_

  - [ ] 11.2 Display real-time sensor values in test mode
    - Show current accelerometer X, Y, Z values
    - Show current heart rate value
    - Show buffer size and time since last transmission
    - _Requirements: 8.5_

- [ ] 12. Final checkpoint - Complete testing and validation
  - Ensure all tests pass, ask the user if questions arise.
