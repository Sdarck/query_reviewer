module QueryReviewer
  module Views
    module QueryReviewBoxHelper
      def parent_div_class
        "sql_#{parent_div_status.downcase}"
      end
      
      def parent_div_status
        if !enabled_by_cookie
          'DISABLED'
        elsif overall_max_severity < QueryReviewer::CONFIGURATION.fetch('warn_severity', 4)
          'OK'
        elsif overall_max_severity < QueryReviewer::CONFIGURATION.fetch('critical_severity', 7)
          'WARNING'
        else
          'CRITICAL'
        end
      end
      
      def syntax_highlighted_sql(sql)
        sql = sql.to_sql if sql.respond_to?(:to_sql)
        if QueryReviewer::CONFIGURATION.fetch('uv', false)
          uv_out = Uv.parse(sql, 'xhtml', 'sql_rails', false, 'blackboard')
          uv_out.gsub('<pre class="blackboard">', '<code class="sql">').gsub('</pre>', '</code>')
        else
          CGI.escapeHTML(sql)
        end
      end
      
      def overall_max_severity
        queries_with_warnings_sorted_nonignored.first&.max_severity ||
          warnings_no_query_sorted.first&.severity || 0
      end
      
      def severity_color(severity)
        red = [8, (severity * 16.0 / 10).to_i].min.clamp(0, 8)
        green = [8, ((10 - severity) * 16.0 / 10).to_i].min.clamp(0, 8)
        format("#%<red>x%<green>x0", red: red, green: green)
      end
      
      def ignore_hash?(hash)
        ignored_hashes.include?(hash.to_s)
      end
      
      def ignored_hashes
        @ignored_hashes ||= (controller.cookies['query_review_ignore_list'] || '').split(',')
      end
      
      def queries_with_warnings
        @queries.queries.select(&:has_warnings?)
      end
      
      def queries_with_warnings_sorted
        queries_with_warnings.sort_by { |q| [-q.max_severity, -(q.duration || 0)] }
      end
      
      def queries_with_warnings_sorted_nonignored
        queries_with_warnings_sorted.reject { |q| ignore_hash?(q.to_hash) }
      end
      
      def queries_with_warnings_sorted_ignored
        queries_with_warnings_sorted.select { |q| ignore_hash?(q.to_hash) }
      end
      
      def warnings_no_query_sorted
        @queries.collection_warnings.sort_by(&:severity).reverse
      end
      
      def warnings_no_query_sorted_ignored
        warnings_no_query_sorted.reject { |w| w.severity >= QueryReviewer::CONFIGURATION.fetch('warn_severity', 4) }
      end
      
      def warnings_no_query_sorted_nonignored
        warnings_no_query_sorted.select { |w| w.severity >= QueryReviewer::CONFIGURATION.fetch('warn_severity', 4) }
      end
      
      def enabled_by_cookie
        controller.cookies['query_review_enabled']
      end
      
      def duration_with_color(query)
        title = query.duration_stats
        duration = query.duration
        severity = if duration > QueryReviewer::CONFIGURATION.fetch('critical_duration_threshold', 1)
                     9
                   elsif duration > QueryReviewer::CONFIGURATION.fetch('warn_duration_threshold', 0.5)
                     QueryReviewer::CONFIGURATION.fetch('critical_severity', 7)
                   end
        
        content_tag(:span, format('%.3f', duration), style: ("color: #{severity_color(severity)}" if severity), title: title)
      end
    end
  end
end
