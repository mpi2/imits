#!/usr/bin/env ruby

require 'pp'

def check_genes genes
  missing = []
  genes.each do |marker_symbol|
    sql = "select * from genes where marker_symbol ilike '#{marker_symbol}'"
    rows = ActiveRecord::Base.connection.execute(sql)
    missing.push marker_symbol if ! rows.first
  end

  pp missing

  puts "#### missing: #{missing.size}"
end

def load_csv filename, use_alternate = true
  lines = []
  genes = []
  CSV.foreach(filename, :headers => true) do |row|
    hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]
    lines.push hash
    if use_alternate && hash['Mouse Gene Symbol'].to_s.length > 0
      genes.push hash['Mouse Gene Symbol']
    else
      genes.push hash['Gene']
    end
  end
  genes
end

def load_and_check_genes
  genes = load_csv '/nfs/users/nfs_r/re4/Desktop/CRISPR targets.csv'
  check_genes genes
end

def load_and_check_genes2 filename
  list = []
  missing = []
  CSV.foreach(filename, :headers => true) do |row|
    hash = Hash[row.headers[0..-1].zip(row.fields[0..-1])]

    sql_1 = "select * from genes where marker_symbol ilike '#{hash['Mouse Gene Symbol']}'"
    sql_2 = "select * from genes where marker_symbol ilike '#{hash['Gene']}'"

    rows = []
    marker_symbol = hash['Gene']

    if ! hash['Mouse Gene Symbol'].to_s.empty?
      marker_symbol = hash['Mouse Gene Symbol']
      rows = ActiveRecord::Base.connection.execute(sql_1)
    end

    if ! rows.first
      rows = ActiveRecord::Base.connection.execute(sql_2)
    end

    list.push marker_symbol
    missing.push hash if ! rows.first
  end
  return missing, list
end

def load_and_check_genes21
  missing, list = load_and_check_genes2 '/nfs/users/nfs_r/re4/Desktop/CRISPR targets.csv'

  CSV.open('/nfs/users/nfs_r/re4/Desktop/missing_crispr_targets.csv', "wb") do |csv|
    csv << missing.first.keys
    missing.each do |row|
      csv << row.values
    end
  end
end

load_and_check_genes21

#genes = YAML.load_file("#{Rails.root}/config/idg_symbols.yml")
#check_genes genes

#["AQP10",
# "BEST4",
# "C230081A13Rik",
# "CLIC2",
# "CMKLR2",
# "EMR2",
# "EMR3",
# "ETBRLP2",
# "FCNCA",
# "FKSG79",
# "FKSG80",
# "FPRL2",
# "GJA6P",
# "GJB7",
# "GNRHRII",
# "GPCR111",
# "Gpr144",
# "GPR32",
# "GPR78",
# "GPR8",
# "GRK7",
# "HTR3C",
# "HTR3D",
# "HTR3E",
# "KCNJ18",
# "Nim1",
# "P2Y3L",
# "P2Y8",
# "PRKY",
# "SCNN1D",
# "Gm1078",
# "STK17A",
# "T2R45",
# "T2R48",
# "T2R51",
# "T2R52",
# "T2R53",
# "T2R54",
# "TG1019",
# "Gpr30",
# "4930444A02Rik"]
