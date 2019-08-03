require 'date'
require 'json'
require 'octokit'
require 'pry'

client = Octokit::Client.new(login: ENV['GITHUB_REPORT_USER'], access_token: ENV['GITHUB_REPORT_ACCESS_TOKEN'])

query = <<~GRAPHQL
  query($from_date: DateTime!, $to_date: DateTime!) {
    viewer {
      contributionsCollection(from: $from_date, to: $to_date) {
        issueContributions(last: 100) {
          edges {
            node {
              issue {
                title
                url
                state
                repository {
                  nameWithOwner
                }
              }
            }
          }
        }
        pullRequestContributions(last: 100) {
          edges {
            node {
              pullRequest {
                title
                url
                state
                repository {
                  nameWithOwner
                }
              }
            }
          }
        }
      }
    }
  }
GRAPHQL

var = { from_date: DateTime.iso8601('2019-01-01T00:00:00+09:00'), to_date: DateTime.iso8601('2019-03-25T00:00:00+09:00') }

param = { query: query, variables: var }.to_json

r = client.post('/graphql', param)
grouped_issue = r.data.viewer.contributionsCollection.issueContributions.edges.group_by { |edge| edge.node.issue.repository.nameWithOwner }
grouped_pr = r.data.viewer.contributionsCollection.pullRequestContributions.edges.group_by { |edge| edge.node.pullRequest.repository.nameWithOwner }

puts 'Issues'
grouped_issue.each do |title, values|
  puts "\n### #{title}\n\n"
  values.each do |val|
    puts "- [#{val.node.issue.title}](#{val.node.issue.url}) #{val.node.issue.state}"
  end
end

puts
puts 'PRs'
grouped_pr.each do |title, values|
  puts "\n### #{title}\n\n"
  values.each do |val|
    puts "- [#{val.node.pullRequest.title}](#{val.node.pullRequest.url}) #{val.node.pullRequest.state}"
  end
end
