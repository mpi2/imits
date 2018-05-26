class ColonyController < ApplicationController
  require 'rubygems/package'

  respond_to :json

  before_filter :authenticate_user!

  def show
    @id = params[:id]

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?


    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    if marker_symbol
      @title         = "Gene #{marker_symbol} - Colony #{@colony.name}"
    else
      @title         = "Colony #{@colony.name}"
    end

  end

  def phenotype_attempts_new
    @colony = Colony.find_by_name(params[:mi_attempt_colony_name])

    redirect_to :controller => 'phenotype_attempts', :action => :new, :colony_id => @colony.try(:id)
  end

  def evidence
    colony_id = params[:id]
    download = params[:download]
    serve_as = params.has_key?(:view) && ['in_browser', 'download'].include?(params[:view]) ? params[:view] : 'download'

    colony = Colony.find(params[:id])
    raise 'colony not found' if colony.blank?


    downloads = {
                  'trace' => {'data_files' => !colony.trace_files.blank? ? colony.trace_files.select{|tf| !tf.trace_file_name.blank?}.map{|tc| [tc.trace_file_name, tc.trace.file_contents] } : [] }, 
                  'alignment' => {'data_files' => colony.alleles.select{|a| !a.bam_file.blank?}.map{|a| ["#{a.gene.marker_symbol}_#{a.mgi_allele_symbol_superscript}_#{colony.name}.bam", a.bam_file]}}, 
                  'vcf' => {'data_files' => colony.alleles.select{|a| !a.vcf_file.blank?}.map{|a| [ ["#{a.gene.marker_symbol}_#{a.mgi_allele_symbol_superscript}_#{colony.name}_vcf.gz", a.vcf_file], ["#{a.gene.marker_symbol}_#{a.mgi_allele_symbol_superscript}_#{colony.name}_vcf.gz.tbi", a.vcf_file_index] ] }.flatten(1)}, 
                  'mutant_sequence' => {'data_files' => colony.alleles.select{|a| !a.mutant_fa.blank?}.map{|a| ["#{a.gene.marker_symbol}_#{a.mgi_allele_symbol_superscript}_#{colony.name}.fa", a.mutant_fa]}}
                  }

    raise "evidence contoller has not been configured for '#{download}'" if !downloads.has_key?(download)

    raise 'no download available' if downloads[download]['data_files'].all?{|f| f[1].blank?}
    file = StringIO.open("new.tar.gz", "wb")
    Zlib::GzipWriter.wrap(file) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        downloads[download]['data_files'].each do |f|
          tar.add_file_simple("#{f[0]}", 0444, f[1].length) do |io|
            io.write(f[1])
          end
        end
      end
    end

    send_data file.string, :filename => "#{colony.name}_evidence.tar.gz", :disposition => 'attachment'

  end


  def mut_nucleotide_sequences
    position = params[:position]
    ids_str = params.has_key?(:ids) ? params[:ids].split(',') : []
    chr = nil
    coord_start = nil
    coord_end = nil
    unless position.blank?
      chr, coord = position.split(':')
      coord_start, coord_end = coord.split('-')
    end

    annotations = []

    if !chr.blank? && !coord_start.blank? && !coord_end.blank?
      if !ids_str.blank?
        annotations = Allele::Annotation.joins(:allele).where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end AND alleles.colony_id IN ( :ids_str )", {coord_start: coord_start, coord_end: coord_end, ids_str: ids_str})
      else
        annotations = Allele::Annotation.joins(:allele).where("chr = '#{chr}' AND start > :coord_start AND start < :coord_end", {coord_start: coord_start, coord_end: coord_end})
      end
    elsif !ids_str.blank?
      annotations = Allele::Annotation.joins(:allele).where("alleles.colony_id IN ( :ids_str )", {ids_str: ids_str})
    end

    mut_seq_features = []

    annotations.each do |tc_mod|
      mut_seq_feature = {
        'chr'          => tc_mod.chr,
        'start'        => tc_mod.start,
        'end'          => tc_mod.end,
        'ref_sequence' => tc_mod.ref_seq,
        'alt_sequence' => tc_mod.alt_seq,
        'sequence'     => tc_mod.alt_seq,
        'mod_type'     => tc_mod.mod_type
      }
      mut_seq_features.push( mut_seq_feature.as_json )
    end

    respond_with @mutsequences do |format|
      format.json do
        render :json => mut_seq_features
      end
    end

  end
end
