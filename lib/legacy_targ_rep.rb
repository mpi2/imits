require 'legacy_targ_rep/abstract'
require 'legacy_targ_rep/allele'
require 'legacy_targ_rep/user'

DATABASE_CONFIG = Rails.configuration.database_configuration[Rails.env]

class LegacyTargRep

  class RecordNotFound < StandardError; end
  class TableNotFound < StandardError; end

  attr_accessor :config, :database_connection
  
  ##
  ## Get TargRep config. This needs to be in config/database.targ_rep.yml
  ##
  def self.config
    begin
      @config ||= YAML.load_file("#{Rails.root}/config/database.targ_rep.yml")[Rails.env.to_s]
    rescue
      puts "Migration Failed. config/database.targ_rep.yml does not exist."
      raise
    end
  end

  ##
  ## Connect to the TargRep MySQL database.
  ##
  def self.database_connection
    Rails.logger.info "Connecting to #{Rails.env.to_s} database `#{config['database']}` with `#{config['username']}@#{config['password']}`"
    Sequel.mysql2.disconnect
    Sequel.mysql2(config['database'], 
      :user => config['username'],
      :password => config['password'],
      :host => config['host'],
      :port => config['port'],
      :loggers => [Logger.new($stdout)])
  end

  ##
  ## Alter table column
  ##
  def self.change_to_type(bools, conn, to_type)
    bools.each_pair do |table, cols|
      cols.each do |col|
        conn.execute "alter table #{table} alter column #{col} type #{to_type} 
                                  USING (#{col}::#{to_type});"
      end
    end
  end

  ##
  ## Handle MySQL, PostgreSQL boolean differences. Return column defaults to we can reverse it.
  ##
  def self.convert_boolean_to_integer(tablename)
    bools = {}
    defaults = {}

    conn = ActiveRecord::Base.connection
    table = conn.columns(tablename)

    begin

      ## Generate hash of boolean columns
      table.each do |col|
        if col.type.to_s == "boolean"
          (bools[tablename] ||= []) << col.name
          (defaults[tablename] ||= {})[col.name] = col.default if !col.default.nil?
        end

        ## Drop boolean defaults
        defaults.each_pair do |table, cols|
          cols.each_key do |col|
            conn.execute "alter table #{tablename} alter column #{col} DROP DEFAULT"      
          end
        end
      end

      change_to_type(bools, conn, :integer)

    rescue
      restore_column_defaults_and_boolean_type(tablename, [defaults, bools])
    end

    return [defaults, bools]
  end

  def self.restore_column_defaults_and_boolean_type(tablename, table_data)
    defaults, bools = table_data

    conn = ActiveRecord::Base.connection
    change_to_type(bools, conn, :boolean)

    defaults.each_pair do |table, cols|
      cols.each_pair do |col, default|
        conn.execute "alter table #{table} alter column #{col} SET DEFAULT #{default}"
      end
    end
  end

  ##
  ## Dump MySQL data, escape for PSql. Import into PSql.
  ##
  def self.export_mysqlsql_import_postgresql(tablename, new_tablename, has_booleans = false)

    ## If a table has boolean columns convert them to integers so that PostgreSQL doesn't complain.
    if has_booleans
      table_data = convert_boolean_to_integer(new_tablename)
    end

    conn = ActiveRecord::Base.connection

    if tablename == 'targeting_vectors'
      unless (conn.columns(new_tablename).map(&:name).include?('created_by'))
        conn.execute "alter table #{new_tablename} add column created_by integer"
        conn.execute "alter table #{new_tablename} add column updated_by integer"
      end
    end

    exported_file = File.join(Rails.application.config.paths['tmp'].first, "#{tablename}.sql")

    begin
      puts "Export Mysql database"
      dump_command = "mysqldump --compatible=postgresql --skip-comments --no-create-info --skip-extended-insert"
      dump_command << " --complete-insert --skip-opt --default-character-set=latin1"
      dump_command << " --host=#{LegacyTargRep.config['host']}" if LegacyTargRep.config['host']
      dump_command << " --port=#{LegacyTargRep.config['port']}" if LegacyTargRep.config['port']
      dump_command << " --user=#{LegacyTargRep.config['username']}" if LegacyTargRep.config['username']
      dump_command << " --password=#{LegacyTargRep.config['password']}" if LegacyTargRep.config['password']
      
      dump_command << " #{LegacyTargRep.config['database']} #{tablename} > #{exported_file}"
      puts dump_command
      `#{dump_command}`
      if ENV['osx']
        rename_table = %Q[sed -i "" "s/#{tablename}/#{new_tablename}/g" #{exported_file}]
      else
        rename_table = %Q[sed -i "s/#{tablename}/#{new_tablename}/g" #{exported_file}]
      end
      puts rename_table
      `#{rename_table}`

      escaped_file_string = File.open(exported_file) do |f|
        file_body = f.read
        file_body = file_body.gsub(/\\\'/, "\'\'").gsub(/\\r/, "\r").gsub(/\\n/, "\n")
      end

      escaped_file = File.join(Rails.application.config.paths['tmp'].first, "#{tablename}-escaped.sql")
      File.open(escaped_file, 'w') {|f| f.write(escaped_file_string)}
    
      puts "Import database into iMits"
      import_command = %Q[psql -W -h #{DATABASE_CONFIG['host']} -f #{escaped_file} #{DATABASE_CONFIG['database']} -U #{DATABASE_CONFIG['username']}]
      import_command << " -p #{DATABASE_CONFIG['port']}" if DATABASE_CONFIG['port']
      import_command << " -h #{DATABASE_CONFIG['host']}" if DATABASE_CONFIG['host']
    # puts import_command      

      `#{import_command}`

    rescue => e

      puts e.inspect

      if has_booleans
        restore_column_defaults_and_boolean_type(new_tablename, table_data)
      end
    end

    unless conn.execute("select count(*) from #{new_tablename}").first["count"].to_i > 0
      raise "Migration failed."
    end

    ## The imported integer columns that should be booleans should be set back to booleans.
    if has_booleans
      restore_column_defaults_and_boolean_type(new_tablename, table_data)
    end

    if tablename == 'targeting_vectors'
      conn.execute "alter table #{new_tablename} drop column created_by"
      conn.execute "alter table #{new_tablename} drop column updated_by"
    end

    update_sequences(new_tablename)

  end

  def self.update_sequences(tablename)
    puts "Rescyning table sequence based on last id in table."
    conn = ActiveRecord::Base.connection
    if conn.columns(tablename).detect{|i|i.name == "id"}
      conn.execute "SELECT setval('#{tablename}_id_seq', (SELECT max(id) FROM #{tablename}))"
    end
  end

  class Pipeline < Abstract; end
  class EsCell < Abstract; end
  class DistributionQc < Abstract; end
  class EsCellQcConflict < Abstract; end
  class TargetingVector < Abstract; end
end
