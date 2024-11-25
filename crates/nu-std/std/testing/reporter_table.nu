# A reporter that collects results into a table

use db.nu

export def create [color_scheme: closure]: nothing -> record {
    {
        start: { db create }
        complete: { db delete }
        results: { query-results $color_scheme }
        results-all: { query-results-all $color_scheme }
        fire-result: { |row| insert-result $row }
        fire-output: { |row| insert-output $row }
    }
}

def query-results [color_scheme: closure]: nothing -> table<suite: string, test: string, result: string, output: string, error: string> {
    query-results-all $color_scheme | reject stream
}

def query-results-all [color_scheme: closure]: nothing -> table<suite: string, test: string, result: string, output: string, error: string> {
    let res = db query $color_scheme | each { |row|
        {
            suite: $row.suite
            test: $row.test
            result: (format-result $row.result $color_scheme)
            # TODO rename stder, stdout, output
            output: $row.output
            error: $row.error
            stream: $row.stream
        }
    }
    $res
}

def format-result [result: string, color_scheme: closure]: nothing -> string {
    match $result {
        "PASS" => ({ type: "pass", text: $result } | do $color_scheme)
        "SKIP" => ({ type: "skip", text: $result } | do $color_scheme)
        "FAIL" => ({ type: "fail", text: $result } | do $color_scheme)
        _ => $result
    }
}

def insert-result [row: record<suite: string, test: string, result: string>] {
    db insert-result $row
}

def insert-output [row: record<suite: string, test: string, type: string, lines: list<string>>] {
    db insert-output $row
}
