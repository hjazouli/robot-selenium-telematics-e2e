# Robot Framework Test Suite

A test suite for automated testing using Robot Framework and SeleniumLibrary.

## Setup

1. Create and activate a virtual environment (recommended):
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Install browser drivers (if not using webdriver-manager):
   - Chrome: Download from https://chromedriver.chromium.org/
   - Firefox: Download from https://github.com/mozilla/geckodriver/releases
   - Or use webdriver-manager (recommended)

## Project Structure

```
.
├── tests/              # Test suite files
│   └── example_tests.robot
├── resources/          # Resource files with keywords
│   └── common_keywords.robot
├── results/            # Test execution results (generated)
├── requirements.txt    # Python dependencies
└── README.md          # This file
```

## Running Tests

**Note:** Make sure your virtual environment is activated before running tests:
```bash
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

Run all tests:
```bash
robot tests/
```

Run specific test file:
```bash
robot tests/example_tests.robot
```

Run with specific output directory:
```bash
robot -d results tests/
```

Run with tags:
```bash
robot --include smoke tests/
```

## Test Results

After execution, results will be generated in:
- `log.html` - Detailed execution log
- `report.html` - Test execution report
- `output.xml` - Machine-readable XML output

## Tags

- `smoke` - Smoke tests
- `regression` - Regression tests
- `critical` - Critical path tests

