class AddMiplanAbortedStatusToIntemediateReport < ActiveRecord::Migration
  def self.up
    add_column :intermediate_report, :aborted_es_cell_qc_failed_date, :date
  end

  def self.down
    remove_column :intermediate_report, :aborted_es_cell_qc_failed_date
  end
end
