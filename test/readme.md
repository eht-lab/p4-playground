# How to use test scripts

## Complete Workflow

- Run `test.sh` to execute test cases
  - Enter the simulator runtime environment
  - Traverse each case under tuna/app, or enter a specified case
  - Run the test case
```bash
./test.sh
```

## Simulator testing

`test.sh` is a test case running script that uses mininet + bmv2 for simulator testing

### Features

- Supports running all test cases
- Supports running a single test case

### Usage

#### Dispaly usage

```bash
# Display usage for test.sh
./test.sh help
```

#### Run all test cases (default behavior)

```bash
# Call without parameters to run all test cases
./test.sh
```

#### Run a single test case

```bash
# Call with parameters to run a single simulator test case
# The first parameter is the directory where the test case is located
# The second parameter is the test case name
./test.sh app l3_forward
```
