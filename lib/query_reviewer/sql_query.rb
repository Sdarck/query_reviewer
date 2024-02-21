module QueryReviewer
  class SqlQuery
    attr_reader :sqls, :rows, :subqueries, :trace, :id, :command, :affected_rows, :profiles, :durations, :sanitized_sql
    
    @@next_id = 1
    
    class << self
      def next_id
        @@next_id
      end
      
      def next_id=(value)
        @@next_id = value
      end
      
      def generate_full_trace(trace = Kernel.caller)
        trace.map(&:strip).reject { |t| t.starts_with?("#{Rails.root}/vendor/plugins/query_reviewer") }
      end
      
      def sanitize_strings_and_numbers_from_sql(sql)
        new_sql = sql.dup
        new_sql = new_sql.to_sql if new_sql.respond_to?(:to_sql)
        new_sql.gsub!(/\b\d+\b/, 'N')
        new_sql.gsub!(/\b0x[0-9A-Fa-f]+\b/, 'N')
        new_sql.gsub!(/''/, "'S'")
        new_sql.gsub!(/""/, '"S"')
        new_sql.gsub!(/\\'/, '')
        new_sql.gsub!(/\\"/, '')
        new_sql.gsub!(/'[^']+'/, "'S'")
        new_sql.gsub!(/"[^"]+"/, '"S"')
        new_sql
      end
    end
    
    def initialize(sql, rows, full_trace, duration = 0.0, profile = nil, command = 'SELECT', affected_rows = 1, sanitized_sql = nil)
      @trace = full_trace
      @rows = rows
      @sqls = [sql]
      @sanitized_sql = sanitized_sql || self.class.sanitize_strings_and_numbers_from_sql(sql)
      @subqueries = rows ? rows.map { |row| SqlSubQuery.new(self, row) } : []
      @id = (self.class.next_id += 1)
      @profiles = profile ? [profile.map { |p| OpenStruct.new(p) }] : [nil]
      @durations = [duration.to_f]
      @warnings = []
      @command = command
      @affected_rows = affected_rows
    end
    
    def add(sql, duration, profile)
      sqls << sql
      durations << duration.to_f
      profiles << (profile ? profile.map { |p| OpenStruct.new(p) } : nil)
    end
    
    def sql
      sqls.first
    end
    
    def count
      durations.size
    end
    
    def profile
      profiles.first
    end
    
    def duration
      durations.sum
    end
    
    def duration_stats
      format('TOTAL:%<total>.3f  AVG:%<avg>.3f  MAX:%<max>.3f  MIN:%<min>.3f',
             total: duration,
             avg: durations.sum / durations.size,
             max: durations.max,
             min: durations.min)
    end
    
    def to_table
      rows.map(&:qa_columnized)
    end
    
    def warnings
      subqueries.flat_map(&:warnings) + @warnings
    end
    
    def has_warnings?
      warnings.any?
    end
    
    def max_severity
      warnings.map(&:severity).max || 0
    end
    
    def table
      @subqueries.first&.table
    end
    
    def analyze!
      subqueries.each(&:analyze!)
      check_duration
      check_affected_rows
    end
    
    def to_hash
      sql.hash
    end
    
    def relevant_trace
      trace.map(&:strip).select do |t|
        t.start_with?(Rails.root.to_s) &&
          (!t.start_with?("#{Rails.root}/vendor") || QueryReviewer::CONFIGURATION['trace_includes_vendor']) &&
          (!t.start_with?("#{Rails.root}/lib") || QueryReviewer::CONFIGURATION['trace_includes_lib']) &&
          !t.start_with?("#{Rails.root}/vendor/plugins/query_reviewer")
      end
    end
    
    def full_trace
      self.class.generate_full_trace(trace)
    end
    
    def warn(options)
      options[:query] = self
      options[:table] ||= table
      @warnings << QueryWarning.new(options)
    end
    
    def select?
      command == 'SELECT'
    end
    
    private
    
    def check_duration
      if duration >= QueryReviewer::CONFIGURATION['critical_duration_threshold']
        warn(problem: "Query took #{duration} seconds", severity: 9)
      elsif duration >= QueryReviewer::CONFIGURATION['warn_duration_threshold']
        warn(problem: "Query took #{duration} seconds",
             severity: QueryReviewer::CONFIGURATION['critical_severity'])
      end
    end
    
    def check_affected_rows
      if affected_rows >= QueryReviewer::CONFIGURATION['critical_affected_rows']
        warn(problem: "#{affected_rows} rows affected", severity: 9,
             description: 'An UPDATE or DELETE query can be slow and lock tables if it affects many rows.')
      elsif affected_rows >= QueryReviewer::CONFIGURATION['warn_affected_rows']
        warn(problem: "#{affected_rows} rows affected",
             severity: QueryReviewer::CONFIGURATION['critical_severity'], description: 'An UPDATE or DELETE query can be slow and lock tables if it affects many rows.')
      end
    end
  end
end
