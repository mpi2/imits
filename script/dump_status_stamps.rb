#!/usr/bin/env ruby

all_output = {}

[MiPlan, MiAttempt, PhenotypeAttempt].each do |model_class|
  stamps_output = all_output[model_class.name] = {}
  model_class.order('id asc').each do |model|
    stamps_output[model.id] = model.status_stamps.map {|s| [s.created_at.iso8601, s.status.code] }
  end
end

puts all_output.to_json
