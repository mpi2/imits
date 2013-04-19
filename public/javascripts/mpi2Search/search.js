function populate_allele_grid(){
  document.getElementById("mpi2-allele-grid").style.visibility="hidden";
  var mgiAccession = '';
  var patt = new RegExp("MGI:");
  if (patt.test(document.getElementById("marker_symbol").value)){
    mgiAccession = document.getElementById("marker_symbol").value;
    create_grid(mgiAccession);
  }
  else if (document.getElementById("marker_symbol").value) {
    var request = $.ajax({url: window.basePath +"genes.json?marker_symbol_eq=" + document.getElementById("marker_symbol").value, dataType: 'json'});
    request.done(function (response, textStatus, jqZHR){
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
    document.getElementById("mpi2-allele-grid").style.visibility="visible";
  }
}