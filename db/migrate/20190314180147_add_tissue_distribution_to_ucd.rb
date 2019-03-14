class AddTissueDistributionToUcd < ActiveRecord::Migration
  def change
  	sql1 = <<-EOF
      INSERT INTO phenotyping_production_tissue_distribution_centres (start_date, phenotyping_production_id, deposited_material, centre_id, created_at, updated_at) 
      SELECT now(), pp.id, 'Fixed Tissue', c.id, now(), now() 
      FROM phenotyping_productions pp, mi_plans p, centres c 
      WHERE pp.status_id = 4 AND pp.mi_plan_id = p.id AND p.production_centre_id = c.id AND c.name = 'UCD'
    EOF

    ActiveRecord::Base.connection.execute(sql1)

    sql2 = <<-EOF
      INSERT INTO phenotyping_production_tissue_distribution_centres (start_date, phenotyping_production_id, deposited_material, centre_id, created_at, updated_at) 
      SELECT now(), pp.id, 'Paraffin-embedded Sections', c.id, now(), now() 
      FROM phenotyping_productions pp, mi_plans p, centres c 
      WHERE pp.status_id = 4 AND pp.mi_plan_id = p.id AND p.production_centre_id = c.id AND c.name = 'UCD'
    EOF

    ActiveRecord::Base.connection.execute(sql2)
  end
end
