from flask import Flask, jsonify, request
from flask_cors import CORS
import time
import random

app = Flask(__name__)
CORS(app)  # Enable CORS for local development

# In-memory database of vehicles
vehicles = {
    "VIN1001": {
        "vin": "VIN1001", 
        "model": "Model S", 
        "battery": 85, 
        "tire_pressure": 32, 
        "status": "OK",
        "location": {"lat": 48.8566, "lng": 2.3522}, # Paris
        "mileage": 12500,
        "ota_status": "IDLE",
        "last_update": time.time()
    },
    "VIN1002": {
        "vin": "VIN1002", 
        "model": "Cybertruck", 
        "battery": 12, 
        "tire_pressure": 35, 
        "status": "OK",
        "location": {"lat": 34.0522, "lng": -118.2437}, # LA
        "mileage": 500,
        "ota_status": "IDLE",
        "last_update": time.time()
    },
    "VIN1003": {
        "vin": "VIN1003", 
        "model": "Model 3", 
        "battery": 45, 
        "tire_pressure": 31, 
        "status": "OFFLINE",
        "location": {"lat": 52.5200, "lng": 13.4050}, # Berlin
        "mileage": 45600,
        "ota_status": "INSTALLING",
        "last_update": time.time()
    }
}

# Command history log
command_history = {vin: [] for vin in vehicles}
# Telemetry history (last 10 readings)
telemetry_history = {vin: [] for vin in vehicles}

@app.route('/vehicles', methods=['GET'])
def get_vehicles():
    return jsonify(list(vehicles.values()))

@app.route('/vehicle/<vin>/alert', methods=['POST'])
def inject_alert(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    
    data = request.json
    new_status = data.get("status", "ALERT")
    new_battery = data.get("battery", vehicles[vin]["battery"])
    
    vehicles[vin]["status"] = new_status
    vehicles[vin]["battery"] = new_battery
    vehicles[vin]["last_update"] = time.time()
    return jsonify({"message": f"Alert injected for {vin}", "vehicle": vehicles[vin]})

@app.route('/vehicle/<vin>/telemetry', methods=['POST'])
def update_telemetry(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    
    data = request.json
    
    # DATA VALIDATION EDGE CASES
    if "battery" in data:
        if not (0 <= data["battery"] <= 100):
            return jsonify({"error": "Battery must be 0-100"}), 400
        vehicles[vin]["battery"] = data["battery"]
        
    if "tire_pressure" in data:
        if data["tire_pressure"] < 0:
            return jsonify({"error": "Negative tire pressure detected"}), 400
        vehicles[vin]["tire_pressure"] = data["tire_pressure"]
        
    if "location" in data: vehicles[vin]["location"] = data["location"]
    if "mileage" in data: vehicles[vin]["mileage"] = data["mileage"]
    if "engine_temp" in data: vehicles[vin]["engine_temp"] = data["engine_temp"]
    
    vehicles[vin]["last_update"] = time.time()
    
    # Add to history
    entry = {
        "timestamp": time.time(),
        "battery": vehicles[vin].get("battery"),
        "tire_pressure": vehicles[vin].get("tire_pressure"),
        "engine_temp": vehicles[vin].get("engine_temp", 25)
    }
    telemetry_history[vin].append(entry)
    if len(telemetry_history[vin]) > 10:
        telemetry_history[vin].pop(0)
        
    return jsonify({"message": "Telemetry updated", "current": vehicles[vin]})

@app.route('/vehicle/<vin>/ota', methods=['POST'])
def trigger_ota(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    
    # Simulate an OTA update status change
    statuses = ["DOWNLOADING", "INSTALLING", "SUCCESS"]
    current_status = vehicles[vin]["ota_status"]
    
    if current_status == "IDLE" or current_status == "SUCCESS":
        next_status = "DOWNLOADING"
    elif current_status == "DOWNLOADING":
        next_status = "INSTALLING"
    else:
        next_status = "SUCCESS"
        
    vehicles[vin]["ota_status"] = next_status
    vehicles[vin]["last_update"] = time.time()
    
    log_entry = {"timestamp": time.time(), "command": "OTA_UPDATE", "result": next_status}
    command_history[vin].append(log_entry)
    
    return jsonify({"vin": vin, "ota_status": next_status})

@app.route('/vehicle/<vin>/command', methods=['POST'])
def send_command(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    
    data = request.json
    command = data.get("command")
    
    VALID_COMMANDS = ["LOCK", "UNLOCK", "FLASH_LIGHTS", "REMOTE_START", "PANIC", "HONK"]
    if command not in VALID_COMMANDS:
         log_entry = {"timestamp": time.time(), "command": command, "result": "REJECTED", "reason": "Invalid or Unknown Command"}
         command_history[vin].append(log_entry)
         return jsonify(log_entry), 400

    # SAFETY INTERLOCKS
    if command == "REMOTE_START" and vehicles[vin]["battery"] < 15:
        log_entry = {"timestamp": time.time(), "command": command, "result": "REJECTED", "reason": "Low Battery Safety Interlock"}
        command_history[vin].append(log_entry)
        return jsonify(log_entry), 403

    if command == "LOCK" and vehicles[vin]["status"] == "OFFLINE":
         log_entry = {"timestamp": time.time(), "command": command, "result": "REJECTED", "reason": "Vehicle Offline"}
         command_history[vin].append(log_entry)
         return jsonify(log_entry), 403
    
    # NEW: High Temperature Safety Interlock Simulation
    if command == "REMOTE_START" and vehicles.get(vin, {}).get("engine_temp", 25) > 105:
         log_entry = {"timestamp": time.time(), "command": command, "result": "REJECTED", "reason": "Thermal Safety Interlock"}
         command_history[vin].append(log_entry)
         return jsonify(log_entry), 403

    log_entry = {"timestamp": time.time(), "command": command, "result": "SUCCESS"}
    command_history[vin].append(log_entry)
    return jsonify(log_entry)

@app.route('/vehicle/<vin>/command-log', methods=['GET'])
def get_command_log(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    return jsonify(command_history[vin])

@app.route('/vehicle/<vin>/telemetry-history', methods=['GET'])
def get_telemetry_history(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    return jsonify(telemetry_history[vin])

if __name__ == '__main__':
    app.run(port=5001, debug=True)
