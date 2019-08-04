# github-report

Print GitHub contributions for a given date range.

I refered to the following library.

- https://github.com/masutaka/github-nippou
- https://github.com/zenoplex/github-summary
- https://github.com/kogai/github-geppou

## Usage

Set `GITHUB_REPORT_ACCESS_TOKEN` into environment variables.

```sh
# Print contributions for specified date range when given.
$ bundle exec ruby lib/github_report.rb 2019-01-01 2019-01-31

### daido1976/jobcan-checker-script

- [Introduce docker](https://github.com/daido1976/jobcan-checker-script/pull/7) MERGED
- [Bundle update](https://github.com/daido1976/jobcan-checker-script/pull/9) MERGED

### daido1976/github-report

- [Init app](https://github.com/daido1976/github-report/pull/1) MERGED
- [Implement GitHubReport](https://github.com/daido1976/github-report/pull/2) MERGED
- [[Refactor] Goodbye Sawyer::Resource](https://github.com/daido1976/github-report/pull/3) OPEN

# Print today's contributions if not given.
$ bundle exec ruby lib/github_report.rb

### daido1976/github-report

- [[Refactor] Goodbye Sawyer::Resource](https://github.com/daido1976/github-report/pull/3) OPEN
```
