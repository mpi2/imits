# encoding: utf-8

{ruby19: true}

data_migration_map = YAML.load_file('db/data_migration_map.yaml')
old_statuses_map = YAML.load_file('db/pre_data_migration_statuses.yaml')

MiAttempt.transaction do
  data_migration_map.each do |old_id, mappings|
    new_mi = MiAttempt.find_by_id(mappings['id'])
    next unless new_mi

    output = []

    old_statuses = old_statuses_map[new_mi.id]['statuses'].dup

    if new_mi.status_stamps.first.description != old_statuses.keys.last
      output << "  !!!!!Examine!!!!!"
    else
      deleted_status_stamp = new_mi.status_stamps.first.destroy
      output << "  Deleted '#{deleted_status_stamp.description}'(#{deleted_status_stamp.created_at.to_s})"
      new_mi.reload
    end

    old_statuses.each do |description, timestamp|
      new_status_stamp = new_mi.status_stamps.create!(
        :mi_attempt_status => MiAttemptStatus.find_by_description!(description),
        :created_at => Time.parse(timestamp)
      )
      output << "  Created '#{new_status_stamp.description}'(#{new_status_stamp.created_at.to_s})"
    end

    if ! output.blank?
      puts "MI #{new_mi.id}(#{new_mi.colony_name})"
      puts output.join("\n")
    end
  end
end
