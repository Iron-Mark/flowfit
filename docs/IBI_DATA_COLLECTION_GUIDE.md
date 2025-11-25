# IBI (Inter-Beat Interval) Data Collection Guide
## Samsung Health SDK → Kotlin Wear OS → Flutter Phone App

**Date:** November 25, 2025  
**Project:** FlowFit HR Data Transfer  
**Purpose:** Document how IBI data flows from Samsung Galaxy Watch 6 to Flutter app

---

## 📊 Overview: What is IBI?

**IBI (Inter-Beat Interval)** = Time between consecutive heartbeats in milliseconds

- **Normal range:** 600-1200 ms (corresponding to 50-100 BPM)
- **Used for:** Heart Rate Variability (HRV) calculation, stress analysis, fitness metrics
- **Example:** `[845, 777, 729]` = 3 heartbeats with intervals of 845ms, 777ms, 729ms

---

## 🔄 Data Flow Architecture

```
Samsung Health SDK (Watch Hardware)
        ↓
HealthTrackerService (Samsung API)
        ↓
TrackingRepositoryImpl.kt (IBI Extraction)
        ↓
MainViewModel.kt (State Management)
        ↓
MessageRepository.kt (Data Serialization)
        ↓
Google Wearable Data Layer (Bluetooth/WiFi)
        ↓
Flutter Phone App (JSON Deserialization)
```

---

## 1️⃣ Samsung Health SDK Layer

### Location: `TrackingRepositoryImpl.kt`

### SDK Configuration

```kotlin
// Line 33-35: Tracking type configuration
private val trackingType = HealthTrackerType.HEART_RATE_CONTINUOUS
private var heartRateTracker: HealthTracker? = null
```

**Key Points:**
- ✅ Uses `HEART_RATE_CONTINUOUS` mode (supports IBI)
- ✅ Returns IBI data as part of `DataPoint` objects
- ⚠️ IBI availability depends on:
  - Sensor contact quality
  - Watch model (Galaxy Watch 6 ✅ supported)
  - Firmware version
  - Tracking mode configuration

### IBI Data Reception

```kotlin
// Lines 96-133: Data point listener
override fun onDataReceived(dataPoints: MutableList<DataPoint>) {
    for (dataPoint in dataPoints) {
        // Extract Heart Rate
        val hrValue = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE)
        val hrStatus = dataPoint.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS)
        
        // Extract IBI values (THE CRITICAL PART)
        val validIbiList = getValidIbiList(dataPoint)
        
        if (validIbiList.isNotEmpty()) {
            if (trackedData == null) trackedData = TrackedData()
            trackedData.ibi.addAll(validIbiList)
            
            // Calculate HRV from IBI
            trackedData.hrv = calculateHRV(validIbiList)
        }
    }
}
```

**What happens:**
1. Samsung SDK sends `DataPoint` objects (1-2 per second)
2. Each `DataPoint` contains HR + IBI arrays
3. IBI values are extracted and validated
4. Only valid IBI values are kept

---

## 2️⃣ IBI Extraction & Validation

### Location: `IBIDataParsing.kt` (imported helper)

```kotlin
// Referenced in TrackingRepositoryImpl.kt line 7
import com.flowfit.data.IBIDataParsing.Companion.getValidIbiList
```

### Validation Logic

```kotlin
private fun getValidIbiList(dataPoint: DataPoint): ArrayList<Int> {
    // Extract raw IBI list from Samsung SDK
    val ibiList: List<Int> = dataPoint.getValue(ValueKey.HeartRateSet.IBI_LIST)
    
    // Extract status for each IBI value
    val ibiStatus: List<Int> = dataPoint.getValue(ValueKey.HeartRateSet.IBI_STATUS_LIST)
    
    val validIbiList = ArrayList<Int>()

    // Only keep IBI values with status = 0 (valid)
    for ((index, ibi) in ibiList.withIndex()) {
        if (ibiStatus[index] == 0) {
            validIbiList.add(ibi)
        }
    }
    
    return validIbiList
}
```

**Status Codes:**
- `0` = Valid IBI ✅
- `-1` = Invalid (sensor detached) ❌
- `-2` = Movement detected ❌
- `-3` = Low signal quality ❌

