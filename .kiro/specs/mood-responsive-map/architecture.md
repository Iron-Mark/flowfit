# Mood-Responsive Map - Architecture & Logic Flow

## 1. System Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ WellnessTracker  │  │  Track Tab       │                │
│  │     Page         │  │  (Entry Point)   │                │
│  └────────┬─────────┘  └──────────────────┘                │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ Watches State
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    STATE MANAGEMENT LAYER                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  WellnessStateNotifier (Riverpod StateNotifier)      │  │
│  │  - Exposes current wellness state to UI              │  │
│  │  - Manages state history                             │  │
│  └────────┬─────────────────────────────────────────────┘  │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ Subscribes to
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  WellnessStateService                                │  │
│  │  - State detection algorithm                         │  │
│  │  - Hysteresis filtering                              │  │
│  │  - Motion magnitude calculation                      │  │
│  └────────┬─────────────────────────────────────────────┘  │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ Consumes Data
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ WatchBridge      │  │ PhoneData        │                │
│  │ Service          │  │ Listener         │                │
│  │ (Heart Rate)     │  │ (Accelerometer)  │                │
│  └────────┬─────────┘  └────────┬─────────┘                │
└───────────┼──────────────────────┼──────────────────────────┘
            │                      │
            │ Platform Channels    │
            ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    HARDWARE LAYER                            │
│              Samsung Galaxy Watch Sensors                    │
│              - Heart Rate Monitor                            │
│              - Accelerometer                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Data Flow Architecture

### 2.1 Sensor Data Pipeline

```
[Watch Sensors] 
    ↓
[Native Android Code]
    ↓
[Method/Event Channels]
    ↓
[WatchBridgeService] ──→ heartRateStream (Stream<HeartRateData>)
    ↓
[PhoneDataListener] ──→ sensorBatchStream (Stream<SensorBatch>)
    ↓
[WellnessStateService]
    ├─→ Heart Rate Buffer (last 30 seconds)
    ├─→ Accelerometer Buffer (last 10 seconds, 320 samples)
    ├─→ Motion Magnitude Calculator
    └─→ State Detection Engine
         ├─→ Rule Evaluator
         ├─→ Hysteresis Filter
         └─→ State Emitter
              ↓
[WellnessStateNotifier] ──→ stateStream (Stream<WellnessState>)
    ↓
[WellnessTrackerPage]
    ├─→ UI Updates
    ├─→ Map Updates
    └─→ Notification Triggers
```

