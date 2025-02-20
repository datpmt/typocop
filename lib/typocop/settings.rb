require 'yaml'

module Typocop
  class Settings
    attr_reader :excludes, :skips

    def initialize(setting_path)
      @settings = load_settings(setting_path)
      @excludes = @settings['excludes'] || []
      @skips = @settings['skips'] || []
    end

    private

    def load_settings(setting_path)
      YAML.load_file(setting_path)
    rescue StandardError => e
      puts "Error loading YAML file: #{e.message}"
      {}
    end
  end
end
