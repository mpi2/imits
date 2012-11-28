class TargRep::Allele < ActiveRecord::Base
  acts_as_audited
  
  extend AccessAssociationByAttribute
  ##
  ## Associations
  ##
  belongs_to :mutation_method,  :class_name => "TargRep::MutationMethod"
  belongs_to :mutation_type,    :class_name => "TargRep::MutationType"
  belongs_to :mutation_subtype, :class_name => "TargRep::MutationSubtype"
  belongs_to :gene


  access_association_by_attribute :mutation_method,  :name
  access_association_by_attribute :mutation_type,    :name
  access_association_by_attribute :mutation_subtype, :name

  has_one    :genbank_file,      :dependent => :destroy, :class_name => "TargRep::GenbankFile"
  has_many   :targeting_vectors, :dependent => :destroy, :class_name => "TargRep::TargetingVector"
  has_many   :es_cells,          :dependent => :destroy, :class_name => "TargRep::EsCell" do
    def unique_public_info
      info_map = ActiveSupport::OrderedHash.new

      self.order('id ASC').each do |es_cell|
        key = {
          :strain => es_cell.strain,
          :allele_symbol_superscript => es_cell.allele_symbol_superscript,
          :ikmc_project_id => es_cell.ikmc_project_id.to_s
        }

        info_map[key] ||= {:pipelines => []}
        info_map[key][:pipelines].push(es_cell.pipeline.name)
      end

      info = info_map.map do |key, value|
        key.merge(:pipeline => value[:pipelines].first)
      end
      return info
    end
  end

  accepts_nested_attributes_for :genbank_file,      :allow_destroy  => true
  accepts_nested_attributes_for :targeting_vectors, :allow_destroy  => true
  accepts_nested_attributes_for :es_cells,          :allow_destroy  => true

  delegate :mgi_accession_id, :to => :gene

  ##
  ## Validations
  ##

  validates_uniqueness_of :project_design_id,
    :scope => [
      :gene_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ],
    :message => "must have unique design features"

  validates_presence_of [
    :assembly,
    :chromosome,
    :strand,
    :mutation_method,
    :mutation_type,
    :homology_arm_start,
    :homology_arm_end,
    :cassette_start,
    :cassette_end,
    :cassette,
    :cassette_type
  ]

  validates_inclusion_of :cassette_type,
    :in => ['Promotorless','Promotor Driven'],
    :message => "Cassette Type can only be 'Promotorless' or 'Promotor Driven'"

  validates_inclusion_of :strand,
    :in         => ["+", "-"],
    :message    => "should be '+' or '-'."

  validates_inclusion_of :chromosome,
    :in         => ('1'..'19').to_a + ['X', 'Y', 'MT'],
    :message    => "is not a valid mouse chromosome"

  validates_associated :mutation_method,
    :message    => "should be a valid mutation method"

  validates_associated :mutation_type,
    :message    => "should be a valid mutation type"

  validates_associated :mutation_subtype,
    :message    => "should be a valid mutation subtype"

  validates_format_of :floxed_start_exon,
    :with       => /^ENSMUSE\d+$/,
    :message    => "is not a valid Ensembl Exon ID",
    :allow_nil  => true

  validates_format_of :floxed_end_exon,
    :with       => /^ENSMUSE\d+$/,
    :message    => "is not a valid Ensembl Exon ID",
    :allow_nil  => true

  validates_numericality_of :homology_arm_start, :only_integer => true, :greater_than => 0
  validates_numericality_of :homology_arm_end,   :only_integer => true, :greater_than => 0
  validates_numericality_of :cassette_start,     :only_integer => true, :greater_than => 0
  validates_numericality_of :cassette_end,       :only_integer => true, :greater_than => 0
  validates_numericality_of :loxp_start,         :only_integer => true, :greater_than => 0, :allow_nil => true
  validates_numericality_of :loxp_end,           :only_integer => true, :greater_than => 0, :allow_nil => true

  validate :has_right_features, :unless => :missing_fields?

  validate :has_correct_cassette_type

  validates :gene, :presence => true

  ##
  ## Filters
  ##

#  before_validation :set_mutation_details_and_clean_blanks

  ##
  ## Methods
  ##

  def missing_fields?
    assembly.blank? &&
    chromosome.blank? &&
    strand.blank? &&
    mutation_type.blank? &&
    homology_arm_start.blank? &&
    homology_arm_end.blank? &&
    cassette_start.blank? &&
    cassette_end.blank?
  end

  public
    def to_json( options = {} )
      TargRep::Allele.include_root_in_json = false
      options.update(
        :include => {
          :es_cells => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :targeting_vectors => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :genbank_file => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
        }
      )

      super( options )
    end

    def to_xml( options = {} )
      options.update(
        :skip_types => true,
        :include => {
          :es_cells => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]},
          :targeting_vectors => { :except => [
              :allele_id,
              :created_at, :updated_at,
              :creator, :updater
          ]}
        }
      )
      super( options )
    end

    def targeted_trap?
      if self.mutation_type.targeted_non_conditional?
        return 'Yes'
      else
        return 'No'
      end
    end

    def pipeline_names
      pipelines = {}
      self.targeting_vectors.each { |tv| pipelines[tv.pipeline.name] = true } if self.targeting_vectors
      self.es_cells.each { |esc| pipelines[esc.pipeline.name] = true } if self.es_cells
      pipelines.keys.sort.join(', ')
    end

  protected

    def has_right_features
      error_msg = "cannot be greater than %s position on this strand (#{strand})"

      case strand
      when '+'
        if homology_arm_start > cassette_start
          errors.add( :homology_arm_start, error_msg % "cassette start" )
        end
        if cassette_start > cassette_end
          errors.add( :cassette_start, error_msg % "cassette end" )
        end
        # With LoxP site
        if loxp_start and loxp_end
          if cassette_end > loxp_start
            errors.add( :cassette_end, error_msg % "loxp start" )
          end
          if loxp_start > loxp_end
            errors.add( :loxp_start, error_msg % "loxp end" )
          end
          if loxp_end > homology_arm_end
            errors.add( :loxp_end, error_msg % "homology arm end" )
          end
        # Without LoxP site
        else
          if cassette_end > homology_arm_end
            errors.add( :cassette_end, error_msg % "homology arm end" )
          end
        end
      when '-'
        if homology_arm_start < cassette_start
          errors.add( :cassette_start, error_msg % "homology arm start" )
        end
        if cassette_start < cassette_end
          errors.add( :cassette_end, error_msg % "cassette start" )
        end
        # With LoxP site
        if loxp_start and loxp_end
          if cassette_end < loxp_start
            errors.add( :loxp_start, error_msg % "cassette end" )
          end
          if loxp_start < loxp_end
            errors.add( :loxp_end, error_msg % "loxp start" )
          end
          if loxp_end < homology_arm_end
            errors.add( :homology_arm_end, error_msg % "loxp end" )
          end
        # Without LoxP site
        else
          if cassette_end < homology_arm_end
            errors.add( :homology_arm_end, error_msg % "cassette end" )
          end
        end
      end

      if mutation_type && mutation_type.no_loxp_site?
        unless loxp_start.nil? and loxp_end.nil?
          errors.add(:loxp_start, "has to be blank for this mutation method")
          errors.add(:loxp_end,   "has to be blank for this mutation method")
        end
      end
    end

