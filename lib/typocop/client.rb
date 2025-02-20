module Typocop
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

    def execute(cops)
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

    private

    def pull_request
      @pull_request ||= @client.pull_request(@repo_name, PULL_ID)
    end

    def commit_id
      @commit_id ||= pull_request.head.sha
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

    def line_content(cop)
      patch = @repo.patch_additions.find { |p| p.path == cop.path }
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
      puts "create comment: #{path}:#{line}"
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
        event: 'APPROVE',
        body: 'Checked for typos — Everything looks great! :star: :tada: :sparkles:'
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
end
