class Gene::PrivateAnnotation < ActiveRecord::Base

  belongs_to :gene

  def self.load_annoations
    idg_config = "#{Rails.root}/config/idg_symbols.yml"
    cmg_tier1_config = "#{Rails.root}/config/cmg_tier1_symbols.yml"
    cmg_tier2_config = "#{Rails.root}/config/cmg_tier2_symbols.yml"

    genes = {}

    if File.file?(idg_config)
      idg_gene_list = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
      sql = 'SELECT genes.marker_symbol FROM genes JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id WHERE gpa.idg = true'
      remove_idg_genes = ActiveRecord::Base.connection.execute(sql).map{|g| g['marker_symbol']}

      if !idg_gene_list.blank?
        idg_gene_list.each do |gene|
          genes[gene] = {} unless genes.has_key?(gene)
          genes[gene][:idg] = true
          remove_idg_genes.delete(gene)
        end
      end

      remove_idg_genes.each do |gene|
        genes[gene] = {} unless genes.has_key?(gene)
        genes[gene][:idg] = false
      end
    else
        puts "IDG File not found"
    end
  
    if File.file?(cmg_tier1_config)
      cmg_tier1_gene_list = YAML.load_file("#{Rails.root}/config/cmg_tier1_symbols.yml")
      sql = 'SELECT genes.marker_symbol FROM genes JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id WHERE gpa.cmg_tier1 = true'
      remove_cmg_tier1_genes = ActiveRecord::Base.connection.execute(sql).map{|g| g['marker_symbol']}

      if !cmg_tier1_gene_list.blank?
        cmg_tier1_gene_list.each do |gene|
          genes[gene] = {} unless genes.has_key?(gene)
          genes[gene][:cmg_tier1] = true
        end
      end

      remove_cmg_tier1_genes.each do |gene|
        genes[gene] = {} unless genes.has_key?(gene)
        genes[gene][:cmg_tier1] = false
      end
    else
        puts "CMG tier1 File not found"
    end

    if File.file?(cmg_tier2_config)
      cmg_tier2_gene_list = YAML.load_file("#{Rails.root}/config/cmg_tier2_symbols.yml")
      sql = 'SELECT genes.marker_symbol FROM genes JOIN gene_private_annotations gpa ON gpa.gene_id = genes.id WHERE gpa.cmg_tier2 = true'
      remove_cmg_tier2_genes = ActiveRecord::Base.connection.execute(sql).map{|g| g['marker_symbol']}

      if !cmg_tier2_gene_list.blank?
        cmg_tier2_gene_list.each do |gene|
          genes[gene] = {} unless genes.has_key?(gene)
          genes[gene][:cmg_tier2] = true
        end
      end

      remove_cmg_tier2_genes.each do |gene|
        genes[gene] = {} unless genes.has_key?(gene)
        genes[gene][:cmg_tier2] = false
      end
    else
        puts "CMG tier2 File not found"
    end

    genes.each do |gene, params|
      search_for_gpa_model = Gene::PrivateAnnotation.joins(:gene).where("marker_symbol = '#{gene}'")
      next if search_for_gpa_model.blank? || search_for_gpa_model.length > 1
      gpa = Gene::PrivateAnnotation.find(search_for_gpa_model.first.id)
      gpa.update_attributes(params)
    end
  end

end

# == Schema Information
#
# Table name: gene_private_annotations
#
#  id        :integer          not null, primary key
#  gene_id   :integer          not null
#  idg       :boolean          default(FALSE)
#  cmg_tier1 :boolean          default(FALSE)
#  cmg_tier2 :boolean          default(FALSE)
#
