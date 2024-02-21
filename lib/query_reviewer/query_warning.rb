module QueryReviewer
  class QueryWarning
    attr_reader :query, :severity, :problem, :desc, :table, :id
    
    @@next_id = 1
    
    def self.next_id
      @@next_id
    end
    
    def self.next_id=(value)
      @@next_id = value
    end
    
    def initialize(options)
      @query = options[:query]
      @severity = options[:severity]
      @problem = options[:problem]
      @desc = options[:desc] # Renamed to match the full word for clarity
      @table = options[:table]
      @id = self.class.next_id
      self.class.next_id += 1
    end
  end
end
