## ShieldDrive | Automotive Telematics & Fleet Management Portal

ShieldDrive is a functional prototype of a modern automotive fleet management system. It demonstrates how to bridge the gap between web development and automotive engineering by using **Robot Framework** to test end-to-end telematics flows.

## Project Overview

### Why this project is needed

In the modern automotive industry, vehicles are becoming **Software-Defined Vehicles (SDVs)**. A single remote feature, such as "Remote Climate Control Start," is no longer just a UI button—it is a distributed system transaction. Testing just the mobile app or just the car's firmware in isolation is insufficient because critical failures often occur at the **integration points**.

The industry faces several challenges that ShieldDrive addresses:

1.  **Complexity of the Telematics Chain**: A command must travel from a User Interface, through a Cloud Backend, across a Cellular Network to the Telematics Control Unit (TCU), and finally onto the Vehicle Bus (CAN). Any break in this chain causes a failure.
2.  **Strict Safety Interlocks**: Automotive systems must obey thousands of safety "guardrails" (e.g., _Do not remote start if the hood is open_ or _Do not lock doors if a key is inside_). These rules live in the cloud and the car simultaneously and must be validated under all conditions.
3.  **HIL/SIL Accessibility**: Hardware-in-the-Loop (HIL) test benches are expensive and scarce. This project provides a **Software-in-the-Loop (SIL)** environment that allows engineers to validate E2E logic, error handling, and UI feedback without needing a physical ECU or vehicle.

ShieldDrive simulates this entire ecosystem, providing a robust platform for validating distributed automotive logic and ensuring that "The Cloud" and "The Vehicle" stay in perfect sync.

## What was Implemented

### 1. Telematics Backend (`server.py`)

A Python Flask REST API that acts as the "Cloud Brain."

- **Vehicle State Management**: Stores real-time data including **GPS Location**, **Mileage**, Battery, and Tire Pressure.
- **Remote Command Logic**: Handles execution of commands with built-in safety interlocks.
- **OTA Update Simulation**: A state machine for simulating Over-the-Air software updates (`DOWNLOADING` -> `INSTALLING` -> `SUCCESS`).
- **Telemetry History**: Maintains a rolling window of the last 10 telemetry readings for trend analysis.
- **Safety Interlocks**: Advanced validation (e.g., rejecting commands for `OFFLINE` vehicles or low-battery states).

### 2. Fleet Dashboard (`dashboard.html`)

A premium, dark-mode web interface for fleet managers.

- **Advanced Visualization**: Displays real-time GPS coordinates and mileage for every vehicle in the fleet.
- **OTA Management**: Dedicated UI controls to trigger and monitor software updates with status-specific color coding.
- **Real-time Polling**: Automatically refreshes vehicle state and "Last Updated" timestamps every 3 seconds.
- **Interactive Controls**: Dynamic buttons that auto-disable based on vehicle connectivity status.

### 3. E2E Test Suite (`tests/fleet_tests.robot`)

A Robot Framework suite that orchestrates complex test scenarios:

- **OTA Workflow Validation**: Verifies that triggering an update correctly moves the system through sequential states.
- **Offline Safety Interlocks**: Validates that the UI and API correctly block operations on disconnected vehicles.
- **Alert Injection**: Simulates vehicle faults and verifies real-time UI reaction.
- **Command Traceability**: Ensures every interaction is logged for audit purposes.

## Project Structure

```text
.
├── server.py              # Flask Backend API (Telematics Simulation)
├── dashboard.html         # Fleet Management UI
├── tests/
│   ├── fleet_tests.robot   # Main E2E Automotive Tests
│   └── example_tests.robot # Basic Framework Examples
├── resources/
│   └── common_keywords.robot # Reusable low-level keywords
├── results/               # Generated test logs and screenshots
├── requirements.txt       # Python dependencies
└── robot.ini              # Robot Framework configuration
```

## Getting Started

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Start the Backend Server

```bash
python3 server.py
```

_The server will run on `http://127.0.0.1:5001`._

### 3. Open the Dashboard

Simply open `dashboard.html` in any modern web browser (Chrome recommended).

### 4. Run Automated Tests

```bash
robot -d results tests/fleet_tests.robot
```

## Future Development Roadmap

ShieldDrive is designed to be modular and can be expanded with the following:

- **MQTT Integration**: Replace the REST polling with a real-time MQTT broker for "Vehicle-to-Cloud" messaging.
- **Page Object Model (POM)**: Refactor the Robot tests to use a POM architecture for better maintainability.
- **Database Persistence**: Move from in-memory storage to SQLite or PostgreSQL to persist fleet history.
- **CI/CD Integration**: Fully configured GitHub Actions workflow that automatically runs the E2E suite on every push.
- **CAN Bus Simulation**: Integrate with `python-can` and `vcan` to route commands to virtual vehicle hardware.
- **Authentication**: Add a login layer with JWT to test secure user access to the fleet.

## CI/CD Workflow

The project includes a GitHub Actions workflow located at `.github/workflows/robot-tests.yml`. This workflow:

1.  Sets up a Python 3.10 environment.
2.  Installs all dependencies.
3.  Spins up the Telematics Backend in the background.
4.  Executes the Robot Framework suite in `headlesschrome` mode.
5.  Uploads test logs, reports, and failed-test screenshots as build artifacts.

---

_Created as a demonstration of expert Automotive Software Testing and Test Architecture._