#    def set_mutation_details_and_clean_blanks
      # Set the mutation details
#      self.mutation_type = 'targeted_mutation'
#      self.mutation_subtype = case self.design_type
#        when 'Deletion'   then 'deletion'
#        when 'Insertion'  then 'insertion'
#        when 'Knock Out'  then self.loxp_start.nil? ? 'targeted_non_conditional' : 'conditional_ready'
#      end

#      if ['conditional_ready', 'insertion', 'deletion'].include? self.mutation_subtype
#        if self.design_subtype and self.design_subtype === 'domain'
#          self.mutation_method = 'domain_disruption'
#        else
#          self.mutation_method = 'frameshift'
#        end
#      end

      # Convert any blank strings to nil...
#      self.attributes.each do |name,value|
#        self.send("#{name}=".to_sym, nil) if value.is_a?(String) and value.empty?
#      end
#    end

    def has_correct_cassette_type
      known_cassettes = {
        'L1L2_6XOspnEnh_Bact_P'                        => 'Promotor Driven',
        'L1L2_Bact_P'                                  => 'Promotor Driven',
        'L1L2_Del_BactPneo_FFL'                        => 'Promotor Driven',
        'L1L2_GOHANU'                                  => 'Promotor Driven',
        'L1L2_hubi_P'                                  => 'Promotor Driven',
        'L1L2_Pgk_P'                                   => 'Promotor Driven',
        'L1L2_Pgk_PM'                                  => 'Promotor Driven',
        'PGK_EM7_PuDtk_bGHpA'                          => 'Promotor Driven',
        'pL1L2_PAT_B0'                                 => 'Promotor Driven',
        'pL1L2_PAT_B1'                                 => 'Promotor Driven',
        'pL1L2_PAT_B2'                                 => 'Promotor Driven',
        'TM-ZEN-UB1'                                   => 'Promotor Driven',
        'ZEN-Ub1'                                      => 'Promotor Driven',
        'ZEN-UB1.GB'                                   => 'Promotor Driven',
        'pL1L2_GT0_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT1_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT2_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'L1L2_gt0'                                     => 'Promotorless',
        'L1L2_gt1'                                     => 'Promotorless',
        'L1L2_gt2'                                     => 'Promotorless',
        'L1L2_gtk'                                     => 'Promotorless',
        'L1L2_NTARU-0'                                 => 'Promotorless',
        'L1L2_NTARU-1'                                 => 'Promotorless',
        'L1L2_NTARU-2'                                 => 'Promotorless',
        'L1L2_NTARU-K'                                 => 'Promotorless',
        'L1L2_st0'                                     => 'Promotorless',
        'L1L2_st1'                                     => 'Promotorless',
        'L1L2_st2'                                     => 'Promotorless',
        'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GTk_LacZ_BetactP_neo'      => 'Promotor Driven',
        'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT0_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT1_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT2_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT0_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT1_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT2_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GTK_nEGFPO_T2A_CreERT_puro'             => 'Promotorless',
      }

      unless known_cassettes[cassette].nil?
        if known_cassettes[cassette] != cassette_type
          errors.add( :cassette_type, "The cassette #{cassette} is a known #{known_cassettes[cassette]} cassette - please correct this field." )
        end
      end
    end

end

# == Schema Information
#
# Table name: targ_rep_alleles
#
#  id                  :integer         not null, primary key
#  gene_id             :integer
#  assembly            :string(50)      default("NCBIM37"), not null
#  chromosome          :string(2)       not null
#  strand              :string(1)       not null
#  homology_arm_start  :integer         not null
#  homology_arm_end    :integer         not null
#  loxp_start          :integer
#  loxp_end            :integer
#  cassette_start      :integer
#  cassette_end        :integer
#  cassette            :string(100)
#  backbone            :string(100)
#  subtype_description :string(255)
#  floxed_start_exon   :string(255)
#  floxed_end_exon     :string(255)
#  project_design_id   :integer
#  reporter            :string(255)
#  mutation_method_id  :integer
#  mutation_type_id    :integer
#  mutation_subtype_id :integer
#  cassette_type       :string(50)
#  created_at          :datetime
#  updated_at          :datetime
#
