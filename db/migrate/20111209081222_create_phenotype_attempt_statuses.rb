class CreatePhenotypeAttemptStatuses < ActiveRecord::Migration
  def self.up
    create_table :phenotype_attempt_statuses do |t|
      t.string :name, :null => false, :limit => 50

      t.timestamps
    end
  end

  def self.down
    drop_table :phenotype_attempt_statuses
  end
end
