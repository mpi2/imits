class SampleData
  def self.fill_non_foreign_key_integers_with_randomness(object)
    object.class.columns.each do |column|
      if column.type == :integer and column.name.to_s != 'id' and ! column.name.match(/_id$/)
        object[column.name] = rand(20)
      end
    end
  end

  def self.load
    require 'factory_girl_rails'
    clone1 = Clone.find_by_clone_name('EPD_RANDOM_1')
    if ! clone1
      clone1 = Factory.create(:clone, :pipeline_id => 1, :clone_name => 'EPD_RANDOM_1')
    end

    clone2 = Clone.find_by_clone_name('EPD_RANDOM_2')
    if ! clone2
      clone2 = Factory.create(:clone, :pipeline_id => 1, :clone_name => 'EPD_RANDOM_2')
    end

    [clone1, clone2].each do |clone|
      MiAttempt.find_all_by_clone_id(clone.id).each(&:destroy)
      3.times do
        mi_attempt = Factory.build(:mi_attempt, :clone => clone)
        fill_non_foreign_key_integers_with_randomness(mi_attempt)
        mi_attempt.save!
      end
    end
  end

end
