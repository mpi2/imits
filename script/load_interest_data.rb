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
  consortium_name, production_centre_name, mgi_accession_id, rank, start_point, auto_assign = row

  next unless start_point == 'breeding'

  status_to_set = 'Interest'
  status_to_set = 'Assigned' if auto_assign == 'assigned'

  production_centre = nil
  production_centre = Centre.find_by_name!(production_centre_name) unless production_centre_name.blank?

  begin
    gene       = Gene.find_or_create_from_marts_by_mgi_accession_id(mgi_accession_id)
    status     = MiPlanStatus.find_by_name!(status_to_set)
    consortium = Consortium.find_by_name!(consortium_name)
    priority   = RANK_PRIORITY_MAP[rank.to_i]
    mi_plan    = MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id( gene, consortium, production_centre )

    if ! mi_plan
      MiPlan.create!(
        :gene => gene,
        :mi_plan_status => status,
        :consortium => consortium,
        :production_centre => production_centre,
        :mi_plan_priority => priority
      )
    end
  rescue Exception => e
    e2 = RuntimeError.new("(#{e.class.name}) (#{row}): #{e.message}")
    e2.set_backtrace(e.backtrace)
    raise e2
  end
end
