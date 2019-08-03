require 'date'
require 'json'
require 'octokit'
require 'pry'

class GithubReport
  def initialize(from: Date.today.to_s, to: Date.today.to_s)
    @client = Octokit::Client.new(access_token: ENV['GITHUB_REPORT_ACCESS_TOKEN'])
    # contributionsCollection の args として渡す Datetime は iso8601 に則った形式にしないといけないためこうしている
    # see https://developer.github.com/v4/object/user/#contributionscollection
    @from_date = "#{from}T00:00:00+09:00"
    @to_date = "#{to}T00:00:00+09:00"
  end

  def list
    contributions = fetch_query.data.viewer.contributionsCollection

    grouped_issue = group_edges(contributions, type: :issue)
    grouped_pr = group_edges(contributions, type: :pullRequest)

    issue_and_pr = merge_issue_and_pr(grouped_issue, grouped_pr)
    puts_list(issue_and_pr)
  end

  private

  attr_reader :client, :from_date, :to_date

  # github api からのレスポンスは Sawyer::Resource オブジェクトで、構造は Hash っぽいけどメソッド呼び出しの形でアクセスできる
  # see https://github.com/lostisland/sawyer
  # @return [Sawyer::Resource]
  def fetch_query
    query = File.read('./lib/contributionsCollection.gql')

    variables = { from_date: from_date, to_date: to_date }
    params = { query: query, variables: variables }.to_json

    client.post('/graphql', params)
  end

  # @param contributions [Hash]
  # @param type [Symbol] :issue or :pullRequest
  # @return [Hash<Array>] Value の Array をレポジトリ名でグルーピングした Hash を返す
  def group_edges(contributions, type:)
    contributions.send("#{type}Contributions".to_sym).edges.group_by do |edge|
      edge.node.send(type).repository.nameWithOwner
    end
  end

  # @param grouped_issue [Hash<Array>]
  # @param grouped_pr [Hash<Array>]
  # @return [Hash<Array>]
  def merge_issue_and_pr(grouped_issue, grouped_pr)
    grouped_issue.merge(grouped_pr) do |_, issue_val, pr_val|
      issue_val + pr_val
    end
  end

  # Issue と PR のリストを標準出力に出力する
  # @param issue_and_pr [Hash<Array>]
  # @return [void]
  def puts_list(issue_and_pr)
    issue_and_pr.each do |title, values|
      puts "\n### #{title}\n\n"
      values.each do |value|
        puts "- [#{value.node.issue.title}](#{value.node.issue.url}) #{value.node.issue.state}" if value.node.issue?
        puts "- [#{value.node.pullRequest.title}](#{value.node.pullRequest.url}) #{value.node.pullRequest.state}" if value.node.pullRequest?
      end
    end
  end
end

GithubReport.new(from: Date.today.to_s, to: Date.today.to_s).list
