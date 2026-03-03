from flask import Flask, jsonify, request
from flask_cors import CORS
import time

app = Flask(__name__)
CORS(app)  # Enable CORS for local development

# In-memory database of vehicles
vehicles = {
    "VIN1001": {"vin": "VIN1001", "model": "Model S", "battery": 85, "tire_pressure": 32, "status": "OK"},
    "VIN1002": {"vin": "VIN1002", "model": "Cybertruck", "battery": 12, "tire_pressure": 35, "status": "OK"},
    "VIN1003": {"vin": "VIN1003", "model": "Model 3", "battery": 45, "tire_pressure": 31, "status": "OFFLINE"}
}

# Command history log
command_history = {vin: [] for vin in vehicles}

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
    return jsonify({"message": f"Alert injected for {vin}", "vehicle": vehicles[vin]})

@app.route('/vehicle/<vin>/command', methods=['POST'])
def send_command(vin):
    if vin not in vehicles:
        return jsonify({"error": "Vehicle not found"}), 404
    
    data = request.json
    command = data.get("command")
    
    # SAFETY INTERLOCK: Cannot remote start if battery is < 15%
    if command == "REMOTE_START" and vehicles[vin]["battery"] < 15:
        log_entry = {"timestamp": time.time(), "command": command, "result": "REJECTED", "reason": "Low Battery Safety Interlock"}
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

if __name__ == '__main__':
    app.run(port=5001, debug=True)
