*** Settings ***
Documentation     End-to-end tests for ShieldDrive Fleet Management Portal
Library           SeleniumLibrary
Library           RequestsLibrary
Library           Collections

Suite Setup       Setup Global Variables
Test Teardown     Close Browser

*** Variables ***
${DASHBOARD_URL}    file://${CURDIR}/../dashboard.html
${API_BASE}         http://localhost:5001
${BROWSER}          chrome
${VIN_WITH_LOW_BATT}    VIN1002
${VIN_FOR_ALERT}        VIN1001

*** Keywords ***
Setup Global Variables
    Create Session    api    ${API_BASE}

Inject Vehicle Alert
    [Arguments]    ${vin}    ${status}    ${battery}=85
    ${data}=    Create Dictionary    status=${status}    battery=${battery}
    ${resp}=    POST On Session    api    /vehicle/${vin}/alert    json=${data}
    Should Be Equal As Integers    ${resp.status_code}    200

Verify Vehicle Card Status
    [Arguments]    ${vin}    ${expected_status}
    Wait Until Element Contains    id=card-${vin}    ${expected_status}    timeout=10s
    ${class}=    Get Element Attribute    id=card-${vin}    class
    Should Contain    ${class}    status-${expected_status.lower()}

*** Test Cases ***
Scenario 1: Inject Alert and Verify UI Color Change
    [Documentation]    Inject a CRITICAL alert via API and verify the UI turns red (ALERT status)
    [Tags]    telematics    ui
    # 0. Ensure clean start
    Inject Vehicle Alert    ${VIN_FOR_ALERT}    OK
    
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    Maximize Browser Window
    
    # 1. Verify initial state is OK
    Verify Vehicle Card Status    ${VIN_FOR_ALERT}    OK
    
    # 2. Inject Alert via API
    Inject Vehicle Alert    ${VIN_FOR_ALERT}    ALERT

    
    # 3. Verify UI reflects the alert (red pulsing border via class)
    Verify Vehicle Card Status    ${VIN_FOR_ALERT}    ALERT
    Capture Page Screenshot    alert_verification.png

Scenario 2: Remote Command Logging Verification
    [Documentation]    Click 'Flash Lights' on Dashboard and verify API logs the command
    [Tags]    telematics    api
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    
    # 1. Click Flash Lights on the specific vehicle card
    Wait Until Element Is Visible    xpath=//div[@id='card-${VIN_FOR_ALERT}']//button[text()='FLASH LIGHTS']
    Click Button    xpath=//div[@id='card-${VIN_FOR_ALERT}']//button[text()='FLASH LIGHTS']
    
    # 2. Wait for UI Toast notification
    Wait Until Element Is Visible    id=toast    timeout=5s
    Element Should Contain    id=toast    FLASH_LIGHTS: SUCCESS
    
    # 3. Verify API log reflects the command
    ${resp}=    GET On Session    api    /vehicle/${VIN_FOR_ALERT}/command-log
    ${logs}=    Set Variable    ${resp.json()}
    ${last_command}=    Get From List    ${logs}    -1
    Should Be Equal As Strings    ${last_command['command']}    FLASH_LIGHTS
    Should Be Equal As Strings    ${last_command['result']}     SUCCESS

Scenario 3: Safety Interlock - Low Battery Prevents Remote Start
    [Documentation]    Verify vehicle with < 15% battery cannot be remote started
    [Tags]    safety    interlock
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    
    # 1. Ensure vehicle has low battery (VIN1002 starts with 12%)
    Element Should Contain    id=battery-VIN1002    12%
    
    # 2. Trigger Remote Start
    Click Button    xpath=//div[@id='card-VIN1002']//button[text()='REMOTE START']
    
    # 3. Verify rejection in UI Toast
    Wait Until Element Is Visible    id=toast    timeout=5s
    Element Should Contain    id=toast    FAILED: Low Battery Safety Interlock
    
    # 4. Verify API also recorded the rejection
    ${resp}=    GET On Session    api    /vehicle/VIN1002/command-log
    ${logs}=    Set Variable    ${resp.json()}
    ${last_command}=    Get From List    ${logs}    -1
    Should Be Equal As Strings    ${last_command['result']}    REJECTED
    Capture Page Screenshot    safety_interlock_rejection.png