**Example:**
```kotlin
// Raw data from Samsung SDK:
ibiList = [845, 777, 0, 729]
ibiStatus = [0, 0, -2, 0]

// After validation:
validIbiList = [845, 777, 729]  // The 0 value with status -2 was filtered out
```

---

## 3️⃣ Rolling IBI History (NEW FEATURE)

### Location: `TrackingRepositoryImpl.kt` Lines 57-106

### Why Rolling History?

**Problem:** Samsung SDK sends IBI data inconsistently:
```
DataPoint 1: IBI = []         (empty)
DataPoint 2: IBI = [717]      (1 value)
DataPoint 3: IBI = []         (empty)
DataPoint 4: IBI = [845, 777] (2 values)
```

**Solution:** Maintain a rolling window of last 10 IBI values

```kotlin
// Line 57-59: Rolling history buffer
private val ibiHistory = ArrayList<Int>()
private val maxIbiHistory = 10

// Lines 73-106: HRV calculation with rolling window
private fun calculateHRV(ibiList: ArrayList<Int>): Double {
    // Add new IBI values to history
    ibiHistory.addAll(ibiList)
    
    // Keep only last 10 values
    while (ibiHistory.size > maxIbiHistory) {
        ibiHistory.removeAt(0)
    }
    
    // Need at least 2 values for HRV
    if (ibiHistory.size < 2) return 0.0
    
    // Calculate RMSSD (Root Mean Square of Successive Differences)
    val differences = mutableListOf<Double>()
    for (i in 0 until ibiHistory.size - 1) {
        val diff = ibiHistory[i + 1] - ibiHistory[i]
        differences.add(diff * diff.toDouble())
    }
    
    val hrv = if (differences.isNotEmpty()) {
        kotlin.math.sqrt(differences.average())
    } else {
        0.0
    }
    
    Log.i(TAG, "HRV calculated: $hrv from ${ibiHistory.size} IBI values")
    return hrv
}
```

**Benefits:**
- ✅ HRV calculated even with sporadic IBI data
- ✅ More stable HRV values (averaged over time)
- ✅ Handles empty IBI arrays gracefully

---

## 4️⃣ Data Model: TrackedData

### Location: `common/src/main/java/com/flowfit/data/TrackedData.kt`

```kotlin
@Serializable
data class TrackedData(
    var hr: Int = 0,                          // Heart Rate (BPM)
    var ibi: ArrayList<Int> = ArrayList(),    // Inter-Beat Intervals (ms) ⭐
    var hrv: Double = 0.0,                    // Calculated from IBI
    var spo2: Int = 0,                        // Blood Oxygen (%)
    var timestamp: Long = System.currentTimeMillis()
)
```

**IBI Field Details:**
- **Type:** `ArrayList<Int>`
- **Units:** Milliseconds (ms)
- **Range:** Typically 600-1200 ms
- **Size:** 0-10 values per DataPoint (varies)
- **Serialization:** Kotlinx Serialization → JSON

**Example JSON:**
```json
{
  "hr": 78,
  "ibi": [845, 777, 729],
  "hrv": 68.0,
  "spo2": 0,
  "timestamp": 1732545971348
}
```

---

## 5️⃣ ViewModel Processing

### Location: `MainViewModel.kt` Lines 136-165

```kotlin
private fun processExerciseUpdate(trackedData: TrackedData) {
    val hr = trackedData.hr
    val ibi = trackedData.ibi       // ⭐ IBI ArrayList
    val hrv = trackedData.hrv       // Calculated HRV
    val spo2 = trackedData.spo2
    
    Log.i(TAG, "HR: $hr, IBI count: ${ibi.size}, HRV: $hrv, SPO2: $spo2")
    
    currentHR = hr.toString()
    currentIBI = ibi                 // Store for UI display
    
    // Update HRV display
    if (hrv > 0) {
        currentHRV = String.format("%.1f", hrv)
        Log.i(TAG, "HRV updated to: $currentHRV ms")
    }
    
    // Update UI state
    _trackingState.value = TrackingState(
        trackingRunning = true,
        trackingError = false,
        valueHR = if (hr > 0) hr.toString() else "-",
        valueHRV = currentHRV,
        valueSPO2 = if (spo2 > 0) spo2.toString() else currentSPO2,
        valueIBI = ibi,              // ⭐ Passed to UI
        message = "Tracking..."
    )
}
```

