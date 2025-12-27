*** Settings ***
Documentation     Common keywords and utilities for test suites
Library           SeleniumLibrary

*** Variables ***
${DEFAULT_TIMEOUT}    10s
${DEFAULT_BROWSER}    chrome

*** Keywords ***
Open Browser To Test Page
    [Documentation]    Opens browser and navigates to test page
    [Arguments]    ${url}=about:blank    ${browser}=${DEFAULT_BROWSER}
    Open Browser    ${url}    ${browser}
    Maximize Browser Window
    Set Selenium Implicit Wait    ${DEFAULT_TIMEOUT}

Close Browser
    [Documentation]    Closes the browser
    SeleniumLibrary.Close Browser

Wait For Element And Click
    [Documentation]    Waits for element and clicks it
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    ${timeout}
    Click Element    ${locator}

Wait For Element And Input Text
    [Documentation]    Waits for element and inputs text
    [Arguments]    ${locator}    ${text}    ${timeout}=${DEFAULT_TIMEOUT}
    Wait Until Element Is Visible    ${locator}    ${timeout}
    Input Text    ${locator}    ${text}

Verify Page Contains Text
    [Documentation]    Verifies that page contains specified text
    [Arguments]    ${text}
    Wait Until Page Contains    ${text}
    Page Should Contain    ${text}

Take Screenshot On Failure
    [Documentation]    Takes a screenshot when test fails
    Run Keyword If Test Failed    Capture Page Screenshot

