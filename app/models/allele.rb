class Allele < ApplicationModel
  include ::Public::Serializable

  acts_as_audited
  acts_as_reportable


  FULL_ACCESS_ATTRIBUTES = %w{
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_symbol_superscript
    allele_type
    allele_subtype
    allele_description
    contains_lacZ
    mutant_fa
    production_centre_qc_attributes
  }

  READABLE_ATTRIBUTES = %w{
    id
    mgi_allele_accession_id
  } + FULL_ACCESS_ATTRIBUTES

  ALLELE_OPTIONS = {
    'a' => 'a - Knockout-first - Reporter Tagged Insertion',
    'b' => 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion',
    'c' => 'c - Knockout-First, Post-Flp - Conditional',
    'd' => 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter',
    'e' => 'e - Targeted Non-Conditional',
    'e.1' => 'e.1 - Promoter excision from tm1e mouse',
    "''" => "'' - Reporter Tagged Deletion",
    '.1' => '.1 - Promoter excision from Deletion/Point Mutation ',
    '.2' => '.2 - Promoter excision from Deletion/Point Mutation '
  }.freeze


  CRISPR_ALLELE_OPTIONS = {
    'Indel' => 'Indel - Cas9 Injection with one gRNA; result of from non-homology end-joining',
    'Deletion' => 'Deletion - Cas9 Injection with two or more gRNAs; result of non-homology end joining',
    'HR' => 'HR - Cas9 Injection; homology-directed repair using targeting vector(s)>200 nt/bp',
    'HDR' => 'HDR - Cas9 Injection; homology-directed repair using oligo(s)<201 nt/bp',
  }.freeze

  CRISPR_ALLELE_SUB_TYPE_OPTIONS = [
    'Indel',
    'Exon Deletion',
    'Intra-exdel deletion',
    'Inter-exdel deletion',
    'Whole-gene deletion',
    'Null reporter',
    'Conditional Ready',
    'Point Mutation'
  ].freeze

  TEMPLATE_CHARACTER = '@'

  attr_accessible(*FULL_ACCESS_ATTRIBUTES)

  belongs_to :es_cell, :class_name => 'TargRep::EsCell'
  belongs_to :colony, :class_name => 'Colony'

  has_one :production_centre_qc, :inverse_of => :allele, :dependent => :destroy

  has_many :annotations, :dependent => :destroy

  accepts_nested_attributes_for :production_centre_qc, :update_only =>true

