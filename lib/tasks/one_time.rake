
namespace :one_time do

  desc 'one-time rename for mi_plan_status - changing declined to inspect'  
  task 'update_mi_plan_status' => ['environment'] do
    MiPlanStatus.all.each do |status|
        status.name = status.name.gsub(/^Declined/, "Inspect")
        status.description = status.description.gsub(/^Declined/, "Inspect")
        status.save!
    end
        
  end

end
