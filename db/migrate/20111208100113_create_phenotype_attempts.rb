class CreatePhenotypeAttempts < ActiveRecord::Migration
  def self.up
    create_table :phenotype_attempts do |t|
      t.integer :mi_attempt_id, :null => false
      t.boolean :is_active, :null => false, :default => true

      t.timestamps
    end
  end

  def self.down
    drop_table :phenotype_attempts
  end
end
