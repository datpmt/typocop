# typocop.rb

require 'base64'
require 'rugged'
# require 'pry'
require 'octokit'

GITHUB_TOKEN = ENV['GITHUB_TOKEN'] || ''
PULL_ID = ENV['PULL_REQUEST_ID']
GITHUB_BASE_REF = ENV['GITHUB_BASE_REF'] || 'main'
BASE_BRANCH = GITHUB_BASE_REF.start_with?('origin/') ? GITHUB_BASE_REF : "origin/#{GITHUB_BASE_REF}"

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

  def incorrect_words
    @typos.map { |typo| typo[:incorrect_word] }
  end

  def correct_words
    @typos.map { |typo| typo[:correct_word] }
  end
end

class Comment
  attr_reader :id, :path, :line, :body, :user_login

  def initialize(id, path, line, body, user_login)
    @id = id
    @path = path
    @line = line
    @body = body
    @user_login = user_login
  end
end

def contain_incorrect_word?(content, incorrect_words)
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
  "Should replace #{comment.join(', ')}."
end

class Client
  attr_reader :pull_comments, :repo

  def initialize(repo)
    @client = Octokit::Client.new(
      api_endpoint: 'https://api.github.com/',
      web_endpoint: 'https://github.com/',
      access_token: GITHUB_TOKEN,
      auto_paginate: true
    )
    @repo = repo
    @repo_name = @repo.name

    pull_comments = @client.pull_request_comments(@repo_name, PULL_ID)
    @pull_comments = pull_comments.map do |comment|
      Comment.new(comment.id, comment.path, comment.line, comment.body, comment.user.login)
    end
  end

  def pull_request
    @pull_request ||= @client.pull_request(@repo_name, PULL_ID)
  end

  def commit_id
    @commit_id ||= pull_request.head.sha
  end

  def run(cops)
    current_cops = current_cops(cops)
    if current_cops.empty?
      delete_all_comments
      accept_pull_request
    else
      dismiss_accept_pull_request
      delete_comments(current_cops)
      create_comments(current_cops)
    end
  end

  def current_cops(cops)
    result_cops = []
    common_paths = common_paths(cops)
    common_paths.each do |path|
      patch_by_path = patch_by_path(path)
      cops_by_path = cops_by_path(cops, path)
      cops_lines = patch_by_path.added_lines.map(&:new_lineno) & cops_by_path.map(&:line)
      next if cops_lines.empty?

      result_cops.concat(cops_by_path.select { |cop| cops_lines.include?(cop.line) })
    end

    result_cops
  end

  def common_paths(cops)
    @repo.patch_additions.map(&:path) & cops.map(&:path)
  end

  def patch_by_path(path)
    @repo.patch_additions.find { |patch| patch.path == path }
  end

  def cops_by_path(cops, path)
    cops.select { |cop| cop.path == path }
  end

  def create_comments(cops)
    cops.each do |cop|
      next if exist_comment?(cop)

      line_content = line_content(cop)
      suggestion_content = suggestion_content(line_content, cop.typos)

      body = <<~BODY
        ```suggestion
        #{suggestion_content}```
        #{suggestion_comment(cop.typos)}
      BODY

      create_comment(body, cop.path, cop.line)
    end
  end

  def line_content(cop)
    patch = @repo.patch_additions.find { |patch| patch.path == cop.path }
    patch.added_lines.find { |line| line.new_lineno == cop.line }.content
  end

  def create_comment(body, path, line)
    @client.create_pull_request_comment(
      @repo_name,
      PULL_ID,
      body,
      commit_id,
      path,
      line,
      side: 'RIGHT'
    )
    puts "comment on: #{path}:#{line}"
  end

  def exist_comment?(cop)
    own_comments.any? do |comment|
      comment.path == cop.path &&
        comment.line == cop.line &&
        !(comment.body.split('`') & cop.incorrect_words).empty?
    end
  end

  def user_login
    @user_login ||= begin
      @client.user.login
    rescue Octokit::Forbidden
      'github-actions[bot]'
    end
  end

  def own_comments
    @own_comments ||= @pull_comments.select { |comment| comment.user_login == user_login }
  end

  def delete_comments(cops)
    own_comments.each do |comment|
      delete_comment(comment) if should_delete?(comment, cops)
    end
  end

  def should_delete?(comment, cops)
    cops.none? do |cop|
      cop.path == comment.path &&
        cop.line == comment.line &&
        !(cop.incorrect_words & comment.body.split('`')).empty?
    end
  end

  def delete_comment(comment)
    @client.delete_pull_comment(@repo_name, comment.id)
    puts "delete comment: #{comment.path}:#{comment.line}"
  end

  def delete_all_comments
    own_comments.each do |comment|
      delete_comment(comment)
    end
  end

  def accept_pull_request
    @client.create_pull_request_review(
      @repo_name,
      PULL_ID,
      event: 'APPROVE'
    )
  rescue Octokit::UnprocessableEntity => e
    puts e
  end

  def pull_request_reviews
    @pull_request_reviews ||= @client.pull_request_reviews(@repo_name, PULL_ID)
  end

  def own_pull_request_review
    @own_pull_request_review ||= pull_request_reviews.find do |review|
      review.state == 'APPROVED' &&
        review.user.login == user_login
    end
  end

  def dismiss_accept_pull_request
    return unless own_pull_request_review

    review_id = own_pull_request_review.id
    message = 'Found new typos.'
    @client.dismiss_pull_request_review(@repo_name, PULL_ID, review_id, message)
  end
end

class Patch
  attr_reader :path, :lines, :added_lines

  def initialize(path, lines, added_lines)
    @path = path
    @lines = lines
    @added_lines = added_lines
  end
end

class Repo
  attr_reader :patch_additions

  def initialize(path = '.')
    @repo = Rugged::Repository.new(path)
    patch_additions = diff.select { |patch| patch.additions.positive? }
    @patch_additions = patch_additions.map do |patch|
      path = patch.delta.new_file[:path]
      lines = patch.hunks.flat_map(&:lines)
      added_lines = lines.select(&:addition?)
      Patch.new(path, lines, added_lines)
    end
  end

  def name
    match = %r{(?:https?://)?(?:www\.)?github\.com[/:](?<repo_name>.*?)(?:\.git)?\z}.match(remote_url)
    match[:repo_name]
  end

  def remote_url
    @repo.remotes.first.url
  end

  def head
    @repo.head
  end

  def head_target
    head.target
  end

  def merge_base
    @repo.merge_base(BASE_BRANCH, head_target)
  end

  def diff
    @repo.diff(merge_base, head_target)
  end

  def target_id
    head.target_id
  end

  def target_oid
    head_target.oid
  end
end

typo_outputs = `typos --format brief`
typo_outputs = typo_outputs.split("\n")

if typo_outputs.empty?
  puts 'No typo output.'
else
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
  cops_data = cops.cops
  repo = Repo.new
  puts "repo.head.name: #{repo.head.name}"
  client = Client.new(repo)
  client.run(cops_data)
end
