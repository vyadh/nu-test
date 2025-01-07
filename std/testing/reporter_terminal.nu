# A reporter that collects results into a table

use store.nu

export def create [theme: closure, formatter: closure]: nothing -> record {
  {
    start: { start-suite }
    complete: { complete-suite }
    results: { [] }
    has-return-value: false
    fire-start: {|row| start-test $row }
    fire-finish: {|row| $row | complete-test $theme $formatter }
  }
}

def start-suite []: nothing -> nothing {
  print "Running tests..."
}

def complete-suite []: nothing -> nothing {
  let results = store query
  let by_result = $results | group-by result

  let total = $results | length
  let passed = $by_result | count "PASS"
  let failed = $by_result | count "FAIL"
  let skipped = $by_result | count "SKIP"

  let output = $"($total) total, ($passed) passed, ($failed) failed, ($skipped) skipped"
  print $"Test run completed: ($output)"
}

def count [key: string]: list -> int {
  $in
  | get --ignore-errors $key
  | default []
  | length
}

def start-test [row: record]: nothing -> nothing {
}

def complete-test [theme: closure, formatter: closure]: record -> nothing {
  let event = $in
  let suite = {type: "suite" text: $event.suite} | do $theme
  let test = {type: "test" text: $event.test} | do $theme

  let result = store query-test $event.suite $event.test
  if ($result | is-empty) {
    error make {msg: $"No test results found for: ($event)"}
  }
  let row = $result | first
  let formatted = format-result $row.result $theme

  if ($row.output | is-not-empty) {
    let output = $row.output | format-output $formatter
    print $"($formatted) ($suite) ($test)\n($output)"
  } else {
    print $"($formatted) ($suite) ($test)"
  }
}

def format-result [result: string, theme: closure]: nothing -> string {
  match $result {
    "PASS" => ({type: "pass" text: $result} | do $theme)
    "SKIP" => ({type: "skip" text: $result} | do $theme)
    "FAIL" => ({type: "fail" text: $result} | do $theme)
    _ => $result
  }
}

def format-output [formatter: closure]: table<stream: string, items: list<any>> -> string {
  let output = $in
  let formatted = $output | do $formatter
  if ($formatted | describe) == "string" {
    $formatted | indent
  } else {
    $formatted
  }
}

def indent []: string -> string {
  "  " + ($in | str replace --all "\n" "\n  ")
}

def success [] {
  store success
}
