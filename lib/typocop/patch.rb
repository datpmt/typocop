module Typocop
  class Patch
    attr_reader :path, :lines, :added_lines

    def initialize(path, lines, added_lines)
      @path = path
      @lines = lines
      @added_lines = added_lines
    end
  end
end