Scenario 4: OTA Update Workflow Verification
    [Documentation]    Trigger an OTA update and verify status progression in UI
    [Tags]    ota    telematics
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    
    # 1. Trigger OTA Update for VIN1001
    Click Button    xpath=//div[@id='card-VIN1001']//button[text()='TRIGGER OTA UPDATE']
    
    # 2. Verify UI shows OTA badge (status: DOWNLOADING)
    Wait Until Element Is Visible    xpath=//div[@id='card-VIN1001']//span[contains(@class, 'badge-ota')]    timeout=5s
    Element Should Contain    xpath=//div[@id='card-VIN1001']//span[contains(@class, 'badge-ota')]    DOWNLOADING
    
    # 3. Trigger again to move to INSTALLING
    Click Button    xpath=//div[@id='card-VIN1001']//button[text()='TRIGGER OTA UPDATE']
    Wait Until Element Contains    xpath=//div[@id='card-VIN1001']//span[contains(@class, 'badge-ota')]    INSTALLING    timeout=5s
    
    Capture Page Screenshot    ota_update_progress.png

Scenario 5: Offline Vehicle Safety Interlock
    [Documentation]    Verify that commands are rejected (and buttons disabled) for OFFLINE vehicles
    [Tags]    safety    offline
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    
    # 1. VIN1003 is OFFLINE. Check that LOCK button is disabled in UI
    Element Should Be Disabled    xpath=//div[@id='card-VIN1003']//button[text()='LOCK']
    
    # 2. Attempt a command via API directly and verify rejection (Backend validation)
    ${data}=    Create Dictionary    command=LOCK
    ${resp}=    POST On Session    api    /vehicle/VIN1003/command    json=${data}    expected_status=403
    Should Contain    ${resp.json()['reason']}    Vehicle Offline

Scenario 6: API Edge Case - Handle Non-existent VIN
    [Documentation]    Verify API returns 404 for invalid VINs
    [Tags]    edge-case    api
    ${resp}=    GET On Session    api    /vehicle/VIN_GHOST/command-log    expected_status=404
    Should Be Equal As Strings    ${resp.json()['error']}    Vehicle Not Found

Scenario 7: API Edge Case - Unknown Command Rejection
    [Documentation]    Verify API rejects commands not in the allow-list
    [Tags]    edge-case    api
    ${data}=    Create Dictionary    command=EJECT_PILOT
    ${resp}=    POST On Session    api    /vehicle/VIN1001/command    json=${data}    expected_status=400
    Should Be Equal As Strings    ${resp.json()['reason']}    Invalid or Unknown Command

Scenario 8: Boundary Condition - Battery at Exactly 15 Percent
    [Documentation]    Verify that exactly 15% battery ALLOWS remote start (interlock is < 15)
    [Tags]    boundary    safety
    # 1. Inject 15% battery
    Inject Vehicle Alert    VIN1001    OK    battery=15
    
    # 2. Trigger Remote Start via API
    ${data}=    Create Dictionary    command=REMOTE_START
    ${resp}=    POST On Session    api    /vehicle/VIN1001/command    json=${data}
    Should Be Equal As Strings    ${resp.json()['result']}    SUCCESS

Scenario 9: Functional Flow - Alert Recovery
    [Documentation]    Verify UI transitions from ALERT (Red) back to OK (Green)
    [Tags]    functional    ui
    # 1. Start with Alert
    Inject Vehicle Alert    VIN1001    ALERT
    Open Browser    ${DASHBOARD_URL}    ${BROWSER}
    Verify Vehicle Card Status    VIN1001    ALERT
    
    # 2. Fix vehicle via API
    Inject Vehicle Alert    VIN1001    OK
    
    # 3. Verify UI turns back to OK
    Verify Vehicle Card Status    VIN1001    OK
    Capture Page Screenshot    recovery_flow.png

Scenario 10: Data Validation - Reject Negative Tire Pressure
    [Documentation]    Verify API rejects sensor data that is physically impossible
    [Tags]    edge-case    telemetry
    ${data}=    Create Dictionary    tire_pressure=-5
    ${resp}=    POST On Session    api    /vehicle/VIN1001/telemetry    json=${data}    expected_status=400
    Should Contain    ${resp.json()['error']}    Negative tire pressure

Scenario 11: Thermal Safety Interlock
    [Documentation]    Verify that overheating engine prevents remote start
    [Tags]    safety    thermal
    # 1. Set engine temp to 110C (Overheated)
    ${data}=    Create Dictionary    engine_temp=110
    POST On Session    api    /vehicle/VIN1001/telemetry    json=${data}
    
    # 2. Attempt Remote Start
    ${cmd}=    Create Dictionary    command=REMOTE_START
    ${resp}=    POST On Session    api    /vehicle/VIN1001/command    json=${cmd}    expected_status=403
    Should Contain    ${resp.json()['reason']}    Thermal Safety Interlock
