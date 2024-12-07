require 'thor'

module Typocop
  class CLI < Thor
    require 'typocop'
    desc 'execute', 'Run typocop'
    def execute
      Typocop.execute
    end
  end
end
