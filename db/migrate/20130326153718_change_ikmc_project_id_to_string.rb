class ChangeIkmcProjectIdToString < ActiveRecord::Migration
  def up
    change_column :intermediate_report, :ikmc_project_id, :string
  end

  def down
    change_column :intermediate_report, :ikmc_project_id, :integer
  end
end
