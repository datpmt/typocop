module Typocop
  class Repo
    attr_reader :patch_additions

    def initialize(path = '.')
      @repo = Rugged::Repository.new(path)
      patch_additions = diff.select { |patch| patch.additions.positive? }
      @patch_additions = patch_additions.map do |patch|
        path = patch.delta.new_file[:path]
        lines = patch.hunks.flat_map(&:lines)
        added_lines = lines.select(&:addition?)
        Patch.new(path, lines, added_lines)
      end
    end

    def name
      match = %r{(?:https?://)?(?:www\.)?github\.com[/:](?<repo_name>.*?)(?:\.git)?\z}.match(remote_url)
      match[:repo_name]
    end

    def remote_url
      @repo.remotes.first.url
    end

    def head
      @repo.head
    end

    def head_target
      head.target
    end

    def merge_base
      @repo.merge_base(BASE_BRANCH, head_target)
    end

    def diff
      @repo.diff(merge_base, head_target)
    end

    def target_id
      head.target_id
    end

    def target_oid
      head_target.oid
    end
  end
end
