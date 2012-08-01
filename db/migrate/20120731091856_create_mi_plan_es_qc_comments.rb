class CreateMiPlanEsQcComments < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_es_qc_comments do |t|
      t.string :name

      t.timestamps
    end

    add_column :mi_plans, :es_qc_comment_id, :integer

    add_foreign_key :mi_plans, :mi_plan_es_qc_comments, :column => 'es_qc_comment_id'
  end

  def self.down
    remove_column :mi_plans, :es_qc_comment_id

    drop_table :mi_plan_es_qc_comments
  end
end
