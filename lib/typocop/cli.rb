require 'thor'
require_relative 'settings'

module Typocop
  class CLI < Thor
    require 'typocop'
    method_option :config, type: :string, default: '.github/typocop/setting.yml', aliases: '-c', desc: 'Load setting.'

    desc 'execute', 'Run typocop'
    def execute
      settings = Settings.new(options[:config])
      Typocop.execute(settings)
    end
  end
end
