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
    begin
      sql =  <<-EOF
        BEGIN;

        TRUNCATE #{self.class.table};

        INSERT INTO #{self.class.table} (#{self.class.columns.join(', ')}) VALUES
      EOF

      values = Array.new.tap do |v|
        report_rows.each do |report_row|
          v << "(#{self.class.row_for_sql(report_row)})"
        end
      end

      sql << values.join(",\n")
      return if values.empty?

      sql << "; COMMIT;"

      ActiveRecord::Base.connection.execute(sql)

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


    def report_sql(experiment_types, mouse_pipelines, allele_type = [])
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
#          allele_type.each do ||
#          end
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
