
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

    @files[:alignment] = {:filename => 'alignment.txt', :name => 'Alignment', :data => @colony.file_alignment, :show => true, :split => true, :titles=> ['Reference Sequence', 'Mutated Sequence'], :ids => ['ref_seq', 'seq_1']}
    @files[:filtered_analysis_vcf] = {:filename => 'filtered_analysis.vcf', :name => 'Variant (vcf)', :data => @colony.file_filtered_analysis_vcf, :show => true}
    @files[:variant_effect_output_txt] = {:filename => 'variant_effect_output.txt', :name => 'Variant (vep)', :data => @colony.file_variant_effect_output_txt, :show => true}
    @files[:reference] = {:filename => 'reference.fa', :name => 'Protein Sequence (reference)', :data => @colony.file_reference_fa, :show => true, :id => 'ref_protein'}
    @files[:mutant_fa] = {:filename => 'mutated.fa', :name => 'Protein Sequence (mutated)', :data => @colony.file_mutant_fa, :show => true, :id => 'protein_seq'}
    @files[:primer_reads_fa] = {:filename => 'primer_reads.fa', :name => 'Reads', :data => @colony.file_primer_reads_fa, :show => true}

    @files[:debug_output] = {:filename => 'debug_output.txt', :name => 'crispr_damage_analysis output (debug)', :data => @colony.file_trace_output, :show => ! Rails.env.production?}
    @files[:debug_errors] = {:filename => 'debug_errors.txt', :name => 'crispr_damage_analysis errors (debug)', :data => @colony.file_trace_error, :show => ! Rails.env.production?}
    @files[:debug_exception] = {:filename => 'debug_exception.txt', :name => 'crispr_damage_analysis exception (debug)', :data => @colony.file_exception_details, :show => ! Rails.env.production?}

    if params[:filename]
      key = params[:filename].to_sym
      if @files.has_key? key
        send_data @files[key][:data], :filename => @files[key][:filename], :disposition => 'attachment'
      end

      return
    end

    @deletions = @colony.deletions

    @insertions = @colony.insertions

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

  end

  def index
    @colonies = Colony.all
  end
end
