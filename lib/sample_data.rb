class SampleData
  def self.load
    raise "Sample data loading not supported in #{Rails.env} environment!" if ['staging', 'production'].include?(Rails.env)

    require 'factory_girl_rails'

    Centre.find_or_create_by_name('WTSI')
    Centre.find_or_create_by_name('ICS')

    [
      {:clone_name => 'EPD_SAMPLE_1', :pipeline_id => 1},
      {:clone_name => 'EPD_SAMPLE_2', :pipeline_id => 2}
    ].each do |clone_data|
      clone = Clone.find_by_clone_name(clone_data[:clone_name])
      if clone
        clone.mi_attempts.destroy_all
        clone.destroy
      end

      clone = Factory.create(:randomly_populated_clone, :pipeline_id => clone_data[:pipeline_id], :clone_name => clone_data[:clone_name])

      10.times do
        Factory.create(:randomly_populated_mi_attempt, :clone => clone)
      end
    end

  end

end
