class AddEsCellParentalCellLineColumn < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :parental_cell_line, :string
  end

  def self.down
    remove_column :es_cells, :parental_cell_line
  end
end
