# TensorFlow Lite Model - Data Requirements

## 📊 Model Input Requirements

The Activity AI classifier requires **4 data points per sample** over a **10-second window**.

### Input Shape
```
[320 samples, 4 features]
```

- **320 samples** = 10 seconds @ 32Hz sampling rate
- **4 features** = [AccX, AccY, AccZ, BPM]

## 🎯 Required Data from Smartwatch

### 1. **Accelerometer Data** (3 axes)

#### What It Is:
- **AccX**: Acceleration on X-axis (left/right movement)
- **AccY**: Acceleration on Y-axis (forward/backward movement)
- **AccZ**: Acceleration on Z-axis (up/down movement)

#### Units:
- **m/s²** (meters per second squared)
- Typical range: -20 to +20 m/s²
- Gravity component: ~9.8 m/s² on Z-axis when stationary

#### Sampling Rate:
- **32 Hz** (32 samples per second)
- **Required**: 320 samples (10 seconds of data)

#### How to Get from Galaxy Watch:
```kotlin
// In your Galaxy Watch app (Kotlin)
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

class AccelerometerCollector : SensorEventListener {
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    
    fun startCollecting() {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        
        // Register listener at 32Hz (SENSOR_DELAY_GAME ≈ 20ms = 50Hz, adjust as needed)
        sensorManager.registerListener(
            this,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME
        )
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val accX = event.values[0]  // X-axis
            val accY = event.values[1]  // Y-axis
            val accZ = event.values[2]  // Z-axis
            
            // Send to phone or buffer locally
            sendToPhone(accX, accY, accZ)
        }
    }
}
```

#### Data Format to Send:
```json
{
  "type": "accelerometer",
  "timestamp": 1732545971348,
  "accX": 0.15,
  "accY": -0.23,
  "accZ": 9.81
}
```

---

### 2. **Heart Rate (BPM)**

#### What It Is:
- **BPM**: Beats Per Minute
- Current heart rate reading

#### Units:
- **BPM** (beats per minute)
- Typical range: 40-200 BPM
- Resting: 60-100 BPM
- Exercise: 100-180 BPM

#### Sampling Rate:
- **1 Hz** (1 sample per second) - then repeated for each accelerometer sample
- The same BPM value is used for all 32 accelerometer samples in that second

#### How to Get from Galaxy Watch:
```kotlin
// Using Samsung Health Sensor SDK
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.ValueKey

class HeartRateCollector {
    private var healthTracker: HealthTracker? = null
    
    fun startCollecting() {
        val connectionListener = object : HealthTracker.TrackerEventListener {
            override fun onDataReceived(dataPoints: List<DataPoint>) {
                for (dataPoint in dataPoints) {
                    val bpm = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
                    val status = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS)
                    
                    if (status == 0) { // Valid reading
                        sendToPhone(bpm)
                    }
                }
            }
            
            override fun onError(error: HealthTracker.TrackerError) {
                Log.e("HR", "Error: ${error.name}")
            }
            
            override fun onFlushCompleted() {}
        }
        
        healthTracker = healthTrackerManager.getHealthTracker(
            HealthTrackerType.HEART_RATE
        )
        healthTracker?.setEventListener(connectionListener)
    }
}
```

#### Data Format to Send:
```json
{
  "type": "heartrate",
  "timestamp": 1732545971348,
  "bpm": 78,
  "status": "active"
}
```

---

## 📦 Complete Data Package

### Option 1: Send Combined Data (Recommended)
Send accelerometer + heart rate together every ~31ms (32Hz):

```json
{
  "timestamp": 1732545971348,
  "accX": 0.15,
  "accY": -0.23,
  "accZ": 9.81,
  "bpm": 78
}
```

### Option 2: Send Separately
Send accelerometer at 32Hz, heart rate at 1Hz:

**Accelerometer (32 times per second):**
```json
{
  "type": "accelerometer",
  "timestamp": 1732545971348,
  "accX": 0.15,
  "accY": -0.23,
  "accZ": 9.81
}
```

**Heart Rate (1 time per second):**
```json
{
  "type": "heartrate",
  "timestamp": 1732545971000,
  "bpm": 78
}
```

