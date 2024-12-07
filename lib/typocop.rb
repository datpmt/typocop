require 'rugged'
# require 'pry'
require 'octokit'

require 'typocop/cli'
require 'typocop/client'
require 'typocop/comment'
require 'typocop/cop'
require 'typocop/cops'
require 'typocop/patch'
require 'typocop/repo'

GITHUB_TOKEN = ENV['GITHUB_TOKEN'] || ''
PULL_ID = ENV['PULL_REQUEST_ID']
GITHUB_BASE_REF = ENV['GITHUB_BASE_REF'] || 'main'
BASE_BRANCH = GITHUB_BASE_REF.start_with?('origin/') ? GITHUB_BASE_REF : "origin/#{GITHUB_BASE_REF}"

module Typocop
  def self.execute
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
      client = Client.new(repo)
      client.execute(cops_data)
    end
  end
end
