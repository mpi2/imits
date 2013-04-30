function populate_allele_grid(){
  var search_text = document.getElementById("search_for_gene").value;
  document.getElementById("mouse-alleles").style.visibility="hidden";
  var mgiAccession = '';
  var patt = new RegExp("MGI:");
  if (patt.test(search_text)){
    mgiAccession = search_text;
    create_grid(mgiAccession);
  }
  else if (search_text) {
    var request = $.ajax({url: window.basePath +"genes.json?marker_symbol_eq=" + search_text, dataType: 'json'});
    request.done(function (response){
      if (response.length != 0){
        mgiAccession = response[0]['mgi_accession_id'];
        create_grid(mgiAccession);
      };
    });
  }
}

function create_grid(mgiAccession){
  if (mgiAccession){
    mgiAccession = mgiAccession.replace('MGI:', '');
    $("#mpi2-allele-grid").mpi2GenePageAlleleGrid().trigger('search', {solrParams: {q: 'mgi_accession_id:'+mgiAccession}});
    document.getElementById("mouse-alleles").style.visibility="visible";
  }
}
