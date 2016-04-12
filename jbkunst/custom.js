$( document ).ready(function() {
    console.log( "ready!" );
    
    $("a[role='tab']").click(function(e){
      
      console.log(this);
      e = console.log(this.getAttribute('aria-controls'));
      
      chart = $("#" + e + " > .col-md-8 > div").highcharts();
      chart.redraw();
      
    });
    
});