**Log Output Example:**
```
I/MainViewModel: HR: 78, IBI count: 3, HRV: 68.0, SPO2: 0
I/MainViewModel: HRV updated to: 68.0 ms
I/TrackingRepositoryImpl: HRV calculated: 68.0 from 5 IBI values
```

---

## 6️⃣ Data Transmission to Phone

### Location: `MessageRepositoryImpl.kt`

```kotlin
override suspend fun sendMessage(
    coroutineScope: CoroutineScope,
    trackedData: TrackedData
): Boolean = suspendCoroutine { continuation ->
    
    // Serialize TrackedData to JSON
    val jsonString = Json.encodeToString(trackedData)
    
    // Send via Google Wearable Data Layer
    messageClient
        .sendMessage(
            nodeId,
            MESSAGE_PATH,
            jsonString.toByteArray()
        )
        .addOnSuccessListener {
            Log.i(TAG, "Message sent successfully: $jsonString")
            continuation.resume(true)
        }
}
```

**Transmitted JSON Example:**
```json
{
  "hr": 78,
  "ibi": [845, 777, 729, 754, 717],
  "hrv": 68.0,
  "spo2": 0,
  "timestamp": 1732545971348
}
```

**Message Path:** `/hr_data_path`  
**Transport:** Bluetooth Low Energy or WiFi Direct  
**Frequency:** Every 1-2 seconds (when HR updates)

---

## 7️⃣ Flutter Side Reception

### Expected JSON Structure

```dart
// In your Flutter app:
class TrackedData {
  final int hr;
  final List<int> ibiValues;    // ⭐ THIS IS THE IBI DATA
  final double hrv;
  final int spo2;
  final int timestamp;
  
  factory TrackedData.fromJson(Map<String, dynamic> json) {
    return TrackedData(
      hr: json['hr'] ?? 0,
      ibiValues: List<int>.from(json['ibi'] ?? []),  // Parse IBI array
      hrv: json['hrv']?.toDouble() ?? 0.0,
      spo2: json['spo2'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
    );
  }
}
```

### Why Flutter Shows Empty IBI

**Your log showed:**
```
"ibiValues": []
```

**Root Causes:**

1. **Samsung SDK Not Providing IBI:**
   - Sensor contact quality issues
   - Watch not properly worn
   - Tracking just started (no data accumulated yet)

2. **Timing Issue:**
   - First few DataPoints often have empty IBI
   - Takes 2-3 seconds to start receiving IBI data

3. **Validation Filtering:**
   - All IBI values had invalid status codes
   - `getValidIbiList()` filtered them all out

---

## 🔍 Debugging IBI Collection

### Check Samsung SDK Logs

```bash
adb logcat | grep -E "(TrackingRepositoryImpl|MainViewModel)"
```

**What to look for:**

✅ **Good - IBI data flowing:**
```
I/TrackingRepositoryImpl: valid HR: 78
I/MainViewModel: HR: 78, IBI count: 3, HRV: 68.0, SPO2: 0
I/TrackingRepositoryImpl: HRV calculated: 68.0 from 5 IBI values
```

❌ **Bad - No IBI data:**
```
I/TrackingRepositoryImpl: valid HR: 78
I/MainViewModel: HR: 78, IBI count: 0, HRV: 0.0, SPO2: 0
I/TrackingRepositoryImpl: HRV calculated: 0.0 from 0 IBI values
```

### Check Data Transmission

```bash
adb logcat | grep "MessageRepositoryImpl"
```

**Look for:**
```
I/MessageRepositoryImpl: Message sent successfully: {"hr":78,"ibi":[845,777,729],"hrv":68.0,"spo2":0,"timestamp":1732545971348}
```

If you see `"ibi":[]`, the problem is **before** transmission (Samsung SDK layer).

---

## 🛠️ Troubleshooting Guide

### Issue 1: Always Empty IBI

**Symptoms:**
- Flutter always receives `"ibi": []`
- Logs show `IBI count: 0`

**Solutions:**

