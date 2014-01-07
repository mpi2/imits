class EditIkmcProjectTable < ActiveRecord::Migration
  def up
    add_column :targ_rep_ikmc_project_statuses, :order_by, :integer

    TargRep::IkmcProject::Status.reset_column_information

    status_order = {
          'Design Not Possible'                      => 10,
          'Withdrawn From Pipeline'                  => 20,
          'Design Requested'                         => 30,
          'Redesign Requested'                       => 40,
          'VEGA Annotation Requested'                => 50,
          'Design Completed'                         => 60,
          'Vector Unsuccessful - Project Terminated' => 70,
          'Vector - Initial Attempt Unsuccessful'    => 80,
          'Vector Complete - Project Terminated'     => 90,
          'Vector Construction in Progress'          => 100,
          'Vector Complete'                          => 110,
          'ES Cells - Electroporation Unsuccessful'  => 120,
          'ES Cells - Electroporation in Progress'   => 130,
          'ES Cells - No QC Positives'               => 140,
          'ES Cells - Targeting Confirmed'           => 150,
          'Mice - Microinjection in progress'        => 160,
          'Mice - Genotype confirmed'                => 170,
          'Mice - Phenotype Data Available'          => 180
      }

    status_order.each do |key, value|
      status = TargRep::IkmcProject::Status.find_by_name(key)
      next if status.blank?
      status.order_by = value
      status.save
    end

  end

  def down
    remove_column :targ_rep_ikmc_project_statuses, :order_by
  end
end
