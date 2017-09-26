class ExtractJaxAlleleData

  def initialize
    alleles = Allele.joins(colony: [mi_attempt: [mi_plan: :production_centre]]).where("centres.name = 'JAX' AND allele_description IS NOT NULL")
    @allele_descriptions = alleles.map{|a| [a.id, a.allele_description.gsub("\r", '').gsub("\n", '')]}
    @descriptions_with_additional_mutations = @allele_descriptions.select{|a| /(addition|is also|there is a|there are)/.match(a[1])}

    @main_mutations = []
    @main_mutations_ids = []
    @additional_mutation_rule1 = []
    @additional_mutation_rule2 = []
    @additional_mutation_rule3 = []
    @additional_mutation_rule4 = []
    @additional_mutation_rule5 = []
    @additional_mutations_ids = []
  end

  def allele_descriptions
    @allele_descriptions
  end

  def main_mutations
    @main_mutations
  end

  def not_matched
    not_matched = []
    @allele_descriptions.each do |a|
      not_matched << a unless @main_mutations_ids.include?(a[0])
    end
    return not_matched
  end

  def not_matched_additional_mutations
    not_matched = []
    @descriptions_with_additional_mutations.each do |a|
      not_matched << a unless @main_mutations_ids.include?(a[0])
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

      md = extract_additional_mutation_rule4(a[1])
      if !md.blank?
        @additional_mutation_rule4 << [a, md]
        @additional_mutations_ids << a[0]
        next
      end

      md = extract_additional_mutation_rule5(a[1])
      if !md.blank?
        @additional_mutation_rule5 << [a, md]
        @additional_mutations_ids << a[0]
        next
      end

    end
  end

  def extract_main_mutation(allele_description)
    return /which resulted in a ([\d,]+)[ ]*bp(?: internal)? (deletion|insertion|del|ins)(?: in total)?[, ]*(?: beginning)?[ \(]*[ATGCatgc]*\)*(?: before the)?(?: in)?(?: spanning)?(?: around)?(?: flanking)?(?: of)?(?: across)?(?: including)? (exon|exons|intron|5' upstream sequence|5' UTR)?[ ]*\d*(?:\-\d)?(?: and \d+)?[,]*(?: [of \(]*ENSMUSE[\d]+[\)]*)?(?: beginning)?(?: at)?[ \(]*[ATGCatgc]*\)*[,]*(?: at)?[ ]*[cC]hromosome ([\dXYxy]+) (negative|positive|\+|\-) strand position ([\d,]+)/.match(allele_description)
  end

  def extract_additional_mutation_rule1(allele_description)
    return /addition there(?: are)?(?: is)?(?: another)?(?: a)? (\d+)[ ]*bp (deletion|insertion|del|ins) in (intron) \d+[ \(]*[ATGCatgc]*\)*(?: at)? [Cc]hromosome ([\dXYxy]+) (negative|positive|\+|\-) strand position[ ]+(\d+)/.match(allele_description)
  end

  def extract_additional_mutation_rule2(allele_description)
    return /addition there(?: are)?(?: is)?(?: another)?(?: a)?(?: an additional)? (\d+)[ ]*bp (deletion|insertion|del|ins)[ \(]*[ATGCatgc]*\)*(?: at)? position[ ]+(\d+)[ ]*bp[ ]*in (intron) \d+/.match(allele_description)
  end

  def extract_additional_mutation_rule3(allele_description)
    return  /addition there(?: are)?(?: is)?(?: another)?(?: a)?(?: small)? (\d+)[ ]*bp (deletion|insertion|del|ins) (\d+)?(?: bases)?[ ]*(after|before)/.match(allele_description)
  end

  def extract_additional_mutation_rule4(allele_description)
    return /(?:additional|also|another)(?: small)?(?: a)? (\d+)[ ]*bp[ \(]*[ATGCatgc]*\)* (insertion|deletion|del|ins) in(?: the)? (intron)/.match(allele_description)
  end

  def extract_additional_mutation_rule5(allele_description)
    return  /addition there are (2 small) (insertions) of (\d+) and (\d+)[ ]*bp in(?: the)? (intron)/.match(allele_description)
  end
end
