class CreateProductionGoalTable < ActiveRecord::Migration
  def self.up
    create_table :production_goals do |t|
      t.integer :consortium_id
      t.integer :year
      t.integer :month
      t.integer :mi_goal
      t.integer :gc_goal

      t.timestamps
    end

    ProductionGoal.reset_column_information

    goal_data = YAML.load_file File.join(Rails.root, 'config', 'report_production_goals.yml')
    goal_data = goal_data["summary_month_by_month"]
    consortia = goal_data.keys
    consortia.each do |consortium|
      goal_data[consortium].each do |data|
        year = data.first
        rows = data.last
        rows.each do |row|
          month = row.first
          mi_goal = row.last["mi_goals"]
          gc_goal = row.last["gc_goals"]

          ProductionGoal.create :consortium => Consortium.find_by_name(consortium), :year => year, :month => month, :mi_goal => mi_goal, :gc_goal => gc_goal
        end
      end
    end
  end

  def self.down
    drop_table :production_goals
  end
end
