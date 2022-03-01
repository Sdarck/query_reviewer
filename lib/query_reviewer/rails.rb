
require 'query_reviewer'

module QueryReviewer
  def self.inject_reviewer
    # Load adapters
    ActiveRecord::Base
    if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
      adapter_class = ActiveRecord::ConnectionAdapters::MysqlAdapter
    end
    if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      adapter_class = ActiveRecord::ConnectionAdapters::Mysql2Adapter
    end
    adapter_class&.send(:include, QueryReviewer::MysqlAdapterExtensions)
    # Load into controllers
    ActionController::Base.include QueryReviewer::ControllerExtensions
    Array.include QueryReviewer::ArrayExtensions
    if ActionController::Base.respond_to?(:append_view_path)
      ActionController::Base.append_view_path("#{File.dirname(__FILE__)}/lib/query_reviewer/views")
    end
  end
end

if defined?(Rails::Railtie)
  module QueryReviewer
    class Railtie < Rails::Railtie
      rake_tasks do
        load "#{File.dirname(__FILE__)}/tasks.rb"
      end

      initializer 'query_reviewer.initialize' do
        QueryReviewer.load_configuration

        QueryReviewer.inject_reviewer if QueryReviewer.enabled?
      end
    end
  end
else # Rails 2
  QueryReviewer.load_configuration

  QueryReviewer.inject_reviewer if QueryReviewer.enabled?
end
