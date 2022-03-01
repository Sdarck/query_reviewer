# frozen_string_literal: true

require 'rubygems'
require 'active_support'
require 'test/unit'
require 'query_reviewer'

module QueryReviewer
  class SqlSubQuery
    include Test::Unit::Assertions
    def should_warn(problem, severity = nil)
      assert warnings.detect { |warn|
               warn.problem.downcase == problem.downcase &&
                 (!severity || warn.severity == severity)
             }
    end
  end
end

module Test
  module Unit
    class TestCase
      include QueryReviewer
    end
  end
end