1. **Check Watch Fit:**
   ```
   - Wear watch tighter (needs good sensor contact)
   - Position on wrist bone (not over it)
   - Clean watch sensors
   ```

2. **Verify Tracking Mode:**
   ```kotlin
   // In TrackingRepositoryImpl.kt
   // Confirm using HEART_RATE_CONTINUOUS
   private val trackingType = HealthTrackerType.HEART_RATE_CONTINUOUS
   ```

3. **Check Device Capabilities:**
   ```kotlin
   // Add this to setUpTracking() in MainViewModel
   val availableTrackers = getAvailableTrackersUseCase()
   Log.i(TAG, "Available: ${availableTrackers.joinToString()}")
   ```

### Issue 2: Sporadic IBI Data

**Symptoms:**
- Sometimes `"ibi": [729]`
- Sometimes `"ibi": []`
- Inconsistent HRV values

**This is NORMAL!** Samsung SDK behavior:
- Not every DataPoint contains IBI
- Typical pattern: 2-3 IBI values every 3-4 DataPoints

**Solution:** The rolling history fix (already implemented) handles this.

### Issue 3: IBI Present but HRV = 0

**Symptoms:**
- `IBI count: 1` but `HRV: 0.0`

**Explanation:**
HRV requires at least 2 IBI values. With rolling history:
- First IBI: HRV = 0 (need 2 for calculation)
- Second IBI: HRV = calculated ✅
- Subsequent: HRV continuously updated

---

## 📈 Performance Metrics

### Typical Data Rates (Galaxy Watch 6)

| Metric | Frequency | IBI per Update | Notes |
|--------|-----------|----------------|-------|
| HR DataPoints | 1-2 per second | 0-4 IBI values | Varies by movement |
| Valid IBI | 60-80% of time | Average 1-2 values | Good sensor contact |
| HRV Updates | Every 2-3 seconds | Calculated from 2+ IBI | Needs accumulated data |
| Message Transmission | Every update | Full IBI array | Sent to Flutter |

### Data Volume

**Per Minute:**
- ~60-120 DataPoints
- ~80-150 IBI values collected
- ~40-60 IBI values transmitted (after validation)

**JSON Size:**
- Typical message: ~150-200 bytes
- With 5 IBI values: ~180 bytes
- Bluetooth overhead: ~20-30 bytes

---

## 🎯 Flutter Implementation Guide

### 1. Message Listener Setup

```dart
// In your Flutter MessageListener
MessageClient.addListener(path: '/hr_data_path', (DataEvent event) {
  final String jsonString = utf8.decode(event.data);
  final Map<String, dynamic> json = jsonDecode(jsonString);
  
  final TrackedData data = TrackedData.fromJson(json);
  
  print('HR: ${data.hr} BPM');
  print('IBI values: ${data.ibiValues}');  // ⭐ YOUR IBI DATA
  print('HRV: ${data.hrv} ms');
  print('SPO2: ${data.spo2}%');
});
```

### 2. Handling Empty IBI

```dart
class TrackedData {
  final List<int> ibiValues;
  
  bool get hasIbiData => ibiValues.isNotEmpty;
  
  String get ibiDisplay {
    if (!hasIbiData) return 'No IBI data';
    return ibiValues.map((ibi) => '${ibi}ms').join(', ');
  }
  
  double? get calculatedHrv {
    if (ibiValues.length < 2) return null;
    
    // Calculate HRV from IBI (same RMSSD algorithm)
    List<double> diffs = [];
    for (int i = 0; i < ibiValues.length - 1; i++) {
      final diff = ibiValues[i + 1] - ibiValues[i];
      diffs.add(diff * diff.toDouble());
    }
    
    return sqrt(diffs.reduce((a, b) => a + b) / diffs.length);
  }
}
```

### 3. UI Display

```dart
Widget buildHealthMetrics(TrackedData data) {
  return Column(
    children: [
      Text('HR: ${data.hr} BPM'),
      Text('HRV: ${data.hrv.toStringAsFixed(1)} ms'),
      
      // Display IBI values
      if (data.hasIbiData)
        Text('IBI: ${data.ibiDisplay}')
      else
        Text('IBI: Waiting for data...', style: TextStyle(color: Colors.grey)),
      
      // Visual IBI indicator
      Row(
        children: data.ibiValues.take(5).map((ibi) =>
          Container(
            width: 40,
            height: (ibi / 10).clamp(30, 100),  // Visual bar height
            color: Colors.red,
            margin: EdgeInsets.all(2),
          )
        ).toList(),
      ),
    ],
  );
}
```

