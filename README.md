# Nu-test

A [Nushell](https://www.nushell.sh) test runner.

![An example nu-test run](resources/test-run.png)

*^ Tests are structured data that can be processed just like any other table.*

![An example nu-test run](resources/test-run-terminal.png)

*^ Terminal mode - test results appear as they complete.*


## Requirements

Nushell 0.101.0 or later.


## Motivation

Writing tests in Nushell is both powerful and expressive. Not only for testing Nushell code, but also other things, such as APIs, infrastructure, and other scripts. However, Nushell doesn't currently include a test runner for Nu scripts in the standard library. While a runner is not strictly necessary, Nutest aims to encourage writing tests for scripts by making testing more easily accessible.


## Install and Run

Note: Nu-test is fully functional but currently still in pre-1.0 development.

### Using [nupm](https://github.com/nushell/nupm)

First-time installation:

```nushell
git https://github.com/vyadh/nu-test.git
nupm install nu-test --path
```

Usage:

```nushell
cd <your project>
use nutest
nutest run-tests
```

### Standalone

First-time installation:

```nushell
git https://github.com/vyadh/nu-test.git
cp -r nu-test/nutest <a directory referenced by NU_LIB_DIRS / $env.NU_LIB_DIRS>
```

Usage:

```nushell
cd <your project>
use nutest
nutest run-tests
```


## Writing Tests

### Test Suites

A recognised test suite (a Nushell file containing tests) is recognised by nu-test is defined as a filename matching one of the following patterns somewhere within the path:
- `test_*.nu`
- `test-*.nu`
- `*_test.nu`
- `*-test.nu`

### Test Commands

**Nu-test** uses the command description as a tag system for tests, test discovery will ignore non-tagged commands. It supports:

| tag                 | description                             |
|---------------------|-----------------------------------------|
| **\[test\]**        | this is the main tag to annotate tests. | 
| **\[before-all\]**  | this is run once before all tests.      |
| **\[before-each\]** | this is run before each test.           |
| **\[after-all\]**   | this is run once after all tests.       |
| **\[after-each\]**  | this is run after each test.            |
| **\[ignore\]**      | ignores the test but still collects it. |

For example:

```nushell
use std assert

#[before-each]
def setup [] {
  print "before each"
  {
    data: "xxx"
  }
}

#[test]
def "some-data is xxx" [] {
  let context = $in
  print $"Running test A: ($context.data)"
  assert equal "xxx" $context.data
}

#[test]
def "is one equal one" [] {
  print $"Running test B: ($in.data)"
  assert equal 1 1
}

#[test]
def "is two equal two" [] {
  print $"Running test C: ($in.data)"
  assert equal 2 2
}

#[after-each]
def cleanup [] {
  let context = $in
  print "after each"
  print $context
}
```

Will return:
```
╭───────────┬──────────────────┬────────┬─────────────────────╮
│   suite   │       test       │ result │       output        │
├───────────┼──────────────────┼────────┼─────────────────────┤
│ test_base │ is one equal one │ PASS   │ before each         │
│           │                  │        │ Running test B: xxx │
│           │                  │        │ after each          │
│           │                  │        │ {data: xxx}         │
│ test_base │ is two equal two │ PASS   │ before each         │
│           │                  │        │ Running test C: xxx │
│           │                  │        │ after each          │
│           │                  │        │ {data: xxx}         │
│ test_base │ some-data is xxx │ PASS   │ before each         │
│           │                  │        │ Running test A: xxx │
│           │                  │        │ after each          │
│           │                  │        │ {data: xxx}         │
╰───────────┴──────────────────┴────────┴─────────────────────╯
```


## Current Features

- [x] Flexible test definitions
- [x] Setup/teardown with context available to tests
- [x] Filtering of the suites and tests to run
- [x] Terminal completions for suites and tests
- [x] Outputting test results in various ways, including queryable Nushell data tables
- [x] Test output captured and shown against test results
- [x] Parallel test execution and concurrency control
- [x] CI/CD support
  - [x] Non-zero exit code in the form of a `--fail` flag
  - [x] Test report integration with a wide array of tools

### Flexible Tests

Supports tests scripts in flexible configurations:
- Single file with both implementation and tests
- Separate implementation and test files
- Just test files only
  - This would commonly be the case when using Nushell to test other things, such as for testing bash scripts, APIs, infrastructure. All the things Nushell is great at.
- Nushell modules.

Nushell scripts being tested can either be utilised from their public interface as a module via `use <test-file>.nu` or testing their private interface by `source <test-file>.nu`.

### Context and Setup/Teardown

Specify before/after for each test via `[before-each]` and `[after-each]` annotations, or for all tests via `[before-all]` and `[after-all]`.

These setup/teardown commands can also be used to generate contexts used by each test, see Writing Tests section for ane example.

### Filtering Suites and Tests

Allows filter of suites and tests to run via a pattern, such as:
```nushell
run-tests --match-suites api --match-tests test[0-9]
```
This will run all files that include `api` in the name and tests that contain `test` followed by a digit.

### Completions

Completions are available not only for normal command values, they are also available for suites and tests, making it easier to run specific suites and tests from the command line.

For example, typing the following and pressing tab will show all available suites that contain the word `api`:
```nushell
run-tests --match-suites api<tab>
```

Typing the following and pressing tab will show all available tests that contain the word `parse`:
```nushell
run-tests --match-tests parse<tab>
```

While test discovery is done concurrently and quick even with many test files, you can specify `--match-suites <pattern>` before `--match-tests` to greatly reduce the amount of work nu-test needs to do to find the tests you want to run.

### Results Output

There are several ways to output test results in nutest:
- Displaying to the terminal
- Returning data for pipelines
- Reporting to file

#### Terminal Display

By default, nutest displays tests in a textual format as they complete, implicitly as `--display terminal`. This can also be displayed as a table using `--display table` at the end of the run. Examples of these two display types can be seen in the screenshots above.

Terminal output can be turned off using `--display nothing`.

#### Returning Data

No Nushell library is complete without being able to return data to query and manipulate. In nutest, you can query and manipulate the results. For example, to show only tests that need attention using:

```nushell
run-tests --returns table | where result in [SKIP, FAIL]
```

Alternatively, you can return a summary of the test run as a record using:
```nushell
run-tests --returns summary
```

Which will be shown as:
```
╭─────────┬────╮
│ total   │ 54 │
│ passed  │ 50 │
│ failed  │ 1  │
│ skipped │ 3  │
╰─────────┴────╯
```

If data is selected to be returned the display report will be turned off, but can be re-enabled by using the `--display` option explicitly.

The combination of `--display` and `--returns` can be used to be able to see the running tests and also query and manipulate the output once it is complete. It is also helpful for saving output to a file in a format not supported out of the box by the reporting functionality.

#### Reporting to File

Lastly, tests reports can be output to file. See the CI/CD Integration for more details.


### Test Output

Output from the `print` command to stdout and stderr will be captured and shown against test results, which is useful for debugging failing tests.


### Parallel Test Execution

Tests written in Nutest are run concurrently by default.

This is a good design constraint for self-contained tests that run efficiently. The default concurrency strategy is geared for CPU-bound tests, maximising the use of available CPU cores. However, some cases may need adjustment to run efficiently. For example, IO-bound tests may benefit from lower concurrency and tests waiting on external resources may benefit by not being limited to the available CPU cores.

The level of concurrency adjusted or even disabled by specifying the `--strategy { threads: <n> }` option to the `run-tests` command, where `<n>` is the number of concurrently executing machine threads. The default is handling the concurrency automatically.

See the Concurrency section under How Does It Work? for more details.

The concurrency level can also be specified at the suite-level by way of a `strategy` annotation. For example, the following strategy will run all tests in the suite sequentially:

```nushell
#[strategy]
def threads []: nothing -> record {
  { threads: 1 }
}
```

This would be beneficial in a project where most tests should run concurrently by default, but a subset perhaps require exclusive access to a resource, or one that needs resetting on a per-test basis.


### CI/CD Support

#### Exit Codes

In normal operation the tests will be run and the results will be returned as a table with the exit code always set to 0. To avoid manually checking the results, the `--fail` flag can be used to set the exit code to 1 if any tests fail. In this mode, the test results will be printed in the default format and cannot be interrogated.

```nushell
run-tests --fail
```

This is useful for CI/CD pipelines where it is desirable to fail the current
job. However, note that using this directly in your shell will exit your shell session!

### Test Report Integration

In order to integrate with CI/CD tools, such as the excellent [GitHub Action to Publish Test Results](https://github.com/EnricoMi/publish-unit-test-result-action), you can output the result in JUnit XML format. The JUnit format was chosen simply as it appears to have the widest level of support. This can be done by specifying the `--report junit` option to the `run-tests` command:

```nushell
run-tests --report { type: junit, path: "test-report.xml" }
```


## Alternatives

Nushell has its own private runner for the standard library `testing.nu`.

There is also a runner in [nupm](https://github.com/nushell/nupm), the Nushell package manager.

Both of these runners work on modules and so cannot be used for testing independent scripts. This runner is generic. It works with any Nu script, be that single files or modules.
