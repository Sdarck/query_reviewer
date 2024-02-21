Gem::Specification.new do |s|
  s.name = 'query_reviewer'
  s.version = '0.2.4'
  s.authors = ['dsboulder', 'nesquena', 'SDarck']
  s.email = 'it-a@apismedia.pro'
  s.homepage = 'https://github.com/Sdarck/query_reviewer'
  s.summary = 'Runs explain before each select query and displays results in an overlayed div'
  s.description = s.summary
  s.files = %w[MIT-LICENSE Rakefile README.md query_reviewer_defaults.yml] + Dir['lib/**/*']
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.6.6'
  s.add_dependency 'rails', '>= 6.0'
  s.add_development_dependency 'rake'
  s.metadata = {
    'source_code_uri' => 'https://github.com/Sdarck/query_reviewer',
    'bug_tracker_uri' => 'https://github.com/Sdarck/query_reviewer/issues'
  }
end
