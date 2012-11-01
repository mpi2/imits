class SampleData
  def self.load
    raise "Sample data loading not supported in #{Rails.env} environment!" if ['staging', 'production'].include?(Rails.env)

    require 'factory_girl_rails'

    Centre.find_or_create_by_name('WTSI')
    Centre.find_or_create_by_name('ICS')

    user = User.find_by_email('test@example.com')
    if ! user
      user = Factory.create(:user, :email => 'test@example.com')
    end

    TargRep::Pipeline.find_or_create_by_name('EUCOMM')
    TargRep::Pipeline.find_or_create_by_name('KOMP')

    [
      {:name => 'EPD_SAMPLE_1', :pipeline => TargRep::Pipeline.find_by_name!('EUCOMM')},
      {:name => 'EPD_SAMPLE_2', :pipeline => TargRep::Pipeline.find_by_name!('KOMP')}
    ].each do |es_cell_data|
      es_cell = TargRep::EsCell.find_by_name(es_cell_data[:name])
      if es_cell
        es_cell.mi_attempts.destroy_all
        es_cell.destroy
      end

      es_cell = Factory.create(:randomly_populated_es_cell, es_cell_data)

      10.times do
        Factory.create(:randomly_populated_mi_attempt, :es_cell => es_cell)
      end
    end

  end

end
