# encoding: utf-8

{'ruby 1.9': true}

data_migration_map = YAML.load_file('db/data_migration_map.yaml')

data = {}

data_migration_map.each do |old_id, mappings|
  old_mi = Old::MiAttempt.find_by_id!(old_id)
  audits = Old::MiAttemptAudit.where(:id => old_id).
          order("#{Old::MiAttemptAudit.table_name}.edit_date asc").all
  new_id = mappings['id']
  new_mi = MiAttempt.find_by_id(new_id)

  data[new_id] = {}

  first_gc = nil
  first_status = nil
  audits.each do |audit|
    if first_status.nil?
      first_status = audit
    end

    next if audit.mi_attempt_status.nil?

    if audit.mi_attempt_status.name == 'Genotype Confirmed' and first_gc.nil?
      first_gc = audit
    end
  end

  next unless new_mi

  data[new_id]['colony_name'] = new_mi.colony_name
  statuses = data[new_id]['statuses'] = {}
  statuses[MiAttemptStatus.micro_injection_in_progress.description] = old_mi.actual_mi_date.to_s
  if first_gc
    statuses[MiAttemptStatus.genotype_confirmed.description] = first_gc.edit_date.to_s
  end
end

File.open('db/pre_data_migration_statuses.yaml', 'w') do |file|
  file.puts data.to_yaml
end
