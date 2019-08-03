require 'date'
require 'json'
require 'octokit'
require 'pry'

class GithubReport
  # @param from [String] (e.g. '2019-01-01')
  # @param to [String] (e.g. '2019-01-31')
  def initialize(from: Date.today.to_s, to: Date.today.to_s)
    # contributionsCollection の args として渡す Datetime は iso8601 に則った形式にしないといけないためこうしている
    # see https://developer.github.com/v4/object/user/#contributionscollection
    @from_date = "#{from}T00:00:00+09:00"
    @to_date = "#{to}T00:00:00+09:00"
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

  # octokit のレスポンスは Sawyer::Resource オブジェクトで、構造は Hash っぽいけどメソッド呼び出しの形でもアクセスできる
  # 便利な反面 Hash のメソッドは持っておらず `#dig` などが使えない
  # Sawyer::Resource の仕様に依存した実装は汎用性に欠けるため、 `#to_h` して返すようにしている
  # see https://github.com/lostisland/sawyer
  # @return [Hash]
  def fetch_query
    query = File.read('./lib/contributionsCollection.gql')

    variables = { from_date: from_date, to_date: to_date }
    params = { query: query, variables: variables }.to_json

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
    grouped_issue.merge(grouped_pr) do |_, issue_val, pr_val|
      issue_val + pr_val
    end
  end

  # Issue と PR のリストを標準出力に出力する
  # @param issue_and_pr [Hash<Symbol, Array>]
  # @return [void]
  def puts_list(issue_and_pr)
    issue_and_pr.each do |title, values|
      puts "\n### #{title}\n\n"
      values.each do |value|
        type = value[:node].key?(:issue) ? :issue : :pullRequest
        target = value.dig(:node, type)

        puts "- [#{target[:title]}](#{target[:url]}) #{target[:state]}"
      end
    end
  end
end

GithubReport.new(from: Date.today.to_s, to: Date.today.to_s).list
