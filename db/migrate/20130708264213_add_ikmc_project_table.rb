class AddIkmcProjectTable < ActiveRecord::Migration
  def up
    create_table :targ_rep_ikmc_projects do |t|
      t.string :name, null: false
      t.integer :status_id
      t.integer :pipeline_id, null: false

      t.timestamps
    end
      create_table :targ_rep_ikmc_project_statuses do |t|
      t.string :name
      t.string :type
    end

    TargRep::IkmcProject::Status.reset_column_information

    TargRep::IkmcProject::Status.create name: 'Redesign Requested', type: 'Design'
    TargRep::IkmcProject::Status.create name: 'Design Not Possible', type: 'Design'
    TargRep::IkmcProject::Status.create name: 'Withdrawn From Pipeline', type: 'Design'

    TargRep::IkmcProject::Status.create name: 'VEGA Annotation Requested', type: 'Design'
    TargRep::IkmcProject::Status.create name: 'Design Requested', type: 'Design'
    TargRep::IkmcProject::Status.create name: 'Design Completed', type: 'Design'

    TargRep::IkmcProject::Status.create name: 'Vector Unsuccessful - Project Terminated', type: 'Vector'
    TargRep::IkmcProject::Status.create name: 'Vector - Initial Attempt Unsuccessful', type: 'Vector'
    TargRep::IkmcProject::Status.create name: 'Vector Construction in Progress', type: 'Vector'
    TargRep::IkmcProject::Status.create name: 'Vector Complete'

    TargRep::IkmcProject::Status.create name: 'ES Cells - Electroporation Unsuccessful', type: 'Es Cell'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Targeting Confirmed', type: 'Es Cell'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Electroporation in Progress', type: 'Es Cell'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Electroporation Unsuccessful', type: 'Es Cell'
    TargRep::IkmcProject::Status.create name: 'ES Cells - No QC Positives', type: 'Es Cell'

    TargRep::IkmcProject::Status.create name: 'Mice - Microinjection in progress', type: 'Mice'
    TargRep::IkmcProject::Status.create name: 'Mice - Genotype confirmed', type: 'Mice'
    TargRep::IkmcProject::Status.create name: 'Mice - Phenotype Data Available', type: 'Mice'

    add_column :targ_rep_es_cells, :ikmc_project_foreign_id, :integer
    add_column :targ_rep_targeting_vectors, :ikmc_project_foreign_id, :integer
  end

  def down

    drop_table :targ_rep_ikmc_projects
    drop_table :targ_rep_ikmc_project_statuses

    remove_column :targ_rep_es_cells, :ikmc_project_foreign_id
    remove_column :targ_rep_targeting_vectors, :ikmc_project_foreign_id
  end
end
