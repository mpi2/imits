#!/usr/bin/env ruby

data = MiAttempt.order('created_at asc').all.map do |mi|
  [
    "#{mi.colony_name} #{mi.es_cell_name}",
    mi.mi_plan.status_stamps.order(:created_at).map {|i| "#{i.created_at.strftime('%F %T')} #{i.name}"},
    mi.status_stamps.order(:created_at).map {|i| "#{i.created_at.strftime('%F %T')} #{i.name}"}
  ]
end

y data
