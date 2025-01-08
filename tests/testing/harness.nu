use ../../std/testing/orchestrator.nu
use ../../std/testing/reporter_table.nu
use ../../std/testing/theme.nu
use ../../std/testing/formatter.nu
use ../../std/testing/store.nu

# A harness for running tests against nutest itself.

# Encapsulate before-all behaviour
export def setup-tests [formatter?: closure]: nothing -> record {
    store create
    let formatter = $formatter | default (formatter preserved)
    let reporter = reporter_table create (theme none) $formatter
    do $reporter.start
    $in | merge {
        reporter: $reporter
    }
}

# Encapsulate after-all behaviour
export def cleanup-tests []: record<reporter: record> -> nothing {
    let reporter = $in.reporter
    do $reporter.complete
    store delete
}

# Encapsulate before-each behaviour
export def setup-test []: record -> record {
    $in | merge {
        reporter: $in.reporter
        temp_dir: (mktemp --tmpdir --directory)
    }
}

# Encapsulate after-each behaviour
export def cleanup-test []: record -> nothing {
    if $in.temp_dir? != null {
        rm --recursive $in.temp_dir
    }
}

export def run [
    code: closure
    strategy: record = {}
]: record<reporter: record, temp_dir: string> -> record<result: string, output: string> {

    let context = $in
    let temp = $context.temp_dir
    let reporter = $context.reporter
    let strategy = {threads: 1} | merge $strategy

    let test = random chars
    let suite = $code | create-closure-suite $temp $test
    [$suite] | orchestrator run-suites $reporter $strategy
    let results = do $reporter.results

    let result = $results | where test == $test
    if ($result | is-empty) {
        error make {msg: $"No results found for test: ($test)"}
    } else {
        $result | first
    }
}

def create-closure-suite [temp: string, test: string]: closure -> record {
    let path = $temp | path join $"suite.nu"
    let code = view source $in

    $"
        use std/assert
        def ($test) [] {
            do ($code)
        }
    " | save --append $path

    {
        name: "suite"
        path: $path
        tests: [{name: $test type: "test"}]
    }
}

def trim-all []: string -> string {
    $in | str trim | str replace --all --regex '[\n\t ]+' ' '
}
