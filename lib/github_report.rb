require 'date'
require 'json'
require 'octokit'
require 'pry'

class GithubReport
  def initialize(from: Date.today.to_s.delete('-'), to: Date.today.to_s.delete('-'))
    @client = Octokit::Client.new(access_token: ENV['GITHUB_REPORT_ACCESS_TOKEN'])
    # contributionsCollection の args として渡す Datetime は iso8601 に則った形式にしないといけないためこうしている
    # see https://developer.github.com/v4/object/user/#contributionscollection
    @from_date = "#{from[0..3]}-#{from[4..5]}-#{from[6..7]}T00:00:00+09:00"
    @to_date = "#{to[0..3]}-#{to[4..5]}-#{to[6..7]}T00:00:00+09:00"
  end

  def list
    contributions_collection = fetch_query.data.viewer.contributionsCollection

    grouped_issue = group_edges(contributions_collection, type: :issue)
    grouped_pr = group_edges(contributions_collection, type: :pullRequest)

    issue_and_pr = merge_issue_and_pr(grouped_issue, grouped_pr)
    puts_list(issue_and_pr)
  end

  private

  attr_reader :client, :from_date, :to_date

  def puts_list(issue_and_pr)
    issue_and_pr.each do |title, values|
      puts "\n### #{title}\n\n"
      values.each do |value|
        puts "- [#{value.node.issue.title}](#{value.node.issue.url}) #{value.node.issue.state}" if value.node.issue?
        puts "- [#{value.node.pullRequest.title}](#{value.node.pullRequest.url}) #{value.node.pullRequest.state}" if value.node.pullRequest?
      end
    end
  end

  def group_edges(contributions_collection, type:)
    contributions_collection.send("#{type}Contributions".to_sym).edges.group_by do |edge|
      edge.node.send(type).repository.nameWithOwner
    end
  end

  def merge_issue_and_pr(grouped_issue, grouped_pr)
    grouped_issue.merge(grouped_pr) do |_, issue_val, pr_val|
      issue_val + pr_val
    end
  end

  # github api からのレスポンスは Sawyer::Resource オブジェクトで、構造は Hash っぽいけどメソッド呼び出しの形でアクセスできる
  # see https://github.com/lostisland/sawyer
  # @return [Sawyer::Resource]
  def fetch_query
    query = File.read('./lib/contributionsCollection.gql')

    variables = { from_date: from_date, to_date: to_date }
    params = { query: query, variables: variables }.to_json

    client.post('/graphql', params)
  end
end

GithubReport.new(from: '20190101', to: '20190325').list
