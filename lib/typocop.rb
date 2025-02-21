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

GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN') { raise 'GITHUB_TOKEN is required' }
PULL_ID = ENV.fetch('PULL_REQUEST_ID') { raise 'PULL_REQUEST_ID is required' }
GITHUB_BASE_REF = ENV.fetch('GITHUB_BASE_REF') { raise 'GITHUB_BASE_REF is required' }
BASE_BRANCH = GITHUB_BASE_REF.start_with?('origin/') ? GITHUB_BASE_REF : "origin/#{GITHUB_BASE_REF}"

module Typocop
  def self.execute(settings)
    repo = Repo.new
    paths = repo.patch_additions.map(&:path)

    return unless paths.any?

    excludes = settings.excludes
    skips = settings.skips
    typo_checker = TypoChecker::Checker.new(paths: paths, excludes: excludes, skips: skips, stdoutput: false)
    found_typos = typo_checker.scan_repo('.')

    puts 'No typos found' if found_typos.empty?

    cops = Cops.new(found_typos)
    client = Client.new(repo)
    client.execute(cops.cops)
  end
end
