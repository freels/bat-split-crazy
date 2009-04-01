module BatSplitCrazy
  class ReportTable
    def columns(*cols)
      @columns = Array(cols.flatten).map(&:to_s) if cols.length > 0
      @columns
    end

    def rows
      @rows ||= {}.with_indifferent_access
    end

    def row(group_name, *data)
      if data.length == 1 and data.first.is_a? Hash
        hash = data.first.with_indifferent_access
        data = columns.inject([]) {|r,c| r << hash[c] }
      end

      rows[group_name] = data
    end

    def order(col_name, asc_or_desc)
      @order = [col_name.to_s, asc_or_desc]
    end
    alias order_by order

    def ascending?
      @order.last != :desc
    end

    def each(&block)
      if @order
        offset = @columns.index(@order.first)
        row_order = rows.sort_by{|n,r| r[offset]}.map{|n, r| n}
        row_order.reverse! unless ascending?
        row_order.each do |n|
          yield(n, rows[n])
        end
      else
        rows.each(&block)
      end
    end

    def to_html
      %{<table><thead><tr><th>Group</th>#{ columns.map{|c| "<th>#{c}</th>" }.join }</tr></thead>
      <tbody>#{ rows.map{|n,r| "<tr><th>#{n}</th>#{r.map{|v| "<td>#{v}</td>" }.join }</tr>" } }
      </tbody></table>}
    end
  end
end  
