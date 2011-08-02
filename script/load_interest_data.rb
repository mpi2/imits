#!/usr/bin/env ruby

if ! Object.constants.include?(:Rails)
  require File.expand_path('../../config/environment', __FILE__)
end

RANK_PRIORITY_MAP = {
  1 => MiPlanPriority.find_by_name!('High'),
  2 => MiPlanPriority.find_by_name!('Medium'),
  3 => MiPlanPriority.find_by_name!('Low')
}.freeze

rows = CSV.read(ARGV[0])

rows.each do |row|
  consortium_name, production_centre_name, mgi_accession_id, rank, start_point = row
  next unless start_point == 'breeding'
  begin
    MiPlan.create!(
      :gene => Gene.find_or_create_from_marts_by_mgi_accession_id(mgi_accession_id),
      :mi_plan_status => MiPlanStatus.find_by_name!('Interest'),
      :consortium => Consortium.find_by_name!(consortium_name),
      :production_centre => Centre.find_by_name!(production_centre_name),
      :mi_plan_priority => RANK_PRIORITY_MAP[rank.to_i]
    )
  rescue Exception => e
    e2 = RuntimeError.new("(#{e.class.name}) (#{row}): #{e.message}")
    e2.set_backtrace(e.backtrace)
    raise e2
  end
end
