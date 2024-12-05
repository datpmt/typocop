# typocop.rb

require 'base64'
require 'rugged'
# require 'pry'
require 'octokit'

@github_token = ENV['GITHUB_TOKEN'] || ''
@pull_request_id = ENV['PULL_REQUEST_ID']
@commit_id = ENV['COMMIT_ID']
@github_base_ref = ENV['GITHUB_BASE_REF'] || 'main'

puts "@commit_id: #{@commit_id}"

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

class Cops
  attr_reader :path, :line, :cops

  def initialize(cops_data)
    @cops = cops_data.map do |data|
      Cop.new(data[:path], data[:line], data[:typos])
    end
  end
end

class Cop
  attr_reader :path, :line, :typos

  def initialize(path, line, typos)
    @path = path
    @line = line
    @typos = typos
  end
end

typo_outputs = `typos --format brief`
typo_outputs = typo_outputs.split("\n")

result = typo_outputs.each_with_object({}) do |output, hash|
  path, line, _column, typo_detail = output.split(':')
  typo_match = /`(.*?)` -> `(.*?)`/.match(typo_detail)
  incorrect_word, correct_word = typo_match ? typo_match.captures : []

  path = path.start_with?('./') ? path[2..] : path
  line = line.to_i

  hash[path] ||= {}

  hash[path][:typos] ||= []

  existing_entry = hash[path][:typos].find { |typo| typo[:line] == line }

  if existing_entry
    existing_entry[:typos] << { incorrect_word: incorrect_word, correct_word: correct_word }
  else
    hash[path][:typos] << { line: line, typos: [{ incorrect_word: incorrect_word, correct_word: correct_word }] }
  end
end

result = result.map do |path, data|
  data[:typos].map do |entry|
    { path: path, line: entry[:line], typos: entry[:typos] }
  end
end.flatten

cops = Cops.new(result)

def contain_incorrect_word?(content, typos)
  incorrect_words = typos.map { |typo| typo[:incorrect_word] }
  incorrect_words.any? { |incorrect_word| content.include?(incorrect_word) }
end

def suggestion_content(content, typos)
  typos.each do |typo|
    content.gsub!(typo[:incorrect_word], typo[:correct_word])
  end
  content
end

def suggestion_comment(typos)
  comment = typos.map do |typo|
    "`#{typo[:incorrect_word]}` with `#{typo[:correct_word]}`"
  end
  "Replace #{comment.join(', ')}."
end

if typo_outputs.empty?
  puts 'No typo output.'
else
  repo = Rugged::Repository.new('.')
  head = repo.head.target
  base_branch = @github_base_ref.start_with?('origin/') ? @github_base_ref : "origin/#{@github_base_ref}"
  merge_base = repo.merge_base(base_branch, head)
  patches = repo.diff(merge_base, head).select { |patch| patch.additions.positive? }

  client = Octokit::Client.new(access_token: @github_token)
  puts "repo.head.target_id: #{repo.head.target_id}"
  puts "repo.head.target.oid: #{repo.head.target.oid}"
  puts "head.oid: #{head.oid}"
  cops.cops.each do |cop|
    patches.each do |patch|
      next if patch.delta.new_file[:path] != cop.path

      lines = patch.hunks.flat_map(&:lines)
      added_lines = lines.select(&:addition?)

      added_lines.each do |line|
        next if cop.line != line.new_lineno || !contain_incorrect_word?(line.content, cop.typos)

        suggestion_content = suggestion_content(line.content, cop.typos)

        body = <<~BODY
          ```suggestion
          #{suggestion_content}```
          #{suggestion_comment(cop.typos)}
        BODY

        puts "body: #{body}"
        puts "comment on: #{cop.path}:#{cop.line}"
        repo_remote_url = repo.remotes.first.url
        match = %r{(?:https?://)?(?:www\.)?github\.com[/:](?<repo_name>.*?)(?:\.git)?\z}.match(repo_remote_url)
        repo_name = match[:repo_name]
        # create_comment(client, repo_name, body, @commit_id, typo.path, typo.line)
      end
    end
  end
end
