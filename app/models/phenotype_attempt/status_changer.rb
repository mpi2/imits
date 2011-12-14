# encoding: utf-8

module PhenotypeAttempt::StatusChanger
  class ConfigItem
    def initialize(required, &conditions)
      @conditions = conditions
      @required = required
    end

    def conditions_met_for?(phenotype_attempt)
      conditions_met = @conditions.call(phenotype_attempt)
      if @required
        required_conditions_met = @required.conditions_met_for?(phenotype_attempt)
      else
        required_conditions_met = true
      end
      return (conditions_met and required_conditions_met)
    end
  end

  class Config
    @@items = {}

    def self.add(status, required = nil, &conditions)
      raise "Already have #{status}" if @@items.has_key?(status)
      required = @@items[required]
      object = ConfigItem.new(required, &conditions)
      @@items[status] = object
    end

    def self.get_status_for(phenotype_attempt)
      new_status = nil
      @@items.each do |status, item|
        if item.conditions_met_for?(phenotype_attempt)
          new_status = status
        end
      end
      return new_status
    end
  end

  Config.add('Registered') { |pt| true }

  Config.add('Rederivation Started') do |pt|
    pt.rederivation_started?
  end

  Config.add('Rederivation Complete', 'Rederivation Started') do |pt|
    pt.rederivation_complete?
  end

  Config.add('Cre Excision Started') do |pt|
    pt.number_of_cre_matings_started > 0
  end

  Config.add('Cre Excision Complete', 'Cre Excision Started') do |pt|
    pt.number_of_cre_matings_successful > 0
  end

  def change_status
    self.status = PhenotypeAttempt::Status[Config.get_status_for(self)]
  end

end
