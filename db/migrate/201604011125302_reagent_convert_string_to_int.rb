class ReagentConvertStringToInt < ActiveRecord::Migration

  def self.up
      change_column :reagents, :reagent_id, 'integer USING CAST(reagent_id AS integer)'

  end
end
