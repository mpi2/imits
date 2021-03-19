sql = "SELECT id FROM alleles WHERE mgi_allele_symbol_superscript LIKE 'em%'"

ids = ActiveRecord::Base.connection.execute(sql)

results = []

ids.each do |row|
  a = Allele.find(row['id'])
  a.audits.where("audit.audited_changes['mgi_allele_symbol_superscript'] is not null").each do |audit|
    results.push([a.gene.marker_symbol, a.colony.name, audit.audited_changes["mgi_allele_symbol_superscript"], audit["created_at"]])
  end
end

file = '/Users/albagomez/Documents/iMits/allele_em_name_changes.csv'
headers = ['gene', 'colony_name', 'name', 'date']

CSV.open( file, 'w' ) do |writer|
  writer << headers
  results.each do |c|
    writer << [c[0], c[1], c[2], c[3]]
  end
end

