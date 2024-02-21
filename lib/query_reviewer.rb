require 'ostruct'
require 'erb'
require 'yaml'

module QueryReviewer
  CONFIGURATION = {}.freeze
  
  def self.load_configuration
    default_config = YAML.safe_load(ERB.new(File.read(File.expand_path('query_reviewer_defaults.yml', "../.."))).result)
    
    CONFIGURATION.merge!(default_config['all'] || {})
    CONFIGURATION.merge!(default_config[Rails.env || 'test'] || {})
    
    app_config_file = Rails.root.join('config/query_reviewer.yml')
    
    if File.file?(app_config_file)
      app_config = YAML.safe_load(ERB.new(File.read(app_config_file)).result)
      CONFIGURATION.merge!(app_config['all'] || {})
      CONFIGURATION.merge!(app_config[Rails.env || 'test'] || {})
    end
    
    return unless enabled?
    
    begin
      CONFIGURATION['uv'] ||= Gem::Specification.find_all_by_name('uv').any?
      require 'uv' if CONFIGURATION['uv']
    rescue StandardError
      CONFIGURATION['uv'] ||= false
    end
    
    require_relative 'query_reviewer/query_warning'
    require_relative 'query_reviewer/array_extensions'
    require_relative 'query_reviewer/sql_query'
    require_relative 'query_reviewer/mysql_analyzer'
    require_relative 'query_reviewer/sql_sub_query'
    require_relative 'query_reviewer/mysql_adapter_extensions'
    require_relative 'query_reviewer/controller_extensions'
    require_relative 'query_reviewer/sql_query_collection'
  end
  
  def self.enabled?
    CONFIGURATION['enabled']
  end
  
  def self.safe_log
    if @logger.nil?
      yield
    elsif @logger.respond_to?(:quietly)
      @logger.quietly(&block)
    elsif @logger.respond_to?(:silence)
      @logger.silence(&block)
    end
  end
end

# Rails Integration
require_relative 'query_reviewer/rails' if defined?(Rails)
