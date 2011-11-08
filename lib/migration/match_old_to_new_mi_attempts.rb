# encoding: utf-8

stats = Hash.new { 0 }

mi_map = {}

data_migration_map = YAML.load_file('db/data_migration_map.yaml')

stats = Hash.new { |hash, key| hash[key] = [] }

data_migration_map.each do |old_id, mappings|
  new_id = mappings.fetch 'id'
  new_colony_name = mappings.fetch 'colony_name'

  new_mi = MiAttempt.find_by_id(new_id)

  if ! new_mi
    deleted_audit = Audit.find_by_action_and_auditable_type_and_auditable_id 'destroy',
        'MiAttempt', new_id
    # past = deleted_audit.ancestors
    new_mi = deleted_audit.revision

    if ! deleted_audit
      stats[:not_found] << mappings
    end
  else
    if new_mi.colony_name != new_colony_name
      stats[:colony_name_mismatch] << mappings
    end
  end
end

stats.each_key do |stat_name|
  puts "#{stat_name}: #{stats[stat_name].join ', '}"
end

stats.each_key do |stat_name|
  puts "#{stats[stat_name].size}"
end
