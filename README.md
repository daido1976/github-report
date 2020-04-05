# github-report

Print GitHub contributions for a given date range.

I refered to the following library.

- https://github.com/masutaka/github-nippou
- https://github.com/zenoplex/github-summary
- https://github.com/kogai/github-geppou

## Usage

Set [`GITHUB_REPORT_ACCESS_TOKEN`](https://github.com/settings/tokens) into environment variables.

```sh
# Print contributions for specified date range when given.
$ bundle exec ruby lib/github_report.rb 2019-01-01 2019-01-31

# Print today's contributions if not given.
$ bundle exec ruby lib/github_report.rb
```