### MODEL VALIDATION
  validates :allele_type, :inclusion => { :in => ALLELE_OPTIONS.keys + CRISPR_ALLELE_OPTIONS.keys }, :allow_nil => true
  validates :allele_subtype, :inclusion => { :in => CRISPR_ALLELE_SUB_TYPE_OPTIONS}, :allow_nil => true
  
  validate do |allele|
    if es_cell.blank? && colony.blank?
      allele.errors.add :base, 'An allele must be assigned to either a Colony or an ES Cell.'
    elsif !es_cell.blank? && !colony.blank?
      allele.errors.add :base, 'An allele cannot be assigned to both an ES Cell and a Colony.'
    end
    return true
  end

  validates_format_of :mgi_allele_accession_id,
    :with      => /^MGI\:\d+$/,
    :message   => "is not a valid MGI Allele ID",
    :allow_nil => true

  validates_format_of :mutant_fa,
    :with      => /^(>[\w\\+\?\.\*\^\$\(\)\[\]\{\}\|\\\/\-\'\" +=:;~@#&]+\n)?([ACGTNRYKMSWacgtnrykmsw]+\n$)/m,
    :message   => "is not a valid FASTA file format.",
    :allow_nil => true

  validate do |allele|
    return true if allele.mgi_allele_symbol_superscript.blank?

    if allele.mgi_allele_symbol_superscript =~ /^tm/
      return true if allele.mgi_allele_symbol_superscript =~ /^(tm\d+)([a-e]|.\d+|e.\d+)?(\(\w+\))?\w+$/
      allele.errors.add :mgi_allele_symbol_superscript, 'invalid format for targeted mutation (tm). Here are some examples of valid mgi_allele_symbol_superscripts tm1a(KOMP)Wtsi, tm1aWtsi, tm2b(EUCOMM)Hmgu.'
    elsif allele.mgi_allele_symbol_superscript =~ /^Gt/
      return true if allele.mgi_allele_symbol_superscript =~ /^(Gt)(\(\w+\))?\w+$/
      allele.errors.add :mgi_allele_symbol_superscript, 'invalid format for Gene Trap (Gt). Here are some examples of valid mgi_allele_symbol_superscripts Gt(IST12471H5)Wtsi, GtHmgu.'
    elsif allele.mgi_allele_symbol_superscript =~ /^em/
      if allele.mgi_allele_symbol_without_impc_abbreviation
        return true if allele.mgi_allele_symbol_superscript =~ /^(em\d+)\w+$/
        allele.errors.add :mgi_allele_symbol_superscript, 'invalid format for endonuclease mutation (em). Here are some examples of valid mgi_allele_symbol_superscripts em1Wtsi, em2Hmgu.'
      else
        return true if allele.mgi_allele_symbol_superscript =~ /^(em\d+)(\(\w+\))\w+$/
        allele.errors.add :mgi_allele_symbol_superscript, 'invalid format for endonuclease mutation (em). Here are some examples of valid mgi_allele_symbol_superscripts em1(IMPC)Wtsi, em2(IMPC)Hmgu.'
      end
    else
      allele.errors.add :mgi_allele_symbol_superscript, 'invalid format.'
    end
      
    return false
  end

### CALLBACKS

  before_validation do |allele|
    return if allele.mutant_fa.blank?

    md = /^(>[\w\\+\?\.\*\^\$\(\)\[\]\{\}\|\\\/\-\'\" +=:;~@#&]+\n)?([\w\n\+\?\.\*\^\$\(\)\[\]\{\}\|\\\/ -+=:;'"~@#&]+$)/m.match(allele.mutant_fa.gsub("\r", ""))

    allele.mutant_fa = md[1].to_s + md[2].gsub("\n", '').to_s.gsub(" ", "").upcase + "\n"
  end

  before_validation do |allele|
    return true if allele.production_centre_qc.blank?
    return true if allele.colony.blank? || allele.colony.mi_attempt.blank? || allele.colony.mi_attempt.es_cell_id.blank?
    return true if allele.colony.mi_attempt.es_cell.allele.mutation_type.try(:code) == 'cki'

    es_cell_allele = allele.colony.mi_attempt.es_cell.alleles[0]

    if allele.production_centre_qc.loxp_confirmation == 'fail' && es_cell_allele.allele_type == 'a'
      allele.allele_type = 'e'
    elsif allele.allele_type == 'e' and (allele.production_centre_qc.loxp_confirmation == 'pass')
      allele.allele_type = 'a'
    end
    return true
  end

  before_validation do |allele|
  # set_default_production_qc
    if allele.production_centre_qc.blank?
      # TO DO should create a new allele for each mutagenesis_factor or one if es_cell_id is not blank
       production_centre_qc_attr = {}
       allele.production_centre_qc_attributes = production_centre_qc_attr
     end
     return true
  end

  before_validation do |allele|
    # auto_assign_allele_for_es_cells
    if allele.belongs_to_es_cell?
      design_allele = allele.es_cell.allele
      allele.genbank_file_id = design_allele.allele_genbank_file_id
      if allele.mgi_allele_symbol_superscript.blank?
        allele.allele_type = design_allele.mutation_type.allele_code
      else
        extacted = allele.class.extract_symbol_superscript_template(allele.mgi_allele_symbol_superscript)
        allele.allele_type = extacted[1]
        allele.allele_symbol_superscript_template = extacted[0]
      end
    elsif allele.belongs_to_colony?
    # Check how allele was created
      # Created by Micro-injection of ES CELL
      if !allele.colony.mi_attempt.blank? && !allele.colony.mi_attempt.es_cell_id.blank?
        es_cell = allele.colony.mi_attempt.es_cell
        if allele.allele_type.blank? || allele.allele_type == es_cell.alleles[0].allele_type
          allele.same_as_es_cell = true
          allele.allele_type = es_cell.alleles[0].allele_type
          allele.genbank_file_id = es_cell.alleles[0].genbank_file_id
          allele.mgi_allele_symbol_superscript = es_cell.alleles[0].mgi_allele_symbol_superscript
          allele.allele_symbol_superscript_template = es_cell.alleles[0].allele_symbol_superscript_template
          allele.mgi_allele_accession_id = es_cell.alleles[0].mgi_allele_accession_id
        else
          allele.same_as_es_cell = false
          
          # Questionable whether we shoud do this. Maybe best to have nothing.
          sql = <<-EOF
            SELECT a1.*
            FROM targ_rep_alleles AS a1
              JOIN targ_rep_mutation_types ON targ_rep_mutation_types.id = a1.mutation_type_id
            WHERE 
              a1.cassette = '#{es_cell.allele.cassette}' AND
              a1.homology_arm_start = #{es_cell.allele.homology_arm_start} AND
              a1.homology_arm_end = #{es_cell.allele.homology_arm_end} AND
              a1.cassette_start = #{es_cell.allele.cassette_start} AND
              a1.cassette_end = #{es_cell.allele.cassette_end} AND
              a1.id != #{es_cell.allele_id} AND
              targ_rep_mutation_types.allele_code = '#{allele.allele_type}'
          EOF
          targ_rep_alleles = TargRep::Allele.find_by_sql(sql)

          allele.genbank_file_id = targ_rep_alleles[0].allele_genbank_file_id if targ_rep_alleles.length >= 1

          allele.mgi_allele_accession_id = nil if allele.mgi_allele_accession_id == es_cell.alleles[0].mgi_allele_accession_id 
          if allele.mgi_allele_accession_id.blank?
            allele.allele_symbol_superscript_template = es_cell.alleles[0].allele_symbol_superscript_template
            allele.mgi_allele_symbol_superscript = es_cell.alleles[0].allele_symbol_superscript_template.gsub(/\@/, allele.allele_type.to_s.gsub("''", ''))
          else
            extacted = allele.class.extract_symbol_superscript_template(allele.mgi_allele_symbol_superscript)
            allele.allele_type = extacted[1]
            allele.allele_symbol_superscript_template = extacted[0]
          end
         

        end
      # Created by mouse allele mod
      elsif !allele.colony.mouse_allele_mod.blank? && !allele.colony.mouse_allele_mod.parent_colony.mi_attempt.es_cell_id.blank? 
        if !allele.allele_type.blank?
          parent_colony_allele = allele.colony.mouse_allele_mod.parent_colony.alleles[0]
  
          allele.genbank_file_id = parent_colony_allele.genbank_file_id
          if allele.mgi_allele_accession_id.blank?
            allele.allele_symbol_superscript_template = parent_colony_allele.allele_symbol_superscript_template
            allele.mgi_allele_symbol_superscript = parent_colony_allele.allele_symbol_superscript_template.gsub(/\@/, allele.allele_type.to_s.gsub("''", ''))
          else
            extacted = allele.class.extract_symbol_superscript_template(allele.mgi_allele_symbol_superscript)
            allele.allele_type = extacted[1]
            allele.allele_symbol_superscript_template = extacted[0]
          end

        end
      end
    end
    return true
  end

  before_validation do |allele|
    if allele.changed.include?('vcf_file')
      allele.annotations.delete
    end
  end

  after_save do |allele|
    if !allele.vcf_file.blank? && allele.annotations.blank?
      vcf_file = get_vcf_file.read.split("\n").select{|vcf| vcf[0] != '#'}

      index = {'CHROM' => 0, 'POS' => 1, 'ID' => 2, 'REF' => 3, 'ALT' => 4, 'QUAL' => 5, 'FILTER' => 6, 'INFO' => 7}
      index_bcsq = {'consequence' => 0, 'gene' => 1, 'transcript' => 2, 'biotype' => 3, 'strand' => 4, 'amino_acid_change' => 5, 'dna_change' => 6}
      vcf_file.each do |vcf_line|
        vcf_data = vcf_line.split("\t")
        info = vcf_data[ index['INFO'] ].split(";").map{|info_string| i = info_string.split("="); [i[0], i[1]]}.to_h
        bcsq = info['BCSQ']
        bcsq_transcripts = []
        bcsq_linked = ''
        downstream_of_stop = false
        if bcsq.blank?
        elsif bcsq[0] == '@'
          bcsq_linked = bcsq[1..-1]
        elsif bcsq[0] == '*'
          downstream_of_stop = true
        else
          bcsq_transcripts = bcsq.split(',')
        end
        amino_acid_consequence = {}
        bcsq_transcripts.each do |tran| 
          tran_fields = tran.split{'|'}
          next if tran_fields.length < 7
          amino_acid_consequence[tran_fields[ index_bcsq['amino_acid_change'] ]] = [] if !amino_acid_consequence.has_key?(tran_fields[ index_bcsq['amino_acid_change'] ])
          amino_acid_consequence[tran_fields[ index_bcsq['amino_acid_change'] ]] << amino_acid_consequence[tran_fields[ index_bcsq['transcript'] ]]
        end

        amino_acid_str = ''
        amino_acid_str = amino_acid_consequence.map{|aac, transcripts| ">#{transcripts.join('&')}\n#{aac}" }.join("\n")


        chromosome = vcf_data[ index['CHROM'] ]
        start_pos = vcf_data[ index['POS'] ]
        end_pos = info.has_key?('END') ? info['END'] : start_pos
        sv_type = info['SVTYPE']
        ref = vcf_data[ index['REF'] ]
        alt = vcf_data[ index['ALT'] ]
        
        splice_acceptor = bcsq =~ /splice_acceptor/
        splice_donor = bcsq =~ /splice_donor/
        protein_coding = bcsq =~ /protein_coding/
        intron = bcsq =~ /intron/
        retained_intron = bcsq =~ /retained_intron/
        frameshift = bcsq =~ /frameshift/
        inframe_deletion = bcsq =~ /inframe_deletion/
        inframe_insertion = bcsq =~ /inframe_insertion/
        stop_gained = bcsq =~ /stop_gained/
        three_prime = bcsq =~ /3_prime_utr/
        nmd = bcsq =~ /NMD/
        txc = info['TXC'].split(',') if info.has_key?('TXC')
        
        if sv_type.blank?
          sv_type = 'SNP' if ref.length == alt.length
          sv_type = 'INDEL' if ref.length > alt.length
          sv_type = 'INS' if ref.length < alt.length
        end
        raise 'Missing SV_TYPE' if sv_type.blank?

        exdels = '' # comma separated list of ensembl exons deleted
        partial_exdels = '' # comma separated list of ensembl exons that have been partially deleted

        allele.annotations.create({
          :mod_type => sv_type,
          :chr => chromosome,
          :start => start_pos,
          :end => end_pos,
          :ref_seq => ref,
          :alt_seq => alt,
          :linked_concequence => !bcsq_linked.blank? ? bcsq_linked : '',
          :downstream_of_stop => downstream_of_stop,
          :exdels => exdels,
          :partial_exdels => partial_exdels,
          :splice_donor => splice_donor.blank? ? false : true,
          :splice_acceptor => splice_acceptor.blank? ? false : true,
          :protein_coding_region => protein_coding.blank? ? false : true,
          :stop_gained => stop_gained.blank? ? false : true,
          :intronic => intron.blank? ? false : true,
          :frameshift => frameshift.blank? ? false : true,
          :amino_acid => amino_acid_str,
          :txc => txc.blank? ? '' : "#{txc[0]}:{txc[1]}-{txc[2]}"
          })
      end
    end
  end


  before_save do |allele|
    if allele.changed.include?('mutant_fa')
      allele.annotations.delete
    end
  end


  after_save do |allele|
    # sync downstream alleles
    if allele.belongs_to_es_cell?
      mi_cols = Colony.joins(:mi_attempt, :alleles).where("mi_attempts.es_cell_id = #{allele.es_cell_id} AND alleles.same_as_es_cell = true")
      mi_cols.each do |mi_col|
        next if mi_col.alleles.count > 1
        mi_allele = Allele.find(mi_col.alleles.first.id)
        mi_allele.genbank_file_id = allele.genbank_file_id
        mi_allele.mgi_allele_symbol_superscript = allele.mgi_allele_symbol_superscript
        mi_allele.allele_symbol_superscript_template = allele.allele_symbol_superscript_template
        mi_allele.mgi_allele_accession_id = allele.mgi_allele_accession_id
        mi_allele.allele_type = allele.allele_type

        if mi_allele.changed?
          mi_allele.save
        end
      end

    elsif allele.belongs_to_colony?
      mam_cols = Colony.joins(:mouse_allele_mod).where("mouse_allele_mods.parent_colony_id = #{allele.colony.id}")
      mam_cols.each do |mam_col|
        next if mam_col.alleles.count > 1
        mam_allele = Allele.find(mam_col.alleles.first.id)
        mam_allele.genbank_file_id = allele.genbank_file_id
        if mam_allele.mgi_allele_accession_id.blank? && !mam_allele.allele_type.blank?
          mam_allele.allele_symbol_superscript_template = allele.allele_symbol_superscript_template
          mam_allele.mgi_allele_symbol_superscript = allele.allele_symbol_superscript_template.gsub(/\@/, mam_allele.allele_type.to_s.gsub("''", ''))     
        end
        if mam_allele.changed?
          mam_allele.save
        end
      end
    else
      raise 'This should not be possible'
    end
  end

  def belongs_to_es_cell?
    return true unless es_cell.blank?
    return false
  end

  def belongs_to_colony?
    return true unless colony.blank?
    return false
  end

  def gene
    return es_cell.gene unless es_cell.blank?
    return colony.gene unless colony.blank?
    return nil
  end

  def marker_symbol
    gene.try(:marker_symbol)
  end

  def allele_symbol
    return "#{marker_symbol}<sup>#{mgi_allele_symbol_superscript}</sup>" unless mgi_allele_symbol_superscript.blank?
    return nil
  end

  def production_centre_qc_attributes
    json_options = {
    :except => ['id', 'allele_id']
    }
    return production_centre_qc.as_json(json_options)
  end

  def get_vcf_file
    return nil if vcf_file.empty?
    f = StringIO.new(vcf_file)
    Zlib::GzipReader.new(f)
  end

  def self.extract_symbol_superscript_template(mgi_allele_symbol_superscript)
    return [nil, nil] if mgi_allele_symbol_superscript.blank?

    symbol_superscript_template = nil
    type = nil

    md = /\A(tm\d+|em\d+|Gt)([a-e]|.\d+|e.\d+)?(\([\w\/]+\))?(\w+)\Z/.match(mgi_allele_symbol_superscript)

    if md
      if 'tm' == md[1][0..1]
        symbol_superscript_template = md[1].to_s + TEMPLATE_CHARACTER + md[3].to_s + md[4].to_s
        type = md[2].blank? ? "''" : md[2]
      else
        symbol_superscript_template = nil
        type = nil
      end
    else
      raise "Bad allele symbol superscript '#{mgi_allele_symbol_superscript}'"
    end

    return [symbol_superscript_template, type]
  end

  def self.allele_description (options)
    marker_symbol = options.has_key?('marker_symbol') ? options['marker_symbol'] : nil
    cassette       = options.has_key?('cassette') ? options['cassette'] : nil
    allele_type   = options.has_key?('allele_type') ? options['allele_type'] : nil
    allele_subtype   = options.has_key?('allele_subtype') ? options['allele_subtype'] : nil

    return '' if allele_type.nil?

    allele_descriptions = { 'tma'     => "KO first allele (reporter-tagged insertion with conditional potential)",
                              'tme'     => "Targeted, non-conditional allele",
                              'tme.1'   => "Targeted, non-conditional allele (post-Cre)",
                              'tm'      => "Reporter-tagged deletion allele (with selection cassette)",
                              'tmb'     => "Reporter-tagged deletion allele (post-Cre)",
                              'tm.1'    => "Reporter-tagged deletion allele (post Cre, with no selection cassette)",
                              'tmc'     => "Wild type floxed exon (post-Flp)",
                              'tm.2'    => "Reporter-tagged deletion allele (post Flp, with no reporter and selection cassette)",
                              'tmd'     => "Deletion allele (post-Flp and Cre with no reporter)",
                              'tmCreSC' => "Cre driver allele (with selection cassette)",
                              'tmCre'   => "Cre driver allele",
                              'tmCGI'   => "Truncation cassette with conditional potential (selection cassette)",
                              'tmCGI-cre'   => "Truncated CpG island (post-Cre)",
                              'tmCGI-flp'   => "Wild type floxed CpG island (post-Flp)",
                              'tmCGI-dre'   => "Truncation cassette  with conditional potential (post-Dre, with no selection cassette)",
                              'gt'      => "Gene Trap",
                              'Gene Trap' => "Gene Trap",
                              'Indel'     => "Indel causing a Frameshift Mutation",
                              'Deletion' => "#{if !allele_subtype.blank?; allele_subtype; else; "Exdel"; end;}",
                              'HDR'      => "#{if !allele_subtype.blank?; allele_subtype; else; "Point Mutation"; end;}",
                              'HR'       => "#{if !allele_subtype.blank?; allele_subtype; else; "Conditional Ready / Null reporter"; end;}"
                            }

    return allele_descriptions['tmCGI'] if !marker_symbol.blank? && marker_symbol =~ /Cpgi/ && allele_type == "''"
    return allele_descriptions['tmCGI-cre'] if !marker_symbol.blank? && marker_symbol =~ /Cpgi/ && allele_type == '.1'
    return allele_descriptions['tmCGI-flp'] if !marker_symbol.blank? && marker_symbol =~ /Cpgi/ && allele_type == '.2'
    return allele_descriptions['tmCGI-dre'] if !marker_symbol.blank? && marker_symbol =~ /Cpgi/ && allele_type == '.3'

    return allele_descriptions['tma'] if allele_type == 'a'
    return allele_descriptions['tmb'] if allele_type == 'b'
    return allele_descriptions['tmc'] if allele_type == 'c'
    return allele_descriptions['tmd'] if allele_type == 'd'
    return allele_descriptions['tme'] if allele_type == 'e'
    return allele_descriptions['gt'] if allele_type == 'gt'
    return allele_descriptions['Indel'] if allele_type == 'Indel'
    return allele_descriptions['Deletion'] if allele_type == 'Deletion'
    return allele_descriptions['HDR'] if allele_type == 'HDR'
    return allele_descriptions['HR'] if allele_type == 'HR'

    if !cassette.blank? && cassette =~ /Cre/
      return allele_descriptions['tmCreSC'] if allele_type == "''"
      return allele_descriptions['tmCre'] if allele_type == '.1'
    end

    return allele_descriptions['tm'] if allele_type == "''"
    return allele_descriptions['tm.1'] if allele_type == '.1'
    return allele_descriptions['tm.2'] if allele_type == '.2'

  end

  def self.allowed_to_be_blank
    return ['bam_file', 'bam_file_index', 'vcf_file', 'vcf_file_index']
  end

  def self.generate_allele_description(options)
    raise 'allele_id must be provided' if !options.has_key?('allele_id')
    allele = Allele.find(options['allele_id'])
    raise 'invalid allele id provided' if allele.blank?

    annotations = allele.annotations
    raise 'Cannot generate allele description if there are no annotations' if annotations.blank?

    colony = allele.colony
    mi_attempt = colony.mi_attempt
    raise 'cannot set allele description for colonies not produced via cripsr mi' if mi_attempt.blank? || mi_attempt.mutagenesis_factor_id.blank?

    mutagenesis_factor = mi_attempt.mutagenesis_factor
    cripsrs = mutagenesis_factor.crisprs
    donors = mutagenesis_factor.donors
    centre_name = mi_attempt.mi_plan.production_centre.full_name

    nuclease = 'Cas9'
    if !mi_attempt.protein_nuclease.blank?
      nuclease = "#{mi_attempt.protein_nuclease} Protein"
    elsif !mi_attempt.mrna_nuclease.blank?
      nuclease = "#{mi_attempt.mrna_nuclease} RNA"
    end

    grna_str = ''
    grna_str << 's ' if crisprs.length > 1
    grna_str << crisprs.map{|c| c.sequence}.to_sentence


    donor_str = ''
    if donors.select{|d| !d.oligo_sequence_fa.blank?}.length == donors.length
      donor_str = 'the following donor'
      donor_str << 's ' if donors.length > 1 
      donor_str << donors.map{|c| c.oligo_sequence_fa}.to_sentence
    else
      donor_str = "#{donors.length} donor"
      donor_str << 's ' if donors.length > 1 
    end

    mutagenesis_factor_array = ["#{nuclease}", "guide sequence#{grna_str}"]
    mutagenesis_factor_array << donor_str if !donors.blank?

    target_region = [crisprs.map{|c| c.start}.min , crisprs.map{|c| c.end}.max]

    mutations = []
    upstream_mutations = []
    downstream_mutations =[]
    cause = ''

    annotations.sort{|a1, a2| (a1.end - a1.start) <=> (a2.end - a1.start) }

    allele_description = "This allele from IMPC was generated at #{centre_name} by injecting #{mutagenesis_factor_array.to_sentence}, which resulted in a"
  end

end

# == Schema Information
#
# Table name: alleles
#
#  id                                          :integer          not null, primary key
#  es_cell_id                                  :integer
#  allele_confirmed                            :boolean          default(FALSE), not null
#  mgi_allele_symbol_without_impc_abbreviation :boolean
#  mgi_allele_symbol_superscript               :string(255)
#  allele_symbol_superscript_template          :string(255)
#  mgi_allele_accession_id                     :string(255)
#  allele_type                                 :string(255)
#  genbank_file_id                             :integer
#  created_at                                  :datetime         not null
#  updated_at                                  :datetime         not null
#  colony_id                                   :integer
#  auto_allele_description                     :text
#  allele_description                          :text
#  mutant_fa                                   :text
#  genbank_transition                          :string(255)
#  same_as_es_cell                             :boolean
#  allele_subtype                              :string(255)
#  contains_lacZ                               :boolean          default(FALSE)
#  bam_file                                    :binary
#  bam_file_index                              :binary
#  vcf_file                                    :binary
#  vcf_file_index                              :binary
#
