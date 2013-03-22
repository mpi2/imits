class CreateMiPlanEsCellQcs < ActiveRecord::Migration
  def up
    create_table :mi_plan_es_cell_qcs do |t|
      t.integer :number_starting_qc
      t.integer :number_passing_qc
      t.integer :mi_plan_id

      t.timestamps
    end

    add_foreign_key :mi_plan_es_cell_qcs, :mi_plans

    execute %{
      INSERT INTO mi_plan_es_cell_qcs (mi_plan_id, number_starting_qc, number_passing_qc, created_at, updated_at)
      select id, number_of_es_cells_starting_qc, number_of_es_cells_passing_qc, current_date, current_date from mi_plans
      where number_of_es_cells_starting_qc is not null and number_of_es_cells_passing_qc is not null;
    }
  end

  def down
    drop_table :mi_plan_es_cell_qcs
  end
end
