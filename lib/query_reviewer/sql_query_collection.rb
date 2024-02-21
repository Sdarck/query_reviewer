module QueryReviewer
  class SqlQueryCollection
    COMMANDS = %w[SELECT DELETE INSERT UPDATE].freeze
    
    attr_reader :query_hash
    attr_accessor :overhead_time
    
    def initialize(query_hash = {})
      @query_hash = query_hash
      @overhead_time = 0.0
      @warnings = []
    end
    
    def queries
      query_hash.values
    end
    
    def total_duration
      queries.sum(&:duration)
    end
    
    def query_count
      queries.sum(&:count)
    end
    
    def analyze!
      queries.each(&:analyze!)
      
      crit_severity = 9
      warn_severity = QueryReviewer::CONFIGURATION['critical_severity'] - 1
      
      COMMANDS.each do |command|
        count = count_of_command(command)
        if count > QueryReviewer::CONFIGURATION["critical_#{command.downcase}_count"]
          warn(severity: crit_severity, problem: "#{count} #{command} queries on this page",
               description: "Too many #{command} queries can severely slow down a page")
        elsif count > QueryReviewer::CONFIGURATION["warn_#{command.downcase}_count"]
          warn(severity: warn_severity, problem: "#{count} #{command} queries on this page",
               description: "Too many #{command} queries can slow down a page")
        end
      end
    end
    
    def find_or_create_sql_query(sql, cols, run_time, profile, command, affected_rows)
      sanitized_sql = SqlQuery.sanitize_strings_and_numbers_from_sql(sql)
      trace = SqlQuery.generate_full_trace(Kernel.caller)
      key = [sanitized_sql, trace]
      query_hash[key] ||= SqlQuery.new(sql, cols, trace, run_time, profile, command, affected_rows, sanitized_sql)
      query_hash[key].add(sql, run_time, profile)
    end
    
    def warn(options)
      @warnings << QueryWarning.new(options)
    end
    
    def warnings
      queries.flat_map(&:warnings).sort_by(&:severity).reverse
    end
    
    def without_warnings
      queries.reject(&:has_warnings?).sort_by(&:duration).reverse
    end
    
    def collection_warnings
      @warnings
    end
    
    def max_severity
      [warnings.collect(&:severity).max, collection_warnings.collect(&:severity).max].compact.max.to_i
    end
    
    def only_of_command(command, only_no_warnings: false)
      qs = only_no_warnings ? without_warnings : queries
      qs.select { |q| q.command == command }
    end
    
    def count_of_command(command, only_no_warnings: false)
      only_of_command(command, only_no_warnings: only_no_warnings).sum { |q| q.durations.size }
    end
    
    def total_severity
      warnings.sum(&:severity)
    end
    
    def total_with_warnings
      queries.count(&:has_warnings?)
    end
    
    def total_without_warnings
      queries.count { |q| !q.has_warnings? }
    end
    
    def percent_with_warnings
      return 0 if queries.empty?

      (100.0 * total_with_warnings / queries.size).to_i
    end
    
    def percent_without_warnings
      return 0 if queries.empty?

      (100.0 * total_without_warnings / queries.size).to_i
    end
  end
end
