function populate_allele_grid(){
  var search_text = document.getElementById("search_for_gene").value;
  document.getElementById("mouse-alleles").style.display="none";
  document.getElementById("mpi2-allele-grid").style.display="none";
  var mgiAccession = '';
  var patt = new RegExp("MGI:");
  if (patt.test(search_text)){
    mgiAccession = search_text;
    create_gene_grid('mgi_accession_id:'+mgiAccession);
  }
  else if (search_text) {
    create_gene_grid('marker_symbol:'+search_text);
  }
}

function create_allele_grid(mgiAccession){
  if (mgiAccession){
    mgiAccession = mgiAccession.replace('MGI:', '');
    $("#mpi2-allele-grid").mpi2GenePageAlleleGrid().trigger('search', {solrParams: {q: 'mgi_accession_id:'+mgiAccession}});
    document.getElementById("mpi2-allele-grid").style.display="inline";
  }
}

function create_gene_grid(mgiAccession){
  $("#mpi2-search").mpi2Search().trigger('search', [{type: 'gene_new' ,solrParams: {q: mgiAccession}}]);
  create_allele_grid('');
  document.getElementById("mouse-alleles").style.display="inline";
  $(".gene").delegate("a","click",function(){
    var id= this.getAttribute('data-id');
    create_allele_grid(id);
  });

}
