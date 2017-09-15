class FastaFileUpload

  def initialize(upload_file)
    raise "Please specify upload file" if upload_file.blank?
    @fasta_file = open(upload_file, 'r')
    @loaded_data = []
  end

  def fasta_files
    @loaded_data
  end

  def read_data
    @loaded_data = []
    @fasta_file.each do |line|
        data = line[1..-1].split(',').map{|a| a.strip}
        ids = data[0].split('_')
        gene = ids[1].strip if ids.length >= 2
        colony_name = ids[0].strip.upcase
        mi_attempt_id = ids[2].strip if ids.length == 3
     
#        next if [16136, 16282].include?(mi_attempt_id.to_i)
    
        colony = Colony.where("mi_attempt_id IS NOT NULL AND (UPPER(trim(both from name)) = '#{colony_name}' OR UPPER(trim(both from name)) = '#{colony_name.gsub('H-', '')}' OR UPPER(trim(both from name)) = '#{colony_name.gsub('-B6N', '')}' )")
        raise "Missing colony #{colony_name} for mi_attempt_id #{mi_attempt_id}" if colony.blank? || colony.length > 1
        colony = colony.first

        raise "mi_attempt_id does not match #{mi_attempt_id}, #{colony.mi_attempt_id}" if !mi_attempt_id.blank? && mi_attempt_id.to_i != colony.mi_attempt_id.to_i
        raise "gene does not match #{gene} #{colony.marker_symbol}" if !gene.blank? && gene.upcase != colony.marker_symbol.to_s.upcase 
        raise "Allele Sequence contains unexpected characters #{data[1]} for colony #{colony_name}" if data[1] !~ /^[AGCTNagctn]+$/
        raise "more than one allele #{colony_name} for mi_attempt #{mi_attempt_id}" if colony.alleles.blank? || colony.alleles.length > 1
    
        allele = Allele.find_by_colony_id(colony.id)

        unless allele.mutant_fa.blank?
          puts "fasta sequence already exists for #{colony_name} for mi_attempt #{mi_attempt_id}"
          next
        end

        @loaded_data << [allele, data[1]]
    end
  end

  def upload_fasta_files
    raise "Data has not been loaded" if fasta_files.blank?
    Audit.as_user(User.find_by_email('pm9@ebi.ac.uk')) do
      fasta_files.each do |allele, fasta_file|
        allele.mutant_fa = fasta_file
        raise "allele validation failed for #{colony_name} for mi_attempt #{mi_attempt_id}" unless allele.valid?
        allele.save
      end
    end
  end

end