---

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GALAXY WATCH                             │
│                                                             │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │  Accelerometer   │      │  Heart Rate      │            │
│  │  Sensor          │      │  Sensor          │            │
│  │  (32 Hz)         │      │  (1 Hz)          │            │
│  └────────┬─────────┘      └────────┬─────────┘            │
│           │                         │                       │
│           ▼                         ▼                       │
│  ┌─────────────────────────────────────────┐               │
│  │      Data Collector Service             │               │
│  │  - Buffer accelerometer data            │               │
│  │  - Attach latest BPM to each sample     │               │
│  │  - Create [AccX, AccY, AccZ, BPM]       │               │
│  └────────────────┬────────────────────────┘               │
│                   │                                         │
└───────────────────┼─────────────────────────────────────────┘
                    │ Wearable Data Layer API
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    ANDROID PHONE                            │
│                                                             │
│  ┌─────────────────────────────────────────┐               │
│  │      PhoneDataListener                  │               │
│  │  - Receives data from watch             │               │
│  │  - Parses JSON                          │               │
│  └────────────────┬────────────────────────┘               │
│                   │                                         │
│                   ▼                                         │
│  ┌─────────────────────────────────────────┐               │
│  │      Activity Classifier                │               │
│  │  - Buffers 320 samples (10 seconds)     │               │
│  │  - Sliding window                       │               │
│  └────────────────┬────────────────────────┘               │
│                   │                                         │
│                   ▼                                         │
│  ┌─────────────────────────────────────────┐               │
│  │      TensorFlow Lite Model              │               │
│  │  Input: [320, 4]                        │               │
│  │  Output: [Stress, Cardio, Strength]     │               │
│  └────────────────┬────────────────────────┘               │
│                   │                                         │
│                   ▼                                         │
│  ┌─────────────────────────────────────────┐               │
│  │      UI Display                         │               │
│  │  - Show activity label                  │               │
│  │  - Show probabilities                   │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Implementation Checklist

### On Galaxy Watch (Kotlin):

- [ ] **1. Add Sensor Permissions**
  ```xml
  <!-- AndroidManifest.xml -->
  <uses-permission android:name="android.permission.BODY_SENSORS" />
  <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
  ```

- [ ] **2. Initialize Accelerometer**
  - Get SensorManager
  - Register accelerometer listener at 32Hz
  - Buffer readings

- [ ] **3. Initialize Heart Rate Sensor**
  - Use Samsung Health Sensor SDK
  - Get HealthTracker for heart rate
  - Update BPM every second

- [ ] **4. Combine Data**
  - For each accelerometer reading, attach latest BPM
  - Create data packet: `[accX, accY, accZ, bpm]`

- [ ] **5. Send to Phone**
  - Use Wearable Data Layer API
  - Send via MessageClient or DataClient
  - Path: `/heart_rate` or `/sensor_data`

### On Android Phone (Flutter/Dart):

- [ ] **1. Receive Data**
  - PhoneDataListener already implemented ✅
  - Receives heart rate data ✅

- [ ] **2. Add Accelerometer Reception**
  - Extend PhoneDataListener to receive accelerometer
  - Parse combined data packets

- [ ] **3. Buffer Data**
  - Already implemented in TrackerPage ✅
  - Maintains 320-sample window ✅

- [ ] **4. Run Inference**
  - Already implemented ✅
  - Runs every ~1 second ✅

---

## 🎯 Current Status

### ✅ Already Working:
- Heart rate reception from watch
- Accelerometer from phone sensors
- TensorFlow Lite model inference
- Activity classification UI
- Watch mode selection

### ⚠️ Needs Implementation:
- **Accelerometer data from watch** (currently using phone accelerometer)
- Combined data packet format
- Watch-side data collection service

---

## 📝 Data Format Specification

### Recommended Format (Combined):

```json
{
  "type": "sensor_data",
  "timestamp": 1732545971348,
  "samples": [
    {
      "accX": 0.15,
      "accY": -0.23,
      "accZ": 9.81,
      "bpm": 78
    },
    {
      "accX": 0.16,
      "accY": -0.22,
      "accZ": 9.80,
      "bpm": 78
    }
    // ... up to 32 samples per second
  ]
}
```

### Alternative Format (Batch):

