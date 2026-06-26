# **Project Testing Documentation**

This project utilizes a centralized, automated test runner to validate game logic.

## **Directory Structure**

All test files must be located within the res://tests/ directory to be discovered by the automated runner. You may organize tests into subfolders (e.g., res://tests/production/, res://tests/entities/) to maintain project cleanliness.  
res://  
├── src/            \# Game source code  
└── tests/          \# All test scripts  
    ├── main\_test\_runner.gd    \# The central discovery/execution script  
    └── ...                    \# Test subfolders

## **Creating New Tests**

To add a new test file:

1. **Naming Convention:** The file must end with the suffix \_test.gd (e.g., production\_entities\_test.gd).  
2. **Implementation:** Every test script should be a Node (or inherit from one) and contain a public method named run\_tests() to execute its logic.  
3. **Encapsulation:** Avoid using \_ready() for test execution, as this may cause conflicts with the runner. Use run\_tests() instead.

### **Example Test Template**

class\_name YourTestName  
extends Node

func run\_tests() \-\> void:  
    print("Running YourTestName...")  
    \# Your assertions here  
    assert(1 \+ 1 \== 2, "Test failed description")  
    print("YourTestName passed.")

## **Running the Tests**

To execute the full test suite:

1. Open the res://tests/main\_test\_runner.gd script.  
2. Run the scene.  
3. The runner will recursively discover all \*\_test.gd files in the tests/ directory, instantiate them, and call run\_tests() on each instance.  
4. The console will display progress, and the runner will automatically quit the application upon completion.