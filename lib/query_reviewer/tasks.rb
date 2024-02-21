namespace :query_reviewer do
  desc 'Create a default config/query_reviewer.yml'
  task :setup do
    defaults_path = File.expand_path('query_reviewer_defaults.yml', __dir__)
    dest_path = Rails.root.join('config', 'query_reviewer.yml')
    FileUtils.cp(defaults_path, dest_path)
  end
end