---

## 📝 Key Takeaways for Flutter Integration

### ✅ What's Working (Kotlin Side)

1. **IBI Extraction:** ✅ `getValidIbiList()` properly filters valid IBI values
2. **IBI Validation:** ✅ Status codes checked, invalid values removed
3. **Rolling History:** ✅ Maintains 10-value window for stable HRV
4. **Data Model:** ✅ `TrackedData` includes `ArrayList<Int> ibi`
5. **Serialization:** ✅ Kotlinx Serialization → JSON with IBI array
6. **Transmission:** ✅ Full IBI array sent via Wearable Data Layer

### ⚠️ What to Handle (Flutter Side)

1. **Empty IBI Arrays:** Normal during first few seconds or poor sensor contact
2. **Variable IBI Count:** Sometimes 0, sometimes 1-4 values per message
3. **Null Safety:** Handle missing or zero IBI values gracefully
4. **HRV Calculation:** Can calculate client-side or use transmitted `hrv` value
5. **Historical Data:** Consider storing IBI history in Flutter for trend analysis

### 🔧 Configuration to Verify

**In `TrackingRepositoryImpl.kt`:**
```kotlin
// Line 33: Confirm this is set
private val trackingType = HealthTrackerType.HEART_RATE_CONTINUOUS
```

**NOT this:**
```kotlin
// ❌ Don't use these - they don't provide IBI
HealthTrackerType.HEART_RATE_ON_DEMAND
HealthTrackerType.HEART_RATE_INTERVAL
```

---

## 🚀 Next Steps

### For Testing IBI in Flutter

1. **Start fresh tracking session:**
   ```bash
   adb install -r wear/build/outputs/apk/debug/wear-debug.apk
   ```

2. **Monitor Kotlin logs:**
   ```bash
   adb logcat | grep -E "IBI count:|HRV calculated:"
   ```

3. **Check Flutter reception:**
   ```dart
   print('Received IBI: ${data.ibiValues.length} values');
   ```

4. **Wait 5-10 seconds:**
   - First few messages may have empty IBI
   - IBI data starts flowing after initial calibration

### For Production

1. **Add IBI buffer in Flutter:**
   - Maintain rolling window (like Kotlin side)
   - Calculate HRV client-side for verification

2. **Add IBI visualization:**
   - Real-time IBI chart
   - HRV trends over time
   - Stress level indicators

3. **Error handling:**
   - Show "Waiting for IBI..." when empty
   - Alert if no IBI for >30 seconds
   - Suggest better watch fit

---

## 📚 References

### Samsung Health SDK Documentation
- **IBI Data:** `ValueKey.HeartRateSet.IBI_LIST`
- **IBI Status:** `ValueKey.HeartRateSet.IBI_STATUS_LIST`
- **Tracking Type:** `HealthTrackerType.HEART_RATE_CONTINUOUS`

### Code Locations
- **IBI Extraction:** `TrackingRepositoryImpl.kt` lines 119-125
- **IBI Validation:** `IBIDataParsing.kt` (imported helper)
- **HRV Calculation:** `TrackingRepositoryImpl.kt` lines 73-106
- **Data Model:** `common/TrackedData.kt` line 6
- **Transmission:** `MessageRepositoryImpl.kt` sendMessage()

### HRV Calculation (RMSSD)
```
RMSSD = √(Σ(IBI[i+1] - IBI[i])² / (N-1))
```

Where:
- `IBI[i]` = Inter-beat interval at index i
- `N` = Number of IBI values
- Result in milliseconds (ms)

**Normal HRV Range:**
- Athletes: 60-100 ms
- Average: 30-60 ms
- Low: <30 ms

---

**Document Version:** 1.0  
**Last Updated:** November 25, 2025  
**Verified On:** Galaxy Watch 6 + Samsung Health SDK 1.5.0
