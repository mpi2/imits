class SampleData
  def self.fill_non_foreign_key_fields_with_randomness(object)
    object.class.columns.each do |column|
      next if ['id', 'created_at', 'updated_at'].include?(column.name.to_s)
      next if column.name.match(/_id$/)

      if column.type == :integer
        object[column.name] = rand(20)
      elsif column.type == :date
        object[column.name] = Date.today.beginning_of_month + rand(29).days
      else
        puts 'Not filling ' + column.name
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
        fill_non_foreign_key_fields_with_randomness(mi_attempt)
        mi_attempt.save!
      end
    end
  end

end
