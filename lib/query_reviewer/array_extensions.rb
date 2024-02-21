module QueryReviewer
  module ArrayExtensions
    def qa_columnized
      sized = calculate_column_widths
      
      table = []
      table << qa_columnized_row(first.keys, sized)
      table << '-' * table.first.length
      each { |row| table << qa_columnized_row(row.values, sized) }
      table.join("\n   ") # Spaces added to work with format_log_entry
    end
    
    private
    
    def calculate_column_widths
      sized = Hash.new(0)
      each do |row|
        row.each_with_index do |(key, value), i|
          sized[i] = [sized[i], key.to_s.length, value.to_s.length].max
        end
      end
      sized
    end
    
    def qa_columnized_row(fields, sized)
      fields.each_with_index.map do |f, i|
        format("%-#{sized[i]}s", f.to_s)
      end.join(' | ')
    end
  end
end
