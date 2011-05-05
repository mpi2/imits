class SampleData
  def self.load
    require 'factory_girl_rails'

    Centre.find_or_create_by_name('WTSI')
    Centre.find_or_create_by_name('ICS')

    clone1 = Clone.find_by_clone_name('EPD_SAMPLE_1')
    if ! clone1
      clone1 = Factory.create(:clone, :pipeline_id => 1, :clone_name => 'EPD_RANDOM_1')
    end

    clone2 = Clone.find_by_clone_name('EPD_SAMPLE_2')
    if ! clone2
      clone2 = Factory.create(:clone, :pipeline_id => 1, :clone_name => 'EPD_RANDOM_2')
    end

    [clone1, clone2].each do |clone|
      clone.mi_attempts.destroy_all
      3.times do
        Factory.create(:fully_populated_mi_attempt, :clone => clone)
      end
    end
  end

end
