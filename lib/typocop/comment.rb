module Typocop
  class Comment
    attr_reader :id, :path, :line, :body, :user_login

    def initialize(id, path, line, body, user_login)
      @id = id
      @path = path
      @line = line
      @body = body
      @user_login = user_login
    end
  end
end
