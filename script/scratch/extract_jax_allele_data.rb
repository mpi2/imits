class ExtractJaxAlleleData

  def initialize
    alleles = Allele.joins(colony: [mi_attempt: [mi_plan: :production_centre]]).joins("LEFT OUTER JOIN allele_annotations ON allele_annotations.allele_id = alleles.id").where("centres.name = 'JAX' AND allele_description IS NOT NULL AND allele_annotations.id IS NULL")
    @allele_descriptions = alleles.map{|a| [a.id, a.allele_description.gsub("\r", '').gsub("\n", '')]}
    @descriptions_with_additional_mutations = @allele_descriptions.select{|a| /(addition|is also|there is a|there are)/.match(a[1])}

    @main_mutations = []
    @main_mutations_ids = []
    @additional_mutation_rule1 = []
    @additional_mutation_rule2 = []
    @additional_mutation_rule3 = []
    @additional_mutation_rule4 = []
    @additional_mutation_rule5 = []
    @additional_mutation_rule6 = []
    @additional_mutations_ids = []
    @allele_annotations = {}

  end

  def allele_descriptions
    @allele_descriptions
  end

  def descriptions_with_additional_mutations
    @descriptions_with_additional_mutations
  end

  def allele_annotations
    @allele_annotations
  end

  def main_mutations
    @main_mutations
  end

  def additional_mutation_rule1
    @additional_mutation_rule1
  end

  def additional_mutation_rule2
    @additional_mutation_rule2
  end

  def additional_mutation_rule3
    @additional_mutation_rule3
  end

  def additional_mutation_rule4
    @additional_mutation_rule4
  end

  def additional_mutation_rule5
    @additional_mutation_rule5
  end

  def additional_mutation_rule6
    @additional_mutation_rule6
  end

  def convert_main_mutation_to_allele_annotation
    main_mutations.each do |allele_id, mm|
      @allele_annotations[allele_id] = {}
      mutation_length = mm[1].gsub(',', '').to_i
      mutation_type = translate_mutation_type(mm[2])
      nd_mutation_length = mm[3]
      nd_mutation_type = mm[4].blank? ? nil : translate_mutation_type(mm[4])
      nd_start_coord = nil
      nd_end_cord = nil
      chr = mm[6]
      strand = mm[7]
      start_coord = mm[8].gsub(',', '').to_i
      end_cord = nil

      raise "MISSING START COORDINATE FOR ALLELE #{allele_id}" if start_coord.blank?
      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}, #{mutation_type}:#{nd_mutation_type}" if mutation_type == nd_mutation_type
      end_cord = calculate_end_coorinate(strand, start_coord, mutation_length)

      unless nd_mutation_length.blank? || nd_mutation_type.blank?
        nd_start_coord = end_cord + 1
        nd_end_cord = calculate_end_coorinate(strand, nd_start_coord, nd_mutation_length)
      end

      @allele_annotations[allele_id]['main_mutations'] = annotation(mutation_type, chr, start_coord, end_cord, strand)
      @allele_annotations[allele_id]['nd_main_mutations'] = annotation(nd_mutation_type, chr, nd_start_coord, nd_end_cord, strand) unless nd_mutation_type.blank?
    end
  end

  def not_matched
    not_matched = []
    @allele_descriptions.each do |a|
      not_matched << a unless @main_mutations_ids.include?(a[0])
    end
    return not_matched
  end


  def convert_additional_mutation_rule1_to_allele_annotation
    additional_mutation_rule1.each do |allele, mm|
      allele_id = allele[0]
      @allele_annotations[allele_id] = {} unless @allele_annotations.has_key?(allele_id)
      mutation_length = mm[1].gsub(',', '').to_i
      mutation_type = translate_mutation_type(mm[2])
      chr = mm[4]
      strand = mm[5]
      start_coord = mm[6].gsub(',', '').to_i
      end_cord = nil

      raise "MISSING START COORDINATE FOR ALLELE #{allele_id}" if start_coord.blank?
      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?
      end_cord = calculate_end_coorinate(strand, start_coord, mutation_length)

      @allele_annotations[allele_id]['additional_mutation'] = annotation(mutation_type, chr, start_coord, end_cord, strand)
    end
  end


  def convert_additional_mutation_rule2_to_allele_annotation
    additional_mutation_rule2.each do |allele, mm|
      allele_id = allele[0]
      @allele_annotations[allele_id] = {} unless @allele_annotations.has_key?(allele_id)
      mutation_length = mm[1].gsub(',', '').to_i
      mutation_type = translate_mutation_type(mm[2])
      start_coord = mm[3].gsub(',', '').to_i
      end_cord = nil
      puts "ALLELE ID #{allele_id}"
      puts "MORE #{@allele_annotations[allele_id]}"
      chr = @allele_annotations[allele_id]['main_mutations'][:chr]
      strand = @allele_annotations[allele_id]['main_mutations'][:strand]

      raise "MISSING START COORDINATE FOR ALLELE #{allele_id}" if start_coord.blank?
      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?
      end_cord = calculate_end_coorinate(strand, start_coord, mutation_length)

      @allele_annotations[allele_id]['additional_mutation'] = annotation(mutation_type, chr, start_coord, end_cord, strand)
    end
  end


  def convert_additional_mutation_rule3_to_allele_annotation
    additional_mutation_rule3.each do |allele, mm|
      allele_id = allele[0]
      puts "ALLELE ID #{allele}"
      @allele_annotations[allele_id] = {} unless @allele_annotations.has_key?(allele_id)
      mutation_length = mm[1].gsub(',', '').to_i
      mutation_type = translate_mutation_type(mm[2])
      chr = @allele_annotations[allele_id]['main_mutations'][:chr]
      strand = @allele_annotations[allele_id]['main_mutations'][:strand]
      magnitute = mm[3].to_i
      direction = translate_direction(mm[4])

      raise "MISSING START COORDINATE FOR ALLELE #{magnitute}" if magnitute.blank? && direction != 'on'
      raise "MISSING MUTATION LENGTH FOR ALLELE #{direction}" if direction.blank?

      start_coord = calculate_coord(allele_id, direction, magnitute, mutation_length)

      raise "MISSING START COORDINATE FOR ALLELE #{allele_id}" if start_coord.blank?
      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?
      end_cord = calculate_end_coorinate(strand, start_coord, mutation_length)

      @allele_annotations[allele_id]['additional_mutation'] = annotation(mutation_type, chr, start_coord, end_cord, strand)
    end
  end


  def convert_additional_mutation_rule4_to_allele_annotation
    additional_mutation_rule4.each do |allele, mm|
      allele_id = allele[0]
      @allele_annotations[allele_id] = {} unless @allele_annotations.has_key?(allele_id)
      mutation_length = mm[1]
      mutation_type = translate_mutation_type(mm[2])
      chr = @allele_annotations[allele_id]['main_mutations'][:chr]

      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?

      @allele_annotations[allele_id]['additional_mutation'] = annotation(mutation_type, chr, 0, mutation_length -1, 'positive')
    end
  end

  def convert_additional_mutation_rule5_to_allele_annotation
    additional_mutation_rule5.each do |allele, mm|
      allele_id = allele[0]
      @allele_annotations[allele_id] = {} unless @allele_annotations.has_key?(allele_id)
      mutation_length = mm[3]
      nd_mutation_length = mm[4]
      mutation_type = translate_mutation_type(mm[2])
      chr = @allele_annotations[allele_id]['main_mutations'][:chr]
      strand = @allele_annotations[allele_id]['main_mutations'][:strand]

      raise "MISSING MUTATION LENGTH FOR ALLELE #{allele_id}" if mutation_length.blank?
      raise "MISSING 2ND MUTATION LENGTH FOR ALLELE #{allele_id}" if nd_mutation_length.blank?
      raise "MISSING CHROMOSOME FOR ALLELE #{allele_id}" if chr.blank?
      raise "NO CHROMOSOME MATCH FOR ALLELE #{allele_id}, #{chr}" unless ['X', 'Y', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19' ].include?(chr)
      raise "MISSING MUTATION TYPE FOR ALLELE #{allele_id}" if mutation_type.blank?

      @allele_annotations[allele_id]['additional_mutation'] = annotation(mutation_type, chr, 0, mutation_length -1, 'positive')
      @allele_annotations[allele_id]['nd_additional_mutation'] = annotation(mutation_type, chr, 0, nd_mutation_length -1, 'positive')

    end
  end

  def not_matched_additional_mutations
    not_matched = []
    @descriptions_with_additional_mutations.each do |a|
      not_matched << a unless @additional_mutations_ids.include?(a[0])
    end
    return not_matched
  end


  def extract_main_mutations
    @main_mutation = []
    @allele_descriptions.each do |a|
      extracted_mutations = extract_main_mutation(a[1])
      @main_mutations << [a[0], extracted_mutations] unless extracted_mutations.blank?
    end
    @main_mutations_ids = @main_mutations.map{|s| s[0]}
  end

  def extract_additional_mutations
    @additional_mutation_rule1 = []
    @additional_mutations_ids = []
    @allele_descriptions.each do |a|
      md = extract_additional_mutation_rule1(a[1])
      if !md.blank?
        @additional_mutation_rule1 << [a, md]
        @additional_mutations_ids << a[0]
        next
      end

      md = extract_additional_mutation_rule2(a[1])
      if !md.blank?
        @additional_mutation_rule2 << [a, md]
        @additional_mutations_ids << a[0]
        next
      end

      md = extract_additional_mutation_rule3(a[1])
      if !md.blank?
        @additional_mutation_rule3 << [a, md]
        @additional_mutations_ids << a[0]
        next
      end

#      md = extract_additional_mutation_rule4(a[1])
#      if !md.blank?
#        @additional_mutation_rule4 << [a, md]
#        @additional_mutations_ids << a[0]
#        next
#      end
#
#      md = extract_additional_mutation_rule5(a[1])
#      if !md.blank?
#        @additional_mutation_rule5 << [a, md]
#        @additional_mutations_ids << a[0]
#        next
#      end
#      md = extract_additional_mutation_rule6(a[1])
#      if !md.blank?
#        @additional_mutation_rule6 << [a, md]
#        @additional_mutations_ids << a[0]
#        next
#      end

    end
  end

  def annotation(mutation_type, chr, start_coord, end_cord, strand)
    raise "Annotation CANNOT BE GENERATED: MISSING DETAILS #{mutation_type}:#{chr}:#{start_coord}:#{end_cord}" if mutation_type.blank? || chr.blank? || start_coord.blank? || end_cord.blank?
    return {:mod_type => mutation_type,
            :chr => chr,
            :start => start_coord,
            :end => end_cord,
            :strand => strand,
            :ref_seq => mutation_type == 'del' ? 'N'*((end_cord - start_coord).abs + 3) : 'N',
            :alt_seq => mutation_type == 'ins' ? 'N'*((end_cord - start_coord).abs + 2) : 'NN'}
  end

  def translate_mutation_type(allele_type)
    return 'del' if ['deleted', 'deletion', 'del', 'indel'].include?(allele_type)
    return 'ins' if ['insertion', 'inserted','ins'].include?(allele_type)
    raise "MISSING TRANSLATION FOR ALLELE #{allele_type}"
  end

  def translate_direction(direction)
    return 'before' if ['before', '5-prime'].include?(direction)
    return 'after' if ['after', 'downstream','3-prime'].include?(direction)
    return 'on' if ['at', 'into'].include?(direction)
    raise "MISSING TRANSLATION FOR direction #{direction}"   
  end

  def calculate_coord(allele_id, direction, magnitute, mutation_length)
    strand = @allele_annotations[allele_id]['main_mutations'][:strand]
    main_start = @allele_annotations[allele_id]['main_mutations'][:start]
    main_end = @allele_annotations[allele_id]['main_mutations'][:end]

    if direction == 'before'
      if ['+','positive'].include?(strand)
        return main_start - magnitute.to_i - mutation_length +1
      elsif ['-', 'negative'].include?(strand)
        return main_start + magnitute.to_i + mutation_length -1
      end
      raise "COULD NOT MATCH STRAND #{strand}"
    elsif direction == 'after'
      if ['+','positive'].include?(strand)
        return main_end + magnitute.to_i
      elsif ['-', 'negative'].include?(strand)
        return main_end - magnitute.to_i
      end
      raise "COULD NOT MATCH STRAND #{strand}"
    elsif direction == 'on'
      return main_end   
    end
    raise "ALTERNATIVE DIRECTION GIVEN #{direction}"
  end

  def calculate_end_coorinate(strand, start_coord, mutation_length)
    if ['+','positive'].include?(strand)
      return start_coord.to_i + mutation_length.to_i - 1
    elsif ['-', 'negative'].include?(strand)
      return start_coord.to_i - mutation_length.to_i + 1
    end
    raise "COULD NOT MATCH STRAND #{strand}"
  end

  def extract_main_mutation(allele_description)
    allele_description = allele_description.gsub('single base', '1bp')
    return /which resulted in (?:a|an)?(?: disrupted deletion of)? ([\d,]+)[ ]*bp(?: internal)? (deletion|insertion|del|ins)(?: and[an ]*)?(\d+)?(?:[ ]*bp[ ]*[ \(]*[ATGCatgc]*\)*)?(deletion|insertion|del|ins)?(?: in total)?[, ]*(?: beginning)?[ \(]*[ATGCatgc]*\)*(?: before the)?(?: beginning)?(?: in)?(?: spanning)?(?: around)?(?: flanking)?(?: of)?(?: across)?(?: including)?[ ]*(exon|exons|intron|5' upstream sequence|5' UTR)?[ ]*\d*(?:\-\d)?(?: and \d+)?[,]*(?: [of \(]*ENSMUSE[\d]+[\)]*)?(?: \(exon \d+\))?(?: beginning)?(?: at)?[ \(]*[ATGCatgc]*\)*[,]*(?: at)?[ ]*[cC]hromosome ([\dXYxy]+) (negative|positive|\+|\-) strand(?: position)? ([\d,]+)/.match(allele_description)
  end

  def extract_additional_mutation_rule1(allele_description)
    return /addition there(?: are)?(?: is)?(?: another)?(?: a)? (\d+)[ ]*bp (deletion|insertion|del|ins) in (intron) \d+[ \(]*[ATGCatgc]*\)*(?: at)? [Cc]hromosome ([\dXYxy]+) (negative|positive|\+|\-) strand position[ ]+(\d+)/.match(allele_description)
  end

  def extract_additional_mutation_rule2(allele_description)
    return /addition there(?: are)?(?: is)?(?: another)?(?: a)?(?: an additional)? (\d+)[ ]*bp (deletion|insertion|del|ins)[ \(]*[ATGCatgc]*\)*(?: at)? position[ ]+(\d+)[ ]*bp[ ]*in (intron) \d+/.match(allele_description)
  end

  def extract_additional_mutation_rule3(allele_description)
    allele_description = allele_description.gsub('two', '2')
    allele_description = allele_description.gsub('four', '4')
    allele_description = allele_description.gsub('single', '1')
    allele_description = allele_description.gsub('retention', 'insertion at')
    allele_description = allele_description.gsub("5'", '5p')
    allele_description = allele_description.gsub("an indel", '1 bp indel')
    return  /(?:There|addition)?[,]*(?:al)?(?: there)?(?: are)?(?: is)?(?: also)?(?: another)?(?: a)?(?: small)? (\d+)[ ]*(?:bp|base pair|base)[ \(]*[ATGCatgc]*\)*(?: intronic)? (deleted|deletion|insertion|inserted|del|ins|indel)[ ,\(]*[ATGCatgc]*[-, :\d]*\)*(?: in)?(?: the)?(?: 5p)?(?: intron)?[,]* (\d+)?(?: bases)?(?: bp)?[ ]*(3-prime|5-prime|after|before|downstream|at|into)/.match(allele_description)
  end

  def extract_additional_mutation_rule4(allele_description)
    return /(?:additional|also|another)(?: small)?(?: a)? (\d+)[ ]*bp[ \(]*[ATGCatgc]*\)* (insertion|deletion|del|ins) in(?: the)? (intron)/.match(allele_description)
  end

  def extract_additional_mutation_rule5(allele_description)
    return  /addition there are (2 small) (insertions) of (\d+) and (\d+)[ ]*bp in(?: the)? (intron)/.match(allele_description)
  end

  def extract_additional_mutation_rule6(allele_description)
    return  /addition there(?: are)?(?: is)?(?: a)?(?: an)? (\d+)[ ]*bp (deletion|insertion|del|ins)[ \(]*[ATGCatgc]*\)* and (\d+)[ ]*bp (deletion|insertion|del|ins)[ \(]*[ATGCatgc]*\)* in(?: the)? intron (\d+)[ ]*bp (5-prime|after|before|downstream|at|into)/.match(allele_description)
  end

  def add_allele_annotations_to_imits
    allele_annotations.each do |allele_id, aas|
      aas.each do |key, aa|
        a = Allele::Annotation.new(aa)
        a.allele_id = allele_id
        if a.valid?
          a.save
        else
          raise "ERROR SAVING: #{a.errors.messages} #{allele_id}, #{aas}"
        end
      end
    end
  end
    
end
