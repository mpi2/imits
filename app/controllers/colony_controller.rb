require 'yaml'

class ColonyController < ApplicationController
  def show
    @id = params[:id]
    debug = true

    return if ! @id

    @colony = Colony.find_by_id @id

    @files = {}

    return if @colony.nil?

    @title = "Colony #{@colony.name} (#{@colony.trace_file_file_name})"
    marker_symbol = @colony.try(:mi_attempt).try(:mi_plan).try(:gene).try(:marker_symbol)
    @title = "Gene #{marker_symbol} - Colony #{@colony.name} (#{@colony.trace_file_file_name})" if marker_symbol

    @files[:alignment] = {:name => 'Alignment', :data => @colony.file_alignment, :show => true, :split => true,
      :titles=> ['Reference Sequence', 'Mutated Sequence'], :ids => ['ref_seq', 'seq_1']}
    @files[:filtered_analysis_vcf] = {:name => 'Variant (vcf)', :data => @colony.file_filtered_analysis_vcf, :show => true}
    @files[:variant_effect_output_txt] = {:name => 'Variant (vep)', :data => @colony.file_variant_effect_output_txt, :show => true}
    @files[:reference] = {:name => 'Protein Sequence (reference)', :data => @colony.file_reference_fa, :show => true, :id => 'ref_protein'}
    @files[:mutant_fa] = {:name => 'Protein Sequence (mutated)', :data => @colony.file_mutant_fa, :show => true, :id => 'protein_seq'}
    @files[:primer_reads_fa] = {:name => 'Reads', :data => @colony.file_primer_reads_fa, :show => true}

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_data @files[key][:data], :disposition => 'attachment'
      end

      return
    end

    @deletions = @colony.deletions

    @insertions = @colony.insertions

   # @target_sequence = "Target sequence start: #{@alignment_data['target_sequence_start']} - Target sequence end: #{@alignment_data['target_sequence_end']}"

    @ok = false

    @files.keys.each do |key2|

        data = nil

        if @files[key2][:data]

          if @files[key2][:split] == true
            data  = []
            @files[key2][:data].each_line do |line|
              data << line.strip
            end
          else
            data = @files[key2][:data]
            data = data.strip || data
          end

          @files[key2][:data] = data

          @ok = true if data
        end
    end

    # TODO: move to colony.rb

    # get rid of first line (file name)
    # remove line breaks

    if @files[:primer_reads_fa][:data]
      @files[:primer_reads_fa][:data] = @files[:primer_reads_fa][:data].lines.to_a[1..-1].join
      @files[:primer_reads_fa][:data].gsub!(/\s+/, "")
    end

  end

  def index
    @colonies = Colony.all
  end
end
