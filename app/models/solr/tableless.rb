class Solr::Tableless < Tableless

  def doc_to_tsv
    attr_values = self.class.attributes.map do |attr|
    
     attr_value = self.send(attr)
     if attr_value.class == Array
       attr_value.join('|')
     else
       attr_value.to_s
     end
    
    end

    return "#{attr_values.join('\t')}\n"
  end

  def self.tsv_header
    return "#{self.attributes.join('\t')}\n"
  end

end
