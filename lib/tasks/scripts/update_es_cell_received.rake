namespace :scripts do
  task :update_es_cell_received => :environment do
    MiPlan.all.each do |plan|
      success = plan.update_es_cell_received
      MiPlan.update_all({:number_of_es_cells_received => plan.number_of_es_cells_received, :es_cells_received_on => plan.es_cells_received_on, :es_cells_received_from_id => plan.es_cells_received_from_id}, {:id => plan.id}) if success
    end
  end
end