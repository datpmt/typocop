module Typocop
  class Cops
    attr_reader :path, :line, :cops

    def initialize(cops_data)
      @cops = cops_data.map do |data|
        Cop.new(data[:path], data[:line], data[:typos])
      end
    end
  end
end
