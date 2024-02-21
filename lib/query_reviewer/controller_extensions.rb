require 'action_view'
require_relative 'views/query_review_box_helper'

module QueryReviewer
  module ControllerExtensions
    extend ActiveSupport::Concern
    
    included do
      helper_method :query_review_output
      around_action :with_query_review
    end
    
    class QueryViewBase < ActionView::Base
      include QueryReviewer::Views::QueryReviewBoxHelper
    end
    
    private
    
    def with_query_review(&block)
      Thread.current['queries'] = SqlQueryCollection.new
      Thread.current['query_reviewer_enabled'] = query_reviewer_output_enabled?
      
      yield
      
      total_time = Time.now - Thread.current['queries'].overhead_time
      add_query_output_to_view(total_time)
    ensure
      # Ensure that the thread variables are cleared after the action
      Thread.current['queries'] = nil
      Thread.current['query_reviewer_enabled'] = nil
    end
    
    def query_review_output(ajax = false, total_time = nil)
      faux_view = QueryViewBase.new([File.join(File.dirname(__FILE__), 'views')], {}, self)
      queries = Thread.current['queries']
      queries.analyze!
      faux_view.instance_variable_set('@queries', queries)
      faux_view.instance_variable_set('@total_time', total_time)
      if ajax
        faux_view.render(partial: '/box_ajax.js')
      else
        faux_view.render(partial: '/box')
      end
    end
    
    def add_query_output_to_view(total_time)
      if request.xhr?
        response_body_append(query_review_output(true, total_time), content_type: response.content_type)
      elsif response_body_html?
        idx = response.body.index(%r{</body>}i)
        html = query_review_output(false, total_time)
        response.body.insert(idx, html)
      end
    end
    
    def response_body_append(content, content_type:)
      case content_type
      when /text\/html/
        response.body += "<script type=\"text/javascript\">#{content}</script>"
      when /text\/javascript/
        response.body += ";\n#{content}"
      end
    end
    
    def response_body_html?
      !response.body.is_a?(File) && !response.body.is_a?(Enumerator) && response.body.include?('</body>')
    end
    
    def query_reviewer_output_enabled?
      cookie_enabled = (QueryReviewer::CONFIGURATION['enabled'] == true && cookies['query_review_enabled'])
      session_enabled = (QueryReviewer::CONFIGURATION['enabled'] == 'based_on_session' && session['query_review_enabled'])
      cookie_enabled || session_enabled
    end
  end
end
