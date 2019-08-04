require 'date'
require 'json'
require 'octokit'
require 'pry'

class GithubReport
  # @param options [Hash] (e.g. { from: '2019-01-01', to: '2019-01-31' })
  def initialize(options = {})
    @from_date = options[:from] || Date.today.to_s
    @to_date = options[:to] || Date.today.to_s
    @client = Octokit::Client.new(access_token: ENV['GITHUB_REPORT_ACCESS_TOKEN'])
  end

  def list
    contributions = fetch_query.dig(:data, :viewer, :contributionsCollection)

    grouped_issue = group_edges(contributions, type: :issue)
    grouped_pr = group_edges(contributions, type: :pullRequest)

    issue_and_pr = merge_issue_and_pr(grouped_issue, grouped_pr)
    puts_list(issue_and_pr)
  end

  private

  attr_reader :client, :from_date, :to_date

  # octokit のレスポンスである Sawyer::Resource オブジェクトの仕様に依存した実装は汎用性に欠けるため、 `#to_h` して返すようにしている
  #   以下、 Sawyer::Resource の特徴
  #   - 構造は Hash っぽいけどメソッド呼び出しの形でも Value にアクセスできる
  #   - Hash のメソッドは持っておらず `Hash#dig` などが使えない
  #   see https://github.com/lostisland/sawyer
  # @return [Hash]
  def fetch_query
    query = File.read('./lib/contributionsCollection.gql')

    # contributionsCollection の args として渡す Datetime は iso8601 に則った形式にしないといけないためこうしている
    # see https://developer.github.com/v4/object/user/#contributionscollection
    variables = { from_date_time: "#{from_date}T00:00:00+09:00", to_date_time: "#{to_date}T00:00:00+09:00" }
    params = { query: query, variables: variables }.to_json

    # Sawyer::Resource が返ってくる
    response = client.post('/graphql', params)
    response.to_h
  end

  # @param contributions [Hash]
  # @param type [Symbol] :issue or :pullRequest
  # @return [Hash<Symbol, Array>] レポジトリ名でグルーピングした Hash を返す
  # @todo type（:issue or :pullRequest）の動的な判定が `#puts_list` の中にもあるので、共通化できそうならする
  #   - pullRequestReviewContributions も取得したいとなった場合は共通化必須
  #   - `Hash#transform_keys` を使って :issue, :pullRequest, :pullRequestReview の違いを吸収するようなイメージ
  def group_edges(contributions, type:)
    contributions.dig("#{type}Contributions".to_sym, :edges).group_by do |edge|
      edge.dig(:node, type, :repository, :nameWithOwner)
    end
  end

  # @param grouped_issue [Hash<Symbol, Array>]
  # @param grouped_pr [Hash<Symbol, Array>]
  # @return [Hash<Symbol, Array>]
  def merge_issue_and_pr(grouped_issue, grouped_pr)
    grouped_issue.merge(grouped_pr) do |_key, issue_val, pr_val|
      issue_val + pr_val
    end
  end

  # @param issue_and_pr [Hash<Symbol, Array>]
  # @return [void]
  def puts_list(issue_and_pr)
    issue_and_pr.each do |title, values|
      puts "\n### #{title}\n\n"
      values.each do |value|
        type = value[:node].key?(:issue) ? :issue : :pullRequest
        target = value.dig(:node, type)

        puts "- [#{target[:title]}](#{target[:url]}) **#{target[:state].downcase}!**"
      end
    end
  end
end

GithubReport.new(from: ARGV[0], to: ARGV[1]).list
