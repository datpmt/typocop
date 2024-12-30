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
require 'typo_checker'

GITHUB_TOKEN = ENV['GITHUB_TOKEN'] || ''
PULL_ID = ENV['PULL_REQUEST_ID']
GITHUB_BASE_REF = ENV['GITHUB_BASE_REF'] || 'main'
BASE_BRANCH = GITHUB_BASE_REF.start_with?('origin/') ? GITHUB_BASE_REF : "origin/#{GITHUB_BASE_REF}"

module Typocop
  def self.execute(settings)
    excludes = settings.excludes
    skips = settings.skips
    typo_checker = TypoChecker::Checker.new(excludes, skips, stdoutput = false)
    found_typos = typo_checker.scan_repo('.')

    if found_typos.empty?
      puts 'No typos.'
    else
      cops = Cops.new(found_typos)
      repo = Repo.new
      client = Client.new(repo)
      client.execute(cops.cops)
    end
  end
end
