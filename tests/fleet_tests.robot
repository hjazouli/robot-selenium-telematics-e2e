*** Settings ***
Documentation     End-to-end tests for ShieldDrive Fleet Management Portal
Library           SeleniumLibrary
Library           RequestsLibrary
Library           Collections

Suite Setup       Setup Global Variables
Test Teardown     Close Browser

*** Variables ***
${DASHBOARD_URL}    file:///Users/hichamjazouli/Projects/RobotFramework/Selenium/dashboard.html
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
    Element Should Contain    id=battery-${VIN_WITH_LOW_BATT}    12%
    
    # 2. Trigger Remote Start
    Click Button    xpath=//div[@id='card-${VIN_WITH_LOW_BATT}']//button[text()='REMOTE START']
    
    # 3. Verify rejection in UI Toast
    Wait Until Element Is Visible    id=toast    timeout=5s
    Element Should Contain    id=toast    REJECTED
    Element Should Contain    id=toast    Low Battery Safety Interlock
    
    # 4. Verify API also recorded the rejection
    ${resp}=    GET On Session    api    /vehicle/${VIN_WITH_LOW_BATT}/command-log
    ${logs}=    Set Variable    ${resp.json()}
    ${last_command}=    Get From List    ${logs}    -1
    Should Be Equal As Strings    ${last_command['result']}    REJECTED
    Capture Page Screenshot    safety_interlock_rejection.png
