class CreateCentrePipeline < ActiveRecord::Migration
  def change
    create_table :targ_rep_centre_pipelines do |t|

      t.string :name
      t.text :centres

      t.timestamps
    end

    TargRep::CentrePipeline.reset_column_information

    TargRep::CentrePipeline.create name: 'KOMP', centres: ['KOMP-CSD', 'KOMP-Regeneron']
    TargRep::CentrePipeline.create name: 'EUMMCR', centres: ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre']
    TargRep::CentrePipeline.create name: 'NorCOMM2GLS', centres: ['NorCOMM']
  end
end
