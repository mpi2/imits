class AddIkmcProjectTable < ActiveRecord::Migration
  def up
    create_table :targ_rep_ikmc_projects do |t|
      t.string :name
      t.integer :status_id
      t.integer :pipeline_id

      t.timestamps
    end
      create_table :targ_rep_ikmc_project_statuses do |t|
      t.string :name
    end

    TargRep::IkmcProject::Status.reset_column_information

    TargRep::IkmcProject::Status.create name: 'Design Completed'
    TargRep::IkmcProject::Status.create name: 'Design Not Possible'
    TargRep::IkmcProject::Status.create name: 'Design Requested'
    TargRep::IkmcProject::Status.create name: 'Vector Construction in Progress'
    TargRep::IkmcProject::Status.create name: 'Vector Complete'
    TargRep::IkmcProject::Status.create name: 'Vector - Initial Attempt Unsuccessful'
    TargRep::IkmcProject::Status.create name: 'Vector Unsuccessful - Project Terminated'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Targeting Confirmed'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Electroporation in Progress'
    TargRep::IkmcProject::Status.create name: 'ES Cells - Electroporation Unsuccessful'
    TargRep::IkmcProject::Status.create name: 'ES Cells - No QC Positives'
    TargRep::IkmcProject::Status.create name: 'ES Cells – Electroporation Unsuccessful'
    TargRep::IkmcProject::Status.create name: 'Mice - Microinjection in progress'
    TargRep::IkmcProject::Status.create name: 'Mice - Genotype confirmed'
    TargRep::IkmcProject::Status.create name: 'Mice - Phenotype Data Available'
    TargRep::IkmcProject::Status.create name: 'VEGA Annotation Requested'
    TargRep::IkmcProject::Status.create name: 'Redesign Requested'
    TargRep::IkmcProject::Status.create name: 'Withdrawn From Pipeline'

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
