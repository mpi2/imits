MODELS = [
  MiAttempt::Status,
  QcResult,
  DepositedMaterial,
  Consortium,
  Centre,
  MiPlan::Status,
  MiPlan::Priority,
  MiPlan::SubProject,
  PhenotypeAttempt::Status,
  Strain
]

MODELS.each do |model|
  table_name = model.table_name

  data = {}
  model.all.sort_by(&:id).each {|i| data[i.id] = i.attributes}

  data.each do |fixturename, record|
    record.delete('created_at')
    record.delete('updated_at')
  end

  File.open(Rails.root + "test/fixtures/#{table_name}.yml", 'wb') do |file|
    file.puts data.to_yaml
  end
end
