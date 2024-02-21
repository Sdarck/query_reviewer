require 'query_reviewer'

module QueryReviewer
  def self.inject_reviewer
    # Load adapters
    ActiveRecord::Base
    if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      adapter_class = ActiveRecord::ConnectionAdapters::Mysql2Adapter
      adapter_class&.send(:include, QueryReviewer::MysqlAdapterExtensions)
    end
    
    # Load into controllers
    ActionController::Base.include QueryReviewer::ControllerExtensions
    Array.include(QueryReviewer::ArrayExtensions)
    
    # Update view path
    ActionController::Base.prepend_view_path("#{File.dirname(__FILE__)}/lib/query_reviewer/views")
  end
end

module QueryReviewer
  class Railtie < Rails::Railtie
    rake_tasks do
      load "#{File.dirname(__FILE__)}/tasks.rb"
    end
    
    config.after_initialize do
      QueryReviewer.load_configuration
      QueryReviewer.inject_reviewer if QueryReviewer.enabled?
    end
  end
end
