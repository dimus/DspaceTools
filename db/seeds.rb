require_relative '../environment'

exit if settings.environment != :test

class Seeder
  attr :common_dir, :env_dir

  def initialize
    @db = ActiveRecord::Base.connection
    @common_dir = File.join(File.dirname(__FILE__), 'seed')
    @env_dir = File.join(common_dir, settings.environment.to_s)
    @path = nil
  end

  def walk_path(path)
    @path = path
    files = Dir.entries(path).map {|e| e.to_s}.select {|e| e.match /csv$/}
    files.each do |file|
      table = file.gsub(/\.csv/, '')
      data = get_data(table, file) 
      @db.execute("truncate table %s" % table)
      @db.execute("insert into %s values %s" % [table, data]) if data
    end
  end

  private 
  
  def get_data(table, file)
    columns = @db.select_values("show columns from %s" % table)
    ca_index = columns.index("created_at")
    ua_index = columns.index("updated_at")
    csv_args = {:col_sep => "\t"}
    data = CSV.open(File.join(@path, file), csv_args).map do |row|
      res = get_row(row, ca_index, ua_index)
      (columns.size - res.size).times { res << 'null' } 
      res.join(",")
    end rescue []
    data.empty? ? nil : "(%s)" % data.join("), (")
  end

  def get_row(row, ca_index, ua_index)
    res = []
    row.each_with_index do |field, index|
      if [ca_index, ua_index].include? index
        res << 'now()'
      else
        res << @db.quote(field)
      end
    end
    res
  end

end

s = Seeder.new

s.walk_path(s.env_dir)


