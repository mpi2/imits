class RemoveForeignKeys < ActiveRecord::Migration
  def self.up
    ## These are no longer required
    remove_foreign_key :es_cells, :genes
    ## These are no longer required. Superceded by TargRep::Pipelines
    remove_foreign_key :es_cells, :pipelines
    ## This is not pointing to the reduncant EsCell table.
    remove_foreign_key :mi_attempts, :es_cells
    ##
    ## Once the data has been migrated and is all up to date we'll need to re-add the following foreign key;
    ## add_foreign_key :mi_attempts, :targ_rep_es_cells, :column => 'es_cell_id'
    ##
  end

  def self.down
    add_foreign_key :es_cells, :genes
    add_foreign_key :es_cells, :pipelines
    add_foreign_key :mi_attempts, :es_cells
  end
end
