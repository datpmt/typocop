module Typocop
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
end
