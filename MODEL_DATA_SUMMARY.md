# TensorFlow Lite Model - Data Summary

## 📊 Quick Reference

| Data Type | Source | Rate | Units | Range | Status |
|-----------|--------|------|-------|-------|--------|
| **AccX** | Watch Accelerometer | 32 Hz | m/s² | -20 to +20 | ⚠️ Need to implement |
| **AccY** | Watch Accelerometer | 32 Hz | m/s² | -20 to +20 | ⚠️ Need to implement |
| **AccZ** | Watch Accelerometer | 32 Hz | m/s² | -20 to +20 | ⚠️ Need to implement |
| **BPM** | Watch Heart Rate | 1 Hz | BPM | 40-200 | ✅ Working |

## 🎯 Model Requirements

```
Input Shape: [320, 4]
- 320 samples = 10 seconds @ 32Hz
- 4 features = [AccX, AccY, AccZ, BPM]

Output: [3 probabilities]
- Stress probability (0-1)
- Cardio probability (0-1)
- Strength probability (0-1)
```

## 📦 Data Packet Format

### JSON Format (Recommended):
```json
{
  "timestamp": 1732545971348,
  "accX": 0.15,
  "accY": -0.23,
  "accZ": 9.81,
  "bpm": 78
}
```

### Send Rate:
- **32 packets per second** (every ~31ms)
- Each packet contains all 4 values

## 🔧 Watch Implementation Needed

### 1. Accelerometer Setup (Kotlin)
```kotlin
// Get sensor
val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

// Register at 32Hz
sensorManager.registerListener(
    listener,
    accelerometer,
    SensorManager.SENSOR_DELAY_GAME // ~20ms
)
```

### 2. Combine with Heart Rate
```kotlin
// For each accelerometer reading
val data = mapOf(
    "timestamp" to System.currentTimeMillis(),
    "accX" to event.values[0],
    "accY" to event.values[1],
    "accZ" to event.values[2],
    "bpm" to currentBpm
)
```

### 3. Send to Phone
```kotlin
// Via Wearable Data Layer
val json = JSONObject(data).toString()
sendMessageToPhone("/sensor_data", json.toByteArray())
```

## 📱 Phone Side (Already Implemented)

### Current Status:
- ✅ Receives heart rate from watch
- ✅ Uses phone accelerometer (fallback)
- ✅ Buffers 320 samples
- ✅ Runs TFLite inference
- ✅ Displays activity classification

### What's Needed:
- ⚠️ Receive accelerometer from watch
- ⚠️ Parse combined data packets
- ⚠️ Switch from phone to watch accelerometer

## 🎯 Implementation Priority

### High Priority:
1. ✅ Heart rate from watch - **DONE**
2. ⚠️ Accelerometer from watch - **TODO**
3. ⚠️ Combined data packets - **TODO**

### Medium Priority:
4. Battery optimization
5. Data quality validation
6. Error handling

### Low Priority:
7. Data compression
8. Offline buffering
9. Historical data export

## 📝 Files to Modify

### Watch Side (Kotlin):
- `WatchSensorService.kt` - Add accelerometer collection
- `DataSender.kt` - Send combined packets
- `AndroidManifest.xml` - Add permissions

### Phone Side (Flutter):
- `lib/services/phone_data_listener.dart` - Receive accelerometer
- `lib/features/activity_classifier/presentation/tracker_page.dart` - Use watch accelerometer

## 🚀 Quick Start

### To test with current setup:
```bash
# Run app
flutter run -d 6ece264d

# Navigate to Activity AI
# Select "Watch" mode
# Uses: Watch heart rate + Phone accelerometer
```

### After implementing watch accelerometer:
```bash
# Will use: Watch heart rate + Watch accelerometer
# More accurate activity classification
# Better battery life (single device)
```

## 📊 Data Flow

```
Watch Sensors → Watch App → Wearable Data Layer → Phone App → TFLite Model → UI
```

**Current:**
```
Watch HR ✅ → Phone ✅ → Model ✅
Phone Accel ✅ → Model ✅
```

**Target:**
```
Watch HR ✅ → Phone ✅ → Model ✅
Watch Accel ⚠️ → Phone ⚠️ → Model ✅
```

---

See **TFLITE_MODEL_DATA_REQUIREMENTS.md** for complete implementation details.
