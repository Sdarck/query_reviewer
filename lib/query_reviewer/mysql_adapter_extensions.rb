module QueryReviewer
  module MysqlAdapterExtensions
    def self.prepended(base)
      base.class_eval do
        alias_method :select_without_review, :select
        alias_method :update_without_review, :update
        alias_method :insert_without_review, :insert
        alias_method :delete_without_review, :delete
      end
    end
    
    def update(sql, *args, **kwargs)
      t1 = Time.now
      result = super(sql, *args, **kwargs)
      t2 = Time.now
      
      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, 'UPDATE', result)
      
      result
    end
    
    def insert(arg1, *otherargs, **kwargs)
      t1 = Time.now
      result = super(arg1, *otherargs, **kwargs)
      t2 = Time.now
      
      sql = arg1.is_a?(String) ? arg1 : to_sql(arg1, kwargs[:binds] || [])
      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, 'INSERT')
      
      result
    end
    
    def delete(sql, *args, **kwargs)
      t1 = Time.now
      result = super(sql, *args, **kwargs)
      t2 = Time.now
      
      create_or_add_query_to_query_reviewer!(sql, nil, t2 - t1, nil, 'DELETE', result)
      
      result
    end
    
    def select(sql, *args, **kwargs)
      return super(sql, *args, **kwargs) unless query_reviewer_enabled?
      
      sql = sql.sub(/^SELECT /i, 'SELECT SQL_NO_CACHE ') if QueryReviewer::CONFIGURATION['disable_sql_cache']
      enable_profiling if QueryReviewer::CONFIGURATION['profiling']
      
      t1 = Time.now
      query_results = super(sql, *args, **kwargs)
      t2 = Time.now
      
      if @logger && query_reviewer_enabled? && sql =~ /^SELECT /i
        profile = collect_query_profile(sql, *args, **kwargs) if should_profile?(t2 - t1)
        cols = explain_query(sql, *args, **kwargs)
        duration = profile ? [t2 - t1, profile[:duration]].min : t2 - t1
        create_or_add_query_to_query_reviewer!(sql, cols, duration, profile[:profile])
      end
      
      query_results
    end
    
    private
    
    def query_reviewer_enabled?
      Thread.current['queries'].respond_to?(:find_or_create_sql_query) && Thread.current['query_reviewer_enabled']
    end
    
    def create_or_add_query_to_query_reviewer!(sql, cols, run_time, profile, command = 'SELECT', affected_rows = 1)
      return unless query_reviewer_enabled?
      
      t1 = Time.now
      Thread.current['queries'].find_or_create_sql_query(sql, cols, run_time, profile, command, affected_rows)
      t2 = Time.now
      Thread.current['queries'].overhead_time += t2 - t1
    end
    
    def enable_profiling
      execute('SET PROFILING=1')
    end
    
    def should_profile?(duration)
      use_profiling = QueryReviewer::CONFIGURATION['profiling']
      use_profiling &&= duration >= QueryReviewer::CONFIGURATION['warn_duration_threshold'].to_f / 2.0 if QueryReviewer::CONFIGURATION['production_data']
      use_profiling
    end
    
    def collect_query_profile(sql, *args, **kwargs)
      t3 = Time.now
      select_without_review(sql, *args, **kwargs)
      t4 = Time.now
      profile = select_without_review('SHOW PROFILE ALL', *args, **kwargs)
      execute('SET PROFILING=0')
      t5 = Time.now
      Thread.current['queries'].overhead_time += t5 - t3
      { duration: t4 - t3, profile: profile }
    end
    
    def explain_query(sql, *args, **kwargs)
      select_without_review("EXPLAIN #{sql}", *args, **kwargs)
    end
  end
end

# To include this module, you would prepend it to the ActiveRecord connection adapter for MySQL:
ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend(QueryReviewer::MysqlAdapterExtensions)
