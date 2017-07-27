class IntermediateReport::Base

  attr_accessor :report_rows, :size, :retrying

  def initialize
    @report_rows = []

    parse_raw_report

    nil
  end


  def raw_report
    @raw_report ||= self.class.report_sql.to_a
  end


  def parse_raw_report

    raw_report.each do |report_row|
      report_row['created_at'] = Time.now.to_s(:db)
       @report_rows << report_row
    end

    true
  end


  def size
    @size ||= report_rows.size
  end


  def to_s
    "Generate size: #{size}>"
  end


  def insert_report
    return if report_rows.length == 0

    begin


## batch up insert statement into 10000 records. Do this inside a Active record transaction ensures all the insert statements are executed in the same transaction.
## This sorts out memory bloating/ out of memory issue. I think it creates a transaction (BEGIN COMMIT STATEMENT) in postgres and sends the batch insert sql statements one at a time.
## These smaller queries are evalutated by postgres using much less memory.
## This ensures the memory ruby uses for its variables does not bloat and the memory postgres uses to store the sql statement prior and during evaluation does not bloat.
      ActiveRecord::Base.connection.transaction do

        ActiveRecord::Base.connection.execute("TRUNCATE #{self.class.table};")
        ActiveRecord::Base.connection.execute("SELECT setval('#{self.class.table}_id_seq', 1);")

        i = 0
        sql =''

        report_rows.each do |report_row|
          i += 1
          if  (i-1) % 10000 == 0
            sql = "INSERT INTO #{self.class.table} (#{self.class.columns.join(', ')}) VALUES"
          end

          sql << "\n(#{self.class.row_for_sql(report_row)}),"

          if i % 10000 == 0
            sql = sql.strip().chomp(',')
            sql << ';'
            ActiveRecord::Base.connection.execute(sql)
            sql = ''
          end
        end

        sql = sql.strip().chomp(',')
        sql << ';'
        ActiveRecord::Base.connection.execute(sql)


      end

      INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Report generation successful."
      puts "[#{Time.now}] Report generation successful."

    rescue => e
      puts "[#{Time.now}] ERROR"
      puts e.inspect
      puts e.backtrace.join("\n")

      INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] ERROR - Report generation failed."
      INTERMEDIATE_REPORT_LOG.info e.inspect
      INTERMEDIATE_REPORT_LOG.info e.backtrace.join("\n")
      @retrying = true
      unless @retrying
        ActiveRecord::Base.connection.reconnect!
        @retrying = true

        puts "[#{Time.now}] Reconnecting database and retrying..."
        INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Reconnecting database and retrying..."

        retry
      end

      raise Tarmits::ReportGenerationFailed
    end
  end


  ##
  ## Class methods
  ##

  class << self


    def report_sql(experiment_types, mouse_pipelines)
      data = []

      # GENERIC SQL RULES:
      # 1. filtered_plans is used to select for crispr or es_cell data sets. If the 'ALL' condition is passed in it will select everything as the data set.
      # 2. filtered_production is used to select mouse production from micro_injection or mouse allele modification. This will also return the most advanced phenotyping for mouse produced by this method.
      # 3. ######TO DO filter production by allele type

      experiment_types.each do |experiment_type, experiment_type_condition|
        #'ES CELL', 'CRISPR', 'ALL'
        data += experiment_report_logic(experiment_type, experiment_type_condition)

        mouse_pipelines.each do |mouse_pipeline, mouse_pipeline_condition|
          #'micro-injection', 'mouse allele modification', 'ALL'
          data += ActiveRecord::Base.connection.execute(best_production_report_sql(experiment_type, mouse_pipeline, experiment_type_condition, mouse_pipeline_condition)).to_a
        end
      end
      return data
    end


    def experiment_report_logic(data)
      return
    end


    def cache
      puts "[#{Time.now}] Report generation started."
      INTERMEDIATE_REPORT_LOG.info "[#{Time.now}] Report generation started."

      report = self.new
      report.insert_report
    end


    def row_for_sql(report_row)
      columns.map {|c| data_for_sql(c, report_row)}.join(', ')
    end


    def data_for_sql(column, report_row)

      data = report_row[column]

      if data.blank?
        data = 'NULL'
      elsif data.is_a?(String)
        data = "\'#{data}\'"
      end

      data
    end


    def columns
      []
    end

  end
end
