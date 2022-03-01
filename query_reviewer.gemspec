
Gem::Specification.new do |s|
  s.name = 'query_reviewer'
  s.version = '0.2.3b'
  s.author = 'dsboulder, nesquena, SDarck'
  s.email = 'nesquena@gmail.com'
  s.homepage = 'https://github.com/Sdarck/query_reviewer'
  s.summary = 'Runs explain before each select query and displays results in an overlayed div'
  s.description = s.summary
  s.files = %w[MIT-LICENSE Rakefile README.md query_reviewer_defaults.yml] + Dir['lib/**/*']
  s.license = 'MIT'
end
