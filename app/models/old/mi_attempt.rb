# encoding: utf-8

class Old::MiAttempt < Old::ModelBase

  EMMA_OPTIONS = {
      :unsuitable => 'Unsuitable for EMMA',
      :suitable => 'Suitable for EMMA',
      :suitable_sticky => 'Suitable for EMMA - STICKY',
      :unsuitable_sticky => 'Unsuitable for EMMA - STICKY',
    }.freeze

  set_table_name 'emi_attempt'

  # The include does not work in postgres, which seems to ignore it, and breaks
  # on oracle
  belongs_to :emi_event, :class_name => 'EmiEvent',
          :foreign_key => :event_id # , :include => [:clone]

  belongs_to :mi_attempt_status, :foreign_key => 'status_dict_id'

  delegate :clone, :proposed_mi_date, :distribution_centre, :production_centre, :to => :emi_event

  delegate :clone_name, :gene_symbol, :allele_name, :to => :clone

  scope :search, proc { |params|
    terms, production_centre_id = params.symbolize_keys.values_at(:search_terms, :production_centre_id)

    terms ||= []
    terms = terms.dup.delete_if {|i| i.strip.empty?}
    terms.map(&:upcase!)

    sql_texts = []
    sql_params = []

    unless terms.blank?
      sql_texts <<
              '(UPPER(emi_clone.clone_name) IN (?) OR ' +
              ' UPPER(emi_clone.gene_symbol) IN (?) OR ' +
              ' UPPER(colony_name) IN (?))'
      sql_params << terms << terms << terms
    end

    unless production_centre_id.blank?
      sql_texts << 'emi_event.centre_id = ?'
      sql_params << production_centre_id
    end

    if sql_texts.blank?
      scoped
    else
      sql_text = sql_texts.join(' AND ')
      joins(:emi_event => :clone).where(sql_text, *sql_params)
    end
  }

  scope :sort_by_clone_name, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.clone_name #{direction}")
  }

  scope :sort_by_gene_symbol, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.gene_symbol #{direction}")
  }

  scope :sort_by_allele_name, proc { |direction|
    joins(:emi_event => :clone).order("emi_clone.allele_name #{direction}")
  }

  scope :sort_by_mi_attempt_status, proc { |direction|
    joins(:mi_attempt_status).order("emi_status_dict.name #{direction}")
  }

  scope :sort_by_distribution_centre_name, proc { |direction|
    joins(:emi_event => :distribution_centre).order("per_centre.name #{direction}")
  }

  def distribution_centre_name
    return emi_event.distribution_centre.name
  end

  def emma?
    return (self.emma == '1')
  end

  def emma_status
    if emma?
      if is_emma_sticky? then return :suitable_sticky else return :suitable end
    else
      if is_emma_sticky? then return :unsuitable_sticky else return :unsuitable end
    end
  end

end


# == Schema Information
# Schema version: 20110421150000
#
# Table name: emi_attempt
#
#  id                             :decimal(, )     not null, primary key
#  is_active                      :boolean(1)
#  event_id                       :integer(38)
#  actual_mi_date                 :datetime
#  attempt_number                 :integer(38)
#  num_recipients                 :decimal(, )
#  num_blasts                     :string(4000)
#  created_date                   :datetime
#  creator_id                     :decimal(, )
#  edit_date                      :datetime
#  edited_by                      :string(128)
#  number_born                    :integer(38)
#  total_chimeras                 :integer(38)
#  number_male_chimeras           :integer(38)
#  number_female_chimeras         :integer(38)
#  date_chimera_mated             :datetime
#  number_chimera_mated           :integer(38)
#  number_chimera_mating_success  :integer(38)
#  date_f1_genotype               :datetime
#  number_male_100_percent        :integer(38)
#  number_male_gt_80_percent      :integer(38)
#  number_male_40_to_80_percent   :integer(38)
#  number_male_lt_40_percent      :integer(38)
#  number_with_glt                :integer(38)
#  comments                       :string(4000)
#  status_dict_id                 :integer(38)
#  num_transferred                :decimal(, )
#  number_with_cct                :string(4000)
#  total_f1_mice                  :decimal(, )
#  blast_strain                   :string(4000)
#  number_f0_matings              :decimal(, )
#  f0_matings_with_offspring      :decimal(, )
#  f1_germ_line_mice              :integer(10)
#  number_lt_10_percent_glt       :integer(10)
#  number_btw_10_50_percent_glt   :integer(10)
#  number_gt_50_percent_glt       :integer(10)
#  number_het_offspring           :integer(10)
#  number_100_percent_glt         :integer(10)
#  test_cross_strain              :string(200)
#  chimeras_with_glt_from_cct     :integer(10)
#  chimeras_with_glt_from_genotyp :integer(10)
#  colony_name                    :string(100)
#  europhenome                    :string(1)
#  emma                           :string(1)
#  mmrrc                          :string(1)
#  number_live_glt_offspring      :integer(10)
#  is_emma_sticky                 :boolean(1)
#  back_cross_strain              :string(100)
#  production_centre_mi_id        :string(100)
#  f1_black                       :integer(10)
#  f1_non_black                   :integer(10)
#  mouse_allele_name              :string(100)
#  qc_five_prime_lr_pcr           :string(20)
#  qc_three_prime_lr_pcr          :string(20)
#  qc_tv_backbone_assay           :string(20)
#  qc_loxp_confirmation           :string(20)
#  qc_southern_blot               :string(20)
#  qc_loa_qpcr                    :string(20)
#  qc_homozygous_loa_sr_pcr       :string(20)
#  qc_neo_count_qpcr              :string(20)
#  qc_lacz_sr_pcr                 :string(20)
#  qc_mutant_specific_sr_pcr      :string(20)
#  qc_five_prime_cass_integrity   :string(20)
#  qc_neo_sr_pcr                  :string(20)
#  is_public                      :boolean(1)      default(TRUE), not null
#  released_from_genotyping       :boolean(1)      default(FALSE), not null
#

