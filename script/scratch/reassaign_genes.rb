genes = Gene.all

result = Array.new

Gene.all.each do |g|
  puts "\n", g.id, "\n"
  latest_status = nil
  ps = g.mi_plans
  ps.each do |p|
    mis = p.mi_attempts
    mams = p.mouse_allele_mods
    pps = p.phenotyping_productions
    info = Array.new
    if !pps.empty?
      pps.each do |pp|
        info2 = Array.new
        info2.push(g.marker_symbol.to_s)
        info2.push(p.id)
        info2.push(nil)
        info2.push(pp.id)
        info2.push(p.status.name)
        info2.push(pp.status.name)
        info2.push(pp.status_stamps.maximum("created_at").strftime("%F"))
        info2.push(p.withdrawn)
        info2.push(p.production_centre.name) if p.production_centre != nil

        info.push(info2)
      end
      result.push(info)
      next
    elsif !mams.empty?
      mams.each do |mam|
        info3 = Array.new
        info3.push(g.marker_symbol.to_s)

        info3.push(p.id)
        info3.push(nil)
        info3.push(nil)
        info3.push(p.status.name)
        info3.push(mam.status.name)
        info3.push(mam.status_stamps.maximum("created_at").strftime("%F"))
        info3.push(p.withdrawn)
        info3.push(p.production_centre.name) if p.production_centre != nil 

        info.push(info3)
      end
      result.push(info)
      next
    elsif !mis.empty?
      mis.each do |mi|
        info4 = Array.new
        info4.push(g.marker_symbol.to_s)

        info4.push(p.id)
        info4.push(mi.id)
        info4.push(nil)
        info4.push(p.status.name)
        info4.push(mi.status.name)
        info4.push(mi.status_stamps.maximum("created_at").strftime("%F"))
        info4.push(p.withdrawn)
        info4.push(p.production_centre.name) if p.production_centre != nil

        info.push(info4)
      end
      result.push(info)
      next
    else
      info5 = Array.new
      info5.push(g.marker_symbol.to_s)

      info5.push(p.id)
      info5.push(nil)
      info5.push(nil)
      info5.push(p.status.name)
      info5.push(p.status.name)
      info5.push(p.status_stamps.maximum("created_at").strftime("%F"))
      info5.push(p.withdrawn)
      info5.push(p.production_centre.name) if p.production_centre != nil

      info.push(info5)
      result.push(info)
      next
    end
  end
end

file = "latest_status_per_gene_all_5.csv"
 
CSV.open( file, 'w' ) do |writer|
  writer << ["gene_name", "mi_plan_id", "mi_attempt_id", "phenotyping_productions_id", "latest_plan_status", "latest_status", "date", "withdrawn", "production_centre"]
  result.each do |r|
    r.each do |rr|
      writer << rr
    end
  end
end



# if !info.empty?
#     result.push(info)
#   end



