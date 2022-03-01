
module QueryReviewer
  # taken from query_analyser plugin
  module ArrayExtensions
    protected

    def qa_columnized_row(fields, sized)
      row = []
      fields.each_with_index do |f, i|
        row << format("%0-#{sized[i]}s", f.to_s)
      end
      row.join(' | ')
    end

    public

    def qa_columnized
      sized = {}
      each do |row|
        row.values.each_with_index do |value, i|
          sized[i] = [sized[i].to_i, row.keys[i].length, value.to_s.length].max
        end
      end

      table = []
      table << qa_columnized_row(first.keys, sized)
      table << '-' * table.first.length
      each { |row| table << qa_columnized_row(row.values, sized) }
      table.join("\n   ") # Spaces added to work with format_log_entry
    end
  end
end
