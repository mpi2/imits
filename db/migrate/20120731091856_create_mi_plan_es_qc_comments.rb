class CreateMiPlanEsQcComments < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_es_qc_comments do |t|
      t.string :name, :null => false

      t.timestamps
    end

    add_index :mi_plan_es_qc_comments, :name, :unique => true

    add_column :mi_plans, :es_qc_comment_id, :integer

    add_foreign_key :mi_plans, :mi_plan_es_qc_comments, :column => 'es_qc_comment_id'
  end

  def self.down
    remove_column :mi_plans, :es_qc_comment_id

    drop_table :mi_plan_es_qc_comments
  end
end
