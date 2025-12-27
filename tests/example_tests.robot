*** Settings ***
Documentation     Example test suite for Robot Framework with Selenium
Library           SeleniumLibrary
Resource          ../resources/common_keywords.robot
Test Setup        Open Browser To Test Page
Test Teardown     Close Browser

*** Variables ***
${BROWSER}        chrome
${DELAY}          0.5

*** Test Cases ***
Example Test - Google Search
    [Documentation]    Example test case that searches on Google
    [Tags]    smoke    example
    Go To    https://www.google.com
    Wait Until Page Contains    Google
    Input Text    name=q    Robot Framework
    Press Keys    name=q    RETURN
    Wait Until Page Contains    Robot Framework
    Page Should Contain    Robot Framework

Example Test - Page Title Verification
    [Documentation]    Verify page title
    [Tags]    smoke    example
    Go To    https://www.robotframework.org
    Title Should Be    Robot Framework
    Page Should Contain    Robot Framework

Example Test - Element Visibility
    [Documentation]    Check if elements are visible
    [Tags]    regression    example
    Go To    https://www.robotframework.org
    Wait Until Element Is Visible    css:body
    Element Should Be Visible    css:body

*** Keywords ***
Open Browser To Test Page
    Open Browser    about:blank    ${BROWSER}
    Maximize Browser Window
    Set Selenium Speed    ${DELAY}

