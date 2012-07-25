class AddCodeToStatuses < ActiveRecord::Migration
  TABLE_NAMES = [:mi_plan_statuses, :mi_attempt_statuses, :phenotype_attempt_statuses]

  def self.up
    TABLE_NAMES.each do |table_name|
      add_column table_name, :code, :string, :limit => 10, :null => false, :default => ''
      execute("ALTER TABLE #{table_name.to_s} ALTER code DROP DEFAULT")
    end
  end

  def self.down
    TABLE_NAMES.each do |table_name|
      remove_column table_name, :code
    end
  end
end
