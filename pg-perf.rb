
VERSIONS = ['9.1', '9.4']

class QueryParser

  def initialize()
    @by_sql = {}
    @by_model = {}
  end

  # Result structure: [Model, Query, Time]

  def parse_file(version)
    path = "./#{version}.txt"
    queries_file = "./#{version}-queries.txt"
    File.open(path) do |file|
      File.open(queries_file, 'w') do |qfile|
        file.each_line do |line|
          data = /^([^\s]+)\s+(?:Load\s+)?\((.+)ms\)\s+(.+)$/.match(line)
          next if data.nil?
          if data[1] == 'SQL'
            type, table = parse_sql(data[3])
            next if type.nil?
            @by_sql[table] ||= {}
            @by_sql[table][type] ||= {}
            @by_sql[table][type][version] ||= []
            @by_sql[table][type][version] << data[2].to_f
          else
            @by_model[data[1]] ||= {}
            @by_model[data[1]][version] ||= []
            @by_model[data[1]][version] << data[2].to_f
          end
          qfile.write(data[3]+"\n") if ! /\$/.match(data[3])
        end
      end
    end
  end

  def report_by_model
    # Print report by model
    puts 'Performance Report by Model load'
    max_col_size = @by_model.keys.inject(0) {|s,v| v.size > s ? v.size : s}
    max_col_size = 5 if max_col_size < 5
    table_width = max_col_size + 83
    puts '=' * table_width
    puts ' '.ljust(max_col_size) + ' |    Queries    | Minimum time  |  Maximum time   | Average time  | Time median'
    puts '        Model        |' + '-' * (table_width - max_col_size - 2)
    puts ' ' * max_col_size + ' |  9.1  |  9.4  |  9.1  |  9.4  |   9.1  |   9.4  |  9.1  |  9.4  |  9.1  |  9.4' 
    puts '-' * table_width
    @by_model.keys.sort.each do |model_name|
      avg = {}
      min = {}
      max = {}
      median = {}
      count = {}
      VERSIONS.each do |v|
        t = @by_model[model_name][v]
        if t.nil?
          count[v] = '-'
          min[v] = '-'
          max[v] = '-'
          avg[v] = '-'
          median[v] = '-'
        else
          count[v] = t.size.to_s
          min[v] = '%.2f' % t.min
          max[v] = '%.2f' % t.max
          avg[v] = '%.2f' % (t.inject(:+) / t.size)
          median[v] = '%.2f' % calc_median(t)
        end
      end
      puts model_name.ljust(max_col_size) + ' | ' + \
           count[VERSIONS[0]].rjust(5) + ' | ' + \
           count[VERSIONS[1]].rjust(5) + ' | ' + \
           min[VERSIONS[0]].rjust(5) + ' | ' + \
           min[VERSIONS[1]].rjust(5) + ' | ' + \
           max[VERSIONS[0]].rjust(6) + ' | ' + \
           max[VERSIONS[1]].rjust(6) + ' | ' + \
           avg[VERSIONS[0]].rjust(5) + ' | ' + \
           avg[VERSIONS[1]].rjust(5) + ' | ' + \
           median[VERSIONS[0]].rjust(5) + ' | ' + \
           median[VERSIONS[1]].rjust(5)
    end
    puts '=' * table_width
  end

  def report_by_sql
    puts "\nPerformance Report by Raw SQL"
    max_col_size = @by_sql.keys.inject(0) {|s,v| v.size > s ? v.size : s} + 1
    max_col_size = 11 if max_col_size < 11
    table_width = max_col_size + 83
    puts '=' * table_width
    puts ' '.ljust(max_col_size) + ' |    Queries    | Minimum time  |  Maximum time   | Average time  |  Time median'
    puts '       Table        |' + '-' * (table_width - max_col_size - 2)
    puts ' ' * max_col_size + ' |  9.1  |  9.4  |  9.1  |  9.4  |   9.1  |   9.4  |  9.1  |  9.4  |  9.1  |  9.4' 
    puts '-' * table_width
    @by_sql.keys.sort.each do |table|
      avg = {}
      min = {}
      max = {}
      median = {}
      count = {}
      table_row_written = false
      by_table = @by_sql[table]
      by_table.each_pair do |query, data|
        count[query] ||= {}
        min[query] ||= {}
        max[query] ||= {}
        avg[query] ||= {}
        median[query] ||= {}
        VERSIONS.each do |v|
          times = data[v]
          if times.nil?
            count[query][v] = '-'
            min[query][v] = '-'
            max[query][v] = '-'
            avg[query][v] = '-'
            median[query][v] = '-'
          else
            count[query][v] = times.size.to_s
            min[query][v] = '%.2f' % times.min
            max[query][v] = '%.2f' % times.max
            avg[query][v] = '%.2f' % (times.inject(:+) / times.size)
            median[query][v] = '%.2f' % calc_median(times)
          end
        end
        if !table_row_written
          puts "#{table}:".ljust(max_col_size) + ' |       |       |       |       |        |        |       |       |       |'
          table_row_written = true
        end
        puts "  - #{query}".ljust(max_col_size) + ' | ' + \
             count[query][VERSIONS[0]].rjust(5) + ' | ' + \
             count[query][VERSIONS[1]].rjust(5) + ' | ' + \
             min[query][VERSIONS[0]].rjust(5) + ' | ' + \
             min[query][VERSIONS[1]].rjust(5) + ' | ' + \
             max[query][VERSIONS[0]].rjust(6) + ' | ' + \
             max[query][VERSIONS[1]].rjust(6) + ' | ' + \
             avg[query][VERSIONS[0]].rjust(5) + ' | ' + \
             avg[query][VERSIONS[1]].rjust(5) + ' | ' + \
             median[query][VERSIONS[0]].rjust(5) + ' | ' + \
             median[query][VERSIONS[1]].rjust(5)
      end
    end
    puts '=' * table_width
  end

  def report
    report_by_model
    report_by_sql
  end

  private

  def parse_sql(sql)
    types = {
      'INSERT INTO' => 'insert',
      'DELETE FROM' => 'delete',
      'UPDATE' => 'update'}
    data = /^(INSERT INTO|DELETE FROM|UPDATE|SELECT\s+.+?FROM)\s+"([^"]+)"/.match(sql)
    if data
      if types.has_key?(data[1])
        return types[data[1]], data[2]
      elsif data[1].start_with?('SELECT')
        return 'select', data[2]
      end
    end
    [nil, nil]
  end

  def calc_median(list)
    sorted = list.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

end

if __FILE__ == $0
  qp = QueryParser.new
  VERSIONS.each { |v| qp.parse_file(v) }
  qp.report
end
