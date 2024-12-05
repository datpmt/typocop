# script.rb

require 'base64'
require 'rugged'
require 'pry'
require 'octokit'

encoded_typo_outputs = ENV['ENCODED_TYPO_OUTPUTS'] || 'dGVzdC9leGFtcGxlLnB5OjI0OjIwOiBgZWxsaWdpYmxlYCAtPiBgZWxpZ2libGVgCnRlc3QvZXhhbXBsZS5weToyNToyMDogYGVsbGlnaWJsZWAgLT4gYGVsaWdpYmxlYAp0ZXN0L2V4YW1wbGUucHk6MjY6MjA6IGBlbGxpZ2libGVgIC0+IGBlbGlnaWJsZWAKdGVzdC9leGFtcGxlLnJiOjM6OTogYGxhbmd1ZWdlYCAtPiBgbGFuZ3VhZ2VgCnRlc3QvZXhhbXBsZS5yYjo0Ojk6IGBrbm93bGVnZWAgLT4gYGtub3dsZWRnZWAKdGVzdC9leGFtcGxlLnJiOjU6OTogYGtub3dsZWdlYCAtPiBga25vd2xlZGdlYAoK'
@github_token = ENV['GITHUB_TOKEN'] || ''
@pull_request_id = ENV['PULL_REQUEST_ID']

def create_comment(client, repo, body, commit_id, path, line)
  client.create_pull_request_comment(
    repo,
    @pull_request_id,
    body,
    commit_id,
    path,
    line,
    side: 'RIGHT'
  )
end

class Typo
  attr_reader :path, :line, :incorrect_word, :correct_word

  def initialize(path, line, incorrect_word, correct_word)
    @path = path
    @line = line.to_i
    @incorrect_word = incorrect_word
    @correct_word = correct_word
  end
end

if encoded_typo_outputs.empty?
  puts 'No typo output.'
else
  commit = 'origin/main'
  repo = Rugged::Repository.new('.')
  head = repo.head.target
  merge_base = repo.merge_base(commit, head)
  patches = repo.diff(merge_base, head).select { |patch| patch.additions.positive? }

  client = Octokit::Client.new(access_token: @github_token)
  typo_outputs = Base64.decode64(encoded_typo_outputs).split("\n")
  typo_outputs.each do |typo_output|
    path, line_number, _column, typo_detail = typo_output.split(':')
    typo_match = /`(.*?)` -> `(.*?)`/.match(typo_detail)
    incorrect_word, correct_word = typo_match ? typo_match.captures : []
    typo = Typo.new(path, line_number, incorrect_word, correct_word)

    patches.each do |patch|
      next if patch.delta.new_file[:path] != typo.path

      lines = patch.hunks.flat_map(&:lines)
      added_lines = lines.select(&:addition?)

      added_lines.each do |line|
        next if typo.line != line.new_lineno && line.content.include?(typo.incorrect_word)

        suggestion_content = line.content.gsub(typo.incorrect_word, typo.correct_word)

        body = <<~BODY
          ```suggestion
          #{suggestion_content}
          ```
          Please check this typo. Replace `#{typo.incorrect_word}` with `#{typo.correct_word}`.
        BODY

        puts "body: #{body}"
        create_comment(client, repo, body, typo.path, typo.line)
      end
    end
  end
end
