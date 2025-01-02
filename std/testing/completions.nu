export def "nu-complete reporter" []: nothing -> record<options: record, completions: table<value: string, description: string>> {
    {
        options: {
            sort: false
        }
        completions: [
            [value description];
            [
                "terminal"
                "Output test results as they complete as text. (default)"
            ]
            [
                "table-pretty"
                "A table listing all tests with decorations and color."
            ]
            [
                "table"
                "A table listing all test results as data, useful for querying."
            ]
            [
                "summary"
                "A table with the total tests passed/failed/skipped."
            ]
        ]
    }
}

export def "nu-complete formatter" []: nothing -> record<options: record, completions: table<value: string, description: string>> {
    {
        options: {
            sort: false
        }
        completions: [
            [value description];
            [
                "preserved"
                "Output full output information including stream metadata."
            ]
            [
                "unformatted"
                "Show the original data output with original typing, each item in a list."
            ]
            [
                "pretty"
                "Format all output as text, with `stderr` text highlighted and errors in their rendered form."
            ]
        ]
    }
}

export def "nu-complete suites" [context: string]: nothing -> list<string> {
    use discover.nu

    # todo use a regex match to narrow the suites using 'like'
    # todo might be worth moving filtering to discovery to help share logic
    # todo and split filtering of suites and tests into separate functions

    # todo need to process command line arguments to pick up the arguments:
    # --match-suites (anything specified)
    # --path (to use with list-files)

    # todo we should also use this --match-suites to filter the tests doing completion for --match-tests

    let suites = discover list-files "."
        | each { path parse | get stem }

    #print ($context | split words)
    $suites
}
