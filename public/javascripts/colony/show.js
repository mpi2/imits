jQuery(document).ready(	function() {

    function toggleDetails() {
        $(".toggle").each(function( index ) {

               $( this ).on({'click':function(event){

               var name = $( this ).data( "name" );
               var text = $( this ).text();

               if(text == "View")
                 $( this ).text("Hide");
               else
                 $( this ).text("View");

               $( "#" + name ).toggle();

               event.preventDefault();

            }});
        });
    }

    toggleDetails();

});
