jQuery(document).ready(	function() {

    function toggleDetails() {
        $(".toggle").each(function( index ) {

               $( this ).on({'click':function(event){

               var name = $( this ).data( "name" );

              // alert(name);

               $( "#" + name ).toggle();

             //   alert("hello!");

             //jQuery(this).parent().children("div").toggle();

             //jQuery("div", this).toggle();

               //$( "div" ).toggle();

               event.preventDefault();

            }});
        });
    }

    toggleDetails();

});
