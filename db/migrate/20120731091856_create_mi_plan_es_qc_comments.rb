class CreateMiPlanEsQcComments < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_es_qc_comments do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :mi_plan_es_qc_comments
  end
end
