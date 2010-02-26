var gmap; // ref to the Google Map object
var overlay;

$(document).ready(function () {
  // Set up basic world map
  var latlng = new google.maps.LatLng(0, 0);
  var myOptions = {
    zoom: 2,
    center: latlng,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    navigationControl: true,
    navigationControlOptions: { style: google.maps.NavigationControlStyle.DEFAULT, position: google.maps.ControlPosition.TOP_LEFT },
    mapTypeControl: false,
    scaleControl: true,
    scrollwheel: false
  };
  gmap = new google.maps.Map(document.getElementById("map_painter_gmap"), myOptions);
  // google.maps.event.addListener(gmap, 'dragstart', function() {
  //   alert ("Drag start");
  // })
  // google.maps.event.addListener(gmap, 'dragend', function() {
  //   alert ("Drag end");
  // })
  // google.maps.event.addListener(gmap, 'drag', function() {
  //     gmap.setCenter(new google.maps.LatLng(0, 0));
  //   })
  
  google.maps.event.addListener(gmap, 'click', function(event) {
    // alert (event.latLng);
  })
  google.maps.event.addListener(gmap, 'zoom_changed', updateMapInfo);
  google.maps.event.addListener(gmap, 'bounds_changed', updateMapInfo);
  google.maps.event.addListener(gmap, 'center_changed', updateMapInfo);
  
  // attach events
  $('a#paint_mode_toggle').click(togglePaintMode);
  
  var sw = new google.maps.LatLng(85,-160) ;
  var ne = new google.maps.LatLng(-66,160) ;
  var bounds = new google.maps.LatLngBounds(sw,ne) ;
  overlay = new ProjectedOverlay(gmap,'/images/rails.png', bounds, {}) ;
});

function isPainting()
{
  return (!$('#painter_tools').hasClass("hidden"));
}

function updateMapInfo(event) 
{
  $("#map_size").text (Math.round(overlay.getProjection().getWorldWidth()) + "px (" + gmap.getZoom() + "x)");
  $("#map_centre").text (Math.round(gmap.getCenter().lat()*1000)/1000 + ":" + Math.round(gmap.getCenter().lng()*1000)/1000);
  $("#map_bounds").text (Math.round(gmap.getBounds().getSouthWest().lat()*1000)/1000 + ":" + Math.round(gmap.getBounds().getSouthWest().lng()*1000)/1000 + " - " + Math.round(gmap.getBounds().getNorthEast().lat()*1000)/1000 + ":" + Math.round(gmap.getBounds().getNorthEast().lng()*1000)/1000);
  return (true);
}

function togglePaintMode()
{
  $('#painter_tools').toggleClass('hidden', isPainting());
  if (isPainting())
  {
    $('a#paint_mode_toggle').text($('a#paint_mode_toggle').text().replace("Start", "End"));
    gmap.setOptions ({draggable:false});
  } else {
    $('a#paint_mode_toggle').text($('a#paint_mode_toggle').text().replace("End", "Start"));
    gmap.setOptions ({draggable:true});
  }
}

function ProjectedOverlay(map, imageUrl, bounds, opts)
{
 google.maps.OverlayView.call(this);

 this.map_ = map;
 this.url_ = imageUrl ;
 this.bounds_ = bounds ;
 this.addZ_ = opts.addZoom || '' ;				// Add the zoom to the image as a parameter
 this.id_ = opts.id || this.url_ ;				// Added to allow for multiple images
 this.percentOpacity_ = opts.percentOpacity || 50 ;

 this.setMap(map);
}

ProjectedOverlay.prototype = new google.maps.OverlayView();

ProjectedOverlay.prototype.createElement = function()
{
 var panes = this.getPanes() ;
 var div = this.div_ ;

 if (!div)
 {
  div = this.div_ = document.createElement("div");
  div.style.position = "absolute" ;
  div.setAttribute('id',this.id_) ;
  this.div_ = div ;
  this.lastZoom_ = -1 ;
  if( this.percentOpacity_ )
  {
   this.setOpacity(this.percentOpacity_) ;
  }
  panes.overlayLayer.appendChild(div);
 }
}

// Remove the main DIV from the map pane

ProjectedOverlay.prototype.remove = function()
{
 if (this.div_) 
 {
  this.setMap(null);
  this.div_.parentNode.removeChild(this.div_);
  this.div_ = null;
 }
}

// Redraw based on the current projection and zoom level...

ProjectedOverlay.prototype.draw = function(firstTime)
{
 // Creates the element if it doesn't exist already.

 this.createElement();

 if (!this.div_)
 {
  return ;
 }
 
 var c1 = this.get('projection').fromLatLngToDivPixel(this.bounds_.getSouthWest());
 var c2 = this.get('projection').fromLatLngToDivPixel(this.bounds_.getNorthEast());

 if (!c1 || !c2) { return; }

 // Now position our DIV based on the DIV coordinates of our bounds

 this.div_.style.width = Math.abs(c2.x - c1.x) + "px";
 this.div_.style.height = Math.abs(c2.y - c1.y) + "px";
 this.div_.style.left = Math.min(c2.x, c1.x) + "px";
 this.div_.style.top = Math.min(c2.y, c1.y) + "px";
 
 // alert (this.div_.style.top + ":" + this.div_.style.left + "   " + this.div_.style.width + "x" + this.div_.style.height)

 // Do the rest only if the zoom has changed...
 
 if ( this.lastZoom_ == this.map_.getZoom() )
 {
  return ;
 }

 this.lastZoom_ = this.map_.getZoom() ;

 var url = this.url_ ;

 if ( this.addZ_ )
 {
  url += this.addZ_ + this.map_.getZoom() ;
 }

 this.div_.innerHTML = '<img src="' + url + '"  width=' + this.div_.style.width + ' height=' + this.div_.style.height + ' >' ;
}

ProjectedOverlay.prototype.setOpacity=function(opacity)
{
 if (opacity < 0)
 {
  opacity = 0 ;
 }
 if(opacity > 100)
 {
  opacity = 100 ;
 }
 var c = opacity/100 ;

 if (typeof(this.div_.style.filter) =='string')
 {
  this.div_.style.filter = 'alpha(opacity:' + opacity + ')' ;
 }
 if (typeof(this.div_.style.KHTMLOpacity) == 'string' )
 {
  this.div_.style.KHTMLOpacity = c ;
 }
 if (typeof(this.div_.style.MozOpacity) == 'string')
 {
  this.div_.style.MozOpacity = c ;
 }
 if (typeof(this.div_.style.opacity) == 'string')
 {
  this.div_.style.opacity = c ;
 }
}
