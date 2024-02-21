module QueryReviewer
  class SqlSubQuery
    include MysqlAnalyzer
    
    attr_reader :sql, :cols, :warnings, :parent
    
    def initialize(parent, cols)
      @parent = parent
      @warnings = []
      @cols = cols.each_with_object({}) do |obj, memo|
        memo[obj[0].to_s.downcase] = obj[1].to_s.downcase
      end
      @cols['query_type'] = @cols.delete('type')
    end
    
    def sql
      parent.sql
    end
    
    def analyze!
      @warnings = []
      adapter_name = ActiveRecord::Base.connection.instance_variable_get('@config')[:adapter]
      adapter_name = 'mysql' if adapter_name == 'mysql2'
      method_name = "do_#{adapter_name}_analysis!"
      send(method_name)
    end
    
    def table
      @table[:table]
    end
    
    private
    
    def warn(options)
      if options[:field]
        field = options.delete(:field)
        val = send(field)
        options[:problem] = "#{field.to_s.titleize}: #{val.blank? ? '(blank)' : val}"
      end
      options[:query] = self
      options[:table] = table
      @warnings << QueryWarning.new(options)
    end
    
    def praise(options)
      # no credit, only pain
    end
  end
end
