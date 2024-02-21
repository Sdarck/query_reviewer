module QueryReviewer
  module MysqlAnalyzer
    def do_mysql_analysis!
      analyze_select_type!
      analyze_query_type!
      analyze_key!
      analyze_extras!
      analyze_keylen!
    end
    
    def analyze_select_type!
      case select_type
      when /uncacheable subquery/
        warn(severity: 10, field: 'select_type', description: 'Subquery must be run once for EVERY row in main query')
      when /dependent/
        warn(severity: 2, field: 'select_type',
             description: 'Dependent subqueries cannot be executed while the main query is running')
      end
    end
    
    def analyze_query_type!
      case query_type
      when 'system', 'const', 'eq_ref'
        praise('Yay')
      when 'ref', 'ref_or_null', 'range', 'index_merge'
        praise('Not bad eh...')
      when 'unique_subquery', 'index_subquery'
        # NOT SURE
      when 'index'
        warn(severity: 8, field: 'query_type',
             description: 'Full index tree scan (slightly faster than a full table scan)') if extra.include?('using where')
      when 'all'
        warn(severity: 9, field: 'query_type', description: 'Full table scan') if extra.include?('using where')
      end
    end
    
    def analyze_key!
      if key == 'const'
        praise('Way to go!')
      elsif key.blank? &&
        !extra.include?('select tables optimized away') &&
        !extra.include?('impossible where noticed after reading const tables')
        warn(severity: 6, field: 'key',
             description: "No index was used here. In this case, that meant scanning #{rows} rows.")
      end
    end
    
    def analyze_extras!
      if extra.match?(/range checked for each record/)
        warn(severity: 4, problem: 'Range checked for each record',
             description: 'MySQL found no good index to use, but found that some of the indexes might be used after column values from preceding tables are known')
      end
      
      if extra.match?(/using filesort/)
        warn(severity: 2, problem: 'Using filesort',
             description: 'MySQL must do an extra pass to find out how to retrieve the rows in sorted order.')
      end
      
      return unless extra.match?(/using temporary/)
      
      warn(severity: 10, problem: 'Using temporary table',
           description: 'To resolve the query, MySQL needs to create a temporary table to hold the result.')
    end
    
    def analyze_keylen!
      if key_len && key_len.to_i.positive? && (key_len.to_i > QueryReviewer::CONFIGURATION['max_safe_key_length'])
        warn(severity: 4, problem: "Long key length (#{key_len.to_i})",
             description: 'The key used for the index was rather long, potentially affecting indices in memory')
      end
    end
    
  end
end
