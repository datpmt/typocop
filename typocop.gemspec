Gem::Specification.new do |s|
  s.name        = 'typocop'
  s.version     = '0.1.1'
  s.summary     = 'Comment on PRs with typos or approvals'
  s.description = "Typocop integrates with GitHub Actions to automatically comment on pull requests when typos are detected or when a PR is approved, based on [Crate CI's Typos](https://github.com/crate-ci/typos)."
  s.authors     = ['datpmt']
  s.email       = 'datpmt.2k@gmail.com'
  s.files       = Dir['CHANGELOG.md', 'LICENSE', 'README.md', 'lib/**/*', 'bin/*']
  s.homepage    =
    'https://rubygems.org/gems/typocop'
  s.license = 'MIT'
  s.metadata = {
    'source_code_uri' => 'https://github.com/datpmt/typocop',
    'changelog_uri' => 'https://github.com/datpmt/typocop/blob/main/CHANGELOG.md'
  }
  s.add_dependency 'octokit', '9.2.0'
  s.add_dependency 'rugged', '~> 1.6.3'
  s.add_dependency 'thor', '~> 1.3.2'
  s.executables = %w[typocop]
  s.files.each do |file|
    next unless file.start_with?('bin/')

    File.chmod(0o755, file) unless File.executable?(file)
  end
end
