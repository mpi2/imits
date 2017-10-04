class ProductionCentreQc < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  QC_FIELDS = {
      "five_prime_screen"             => { :name => "5 Prime Screen",   :values => ["pass","not confirmed","no reads detected","not attempted"] },
      "three_prime_screen"            => { :name => "3 Prime Screen",   :values => ["pass","not confirmed","no reads detected"] },
      "loxp_screen"                   => { :name => "LoxP Screen", :values => ["pass","not confirmed","no reads detected"] },
      "loss_of_allele"                => { :name => "Loss of WT Allele (LOA)", :values => ["pass","passb","fail"] },
      "vector_integrity"              => { :name => "Vector Integrity", :values => ["pass","passb","fail"] },
      "southern_blot"                 => { :name => "Southern Blot", :values => ["na", "pass", "fail"], :default => "na" },
      "five_prime_lr_pcr"             => { :name => "Five Prime LR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "five_prime_cassette_integrity" => { :name => "Five Prime Cassette Integrity", :values => ["na", "pass", "fail"], :default => "na" },
      "tv_backbone_assay"             => { :name => "TV Backbone Assay", :values => ["na", "pass", "fail"], :default => "na" },
      "neo_count_qpcr"                => { :name => "Neo Count qPCR", :values => ["na", "pass", "fail"], :default => "na" },
      "lacz_count_qpcr"               => { :name => "LacZ count qPCR", :values => ["na", "pass", "fail"], :default => "na" },
      "neo_sr_pcr"                    => { :name => "Neo SR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "loa_qpcr"                      => { :name => "LOA qPCR", :values => ["na", "pass", "fail"], :default => "na" },
      "homozygous_loa_sr_pcr"         => { :name => "Homozygous LOA SR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "lacz_sr_pcr"                   => { :name => "LacZ SR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "mutant_specific_sr_pcr"        => { :name => "Mutant Specific SR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "loxp_confirmation"             => { :name => "LOXP Confirmation", :values => ["na", "pass", "fail"], :default => "na" },
      "three_prime_lr_pcr"            => { :name => "Three Prime LR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "critical_region_qpcr"          => { :name => "Critical Region qPCR", :values => ["na", "pass", "fail"], :default => "na" },
      "loxp_srpcr"                    => { :name => "LOXP SR PCR", :values => ["na", "pass", "fail"], :default => "na" },
      "loxp_srpcr_and_sequencing"     => { :name => "LOXP SR PCR and Sequencing", :values => ["na", "pass", "fail"], :default => "na"}
  }.freeze

  belongs_to :allele
  before_validation :set_blank_qc_fields_to_na
  before_validation :restrict_qc_fields_that_can_be_updated


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

  after_save do |pc_qc|
    return true if pc_qc.allele.colony.blank? || pc_qc.allele.colony.mi_attempt.blank? || allele.colony.mi_attempt.es_cell_id.blank?
    return true if pc_qc.allele.colony.mi_attempt.es_cell.allele.mutation_type.try(:code) == 'cki'

    es_cell_allele = pc_qc.allele.colony.mi_attempt.es_cell.alleles[0]

    allele = Allele.find(pc_qc.allele_id)
    if pc_qc.loxp_confirmation == 'fail' && es_cell_allele.allele_type == 'a'
      allele.allele_type = 'e'
    elsif allele.allele_type == 'e' and (pc_qc.loxp_confirmation == 'pass')
      allele.allele_type = 'a'
    end

    if allele.changed?
      allele.save
      pc_qc.reload
    end
  end


  def set_blank_qc_fields_to_na
    pc_qc = self

    QC_FIELDS.each do |qc_field, config|
      if config.has_key?(:default)
        if pc_qc.send(qc_field).blank?
          pc_qc.send("#{qc_field}=", config[:default] )
        end
      else
        pc_qc.send("#{qc_field}=", nil) if pc_qc.send(qc_field).blank?
      end
    end
  end
  protected :set_blank_qc_fields_to_na


  def restrict_qc_fields_that_can_be_updated
    pc_qc = self

    return if pc_qc.allele.blank?

    if pc_qc.allele.belongs_to_colony?
      ["five_prime_screen",
       "three_prime_screen",
       "loxp_screen",
       "loss_of_allele",
       "vector_integrity"
       ].each do |field|
         if pc_qc.changed.include?(field)
           pc_qc.send("#{field}=", pc_qc.changes[field][0])
         end
       end

    elsif pc_qc.allele.belongs_to_es_cell?
      all_other_fields = pc_qc.changed - ["id",
       "allele_id",
       "five_prime_screen",
       "three_prime_screen",
       "loxp_screen",
       "loss_of_allele",
       "vector_integrity"
       ]
       all_other_fields.each do |field|
         if pc_qc.changed.include?(field)
           pc_qc.send("#{field}=", pc_qc.changes[field][0])
         end
       end
    end
  end
  protected :restrict_qc_fields_that_can_be_updated


  def self.readable_name
    return 'production_centre_qcs'
  end
end

# == Schema Information
#
# Table name: production_centre_qcs
#
#  id                            :integer          not null, primary key
#  allele_id                     :integer
#  five_prime_screen             :string(255)
#  three_prime_screen            :string(255)
#  loxp_screen                   :string(255)
#  loss_of_allele                :string(255)
#  vector_integrity              :string(255)
#  southern_blot                 :string(255)
#  five_prime_lr_pcr             :string(255)
#  five_prime_cassette_integrity :string(255)
#  tv_backbone_assay             :string(255)
#  neo_count_qpcr                :string(255)
#  lacz_count_qpcr               :string(255)
#  neo_sr_pcr                    :string(255)
#  loa_qpcr                      :string(255)
#  homozygous_loa_sr_pcr         :string(255)
#  lacz_sr_pcr                   :string(255)
#  mutant_specific_sr_pcr        :string(255)
#  loxp_confirmation             :string(255)
#  three_prime_lr_pcr            :string(255)
#  critical_region_qpcr          :string(255)
#  loxp_srpcr                    :string(255)
#  loxp_srpcr_and_sequencing     :string(255)
#