```json
{
  "type": "sensor_batch",
  "timestamp": 1732545971348,
  "duration_ms": 1000,
  "sample_rate": 32,
  "bpm": 78,
  "accelerometer": [
    [0.15, -0.23, 9.81],
    [0.16, -0.22, 9.80],
    [0.14, -0.24, 9.82]
    // ... 32 samples
  ]
}
```

---

## 🔧 Watch Implementation Example

### Complete Kotlin Example:

```kotlin
class SensorDataCollector(private val context: Context) {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    
    private var currentBpm = 0
    private val dataBuffer = mutableListOf<SensorData>()
    
    data class SensorData(
        val accX: Float,
        val accY: Float,
        val accZ: Float,
        val bpm: Int,
        val timestamp: Long
    )
    
    // Accelerometer listener
    private val accelListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            event?.let {
                val data = SensorData(
                    accX = it.values[0],
                    accY = it.values[1],
                    accZ = it.values[2],
                    bpm = currentBpm,
                    timestamp = System.currentTimeMillis()
                )
                
                dataBuffer.add(data)
                
                // Send batch every 32 samples (1 second)
                if (dataBuffer.size >= 32) {
                    sendBatchToPhone(dataBuffer.toList())
                    dataBuffer.clear()
                }
            }
        }
        
        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }
    
    // Heart rate listener
    private val hrListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(dataPoints: List<DataPoint>) {
            dataPoints.firstOrNull()?.let { point ->
                currentBpm = point.getValue(ValueKey.HeartRateSet.HEART_RATE)
            }
        }
        
        override fun onError(error: HealthTracker.TrackerError) {
            Log.e("HR", "Error: ${error.name}")
        }
        
        override fun onFlushCompleted() {}
    }
    
    fun start() {
        // Start accelerometer at ~32Hz
        sensorManager.registerListener(
            accelListener,
            accelerometer,
            SensorManager.SENSOR_DELAY_GAME // ~20ms = 50Hz, will be downsampled
        )
        
        // Start heart rate
        healthTracker?.setEventListener(hrListener)
    }
    
    private fun sendBatchToPhone(batch: List<SensorData>) {
        val json = JSONObject().apply {
            put("type", "sensor_batch")
            put("timestamp", System.currentTimeMillis())
            put("bpm", currentBpm)
            
            val samples = JSONArray()
            batch.forEach { data ->
                samples.put(JSONObject().apply {
                    put("accX", data.accX)
                    put("accY", data.accY)
                    put("accZ", data.accZ)
                })
            }
            put("samples", samples)
        }
        
        // Send via Wearable Data Layer
        sendMessageToPhone("/sensor_data", json.toString().toByteArray())
    }
}
```

---

## 📊 Data Quality Requirements

### Accelerometer:
- ✅ Sampling rate: 32 Hz (±2 Hz acceptable)
- ✅ Range: -20 to +20 m/s²
- ✅ Accuracy: ±0.1 m/s²
- ✅ Latency: < 100ms

### Heart Rate:
- ✅ Update rate: 1 Hz minimum
- ✅ Range: 40-200 BPM
- ✅ Accuracy: ±5 BPM
- ✅ Valid readings only (filter out errors)

### Timing:
- ✅ Synchronized timestamps
- ✅ No gaps > 100ms
- ✅ Consistent sampling rate

---

## 🚀 Next Steps

1. **Implement watch-side accelerometer collection**
2. **Create combined data packet format**
3. **Update PhoneDataListener to receive accelerometer**
4. **Test with real watch data**
5. **Optimize battery usage**

---

## 📚 References

- [Samsung Health Sensor SDK](https://developer.samsung.com/health/android/data/guide/health-sensor.html)
- [Android Sensor API](https://developer.android.com/guide/topics/sensors/sensors_motion)
- [Wearable Data Layer](https://developer.android.com/training/wearables/data-layer)
- [TensorFlow Lite](https://www.tensorflow.org/lite)

---

**Summary:** The model needs **accelerometer (X, Y, Z)** and **heart rate (BPM)** data at **32Hz** for **10 seconds** (320 samples). Currently, heart rate comes from the watch, but accelerometer comes from the phone. To fully use watch data, implement accelerometer collection on the watch and send combined packets to the phone.
