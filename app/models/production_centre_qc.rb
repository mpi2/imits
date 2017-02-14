class ProductionCentreQc < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  QC_FIELDS = {
      "five_prime_screen"       => { :name => "5' Screen",   :values => ["pass","not confirmed","no reads detected","not attempted"] },
      "three_prime_screen"      => { :name => "3' Screen",   :values => ["pass","not confirmed","no reads detected"] },
      "loxp_screen"             => { :name => "LoxP Screen", :values => ["pass","not confirmed","no reads detected"] },
      "loss_of_allele"          => { :name => "Loss of WT Allele (LOA)",:values => ["pass","passb","fail"] },
      "vector_integrity"        => { :name => "Vector Integrity",:values => ["pass","passb","fail"] },
  }.freeze

  belongs_to :allele
  before_validation :set_blank_qc_fields_to_na


  ##
  ## Validations
  ##

  validates :allele, :presence => true

  QC_FIELDS.each_key do |qc_field|
    validates_inclusion_of qc_field,
      :in        => QC_FIELDS[qc_field.to_s][:values],
      :message   => "This QC metric can only be set as: #{QC_FIELDS[qc_field.to_s][:values].join(', ')}",
      :allow_nil => true
  end

  def set_blank_qc_fields_to_na
    QC_FIELDS.each do |qc_field, config|
      next unless config.has_key?(:default)
      if self.send(qc_field).blank?
        self.send("#{qc_field}=", config[:default] )
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  def self.readable_name
    return 'production_centre_qcs'
  end

end

# == Schema Information
#
# Table name: production_centre_qcs
#
#  id                 :integer          not null, primary key
#  allele_id          :integer
#  five_prime_screen  :string(255)
#  three_prime_screen :string(255)
#  loxp_screen        :string(255)
#  loss_of_allele     :string(255)
#  vector_integrity   :string(255)
#
