function zoomMapTo(mapDomElem, north, south, east, west, latitude_centre, longitude_centre)
{
  var map = new GMap2(mapDomElem);
  // clean up
  map.clearOverlays();
  
  var centre = new GLatLng(latitude_centre, longitude_centre);
  sw = new GLatLng(south,west);
  ne = new GLatLng(north,east);
  bounds = new GLatLngBounds(sw, ne);
  zoom = Math.min(map.getBoundsZoomLevel(bounds), 9);
  
  map.setCenter(centre, zoom);
  
  map.addControl(new GLargeMapControl3D());  

  // icons source from http://www.visual-case.it/cgi-bin/vc/GMapsIcons.pl
  opts = {
    icon: new GIcon(G_DEFAULT_ICON, "http://maps.google.com/mapfiles/ms/micons/blue-pushpin.png"),
    draggable: false,
    bouncy: true
  }
  opts.icon.iconSize = new GSize(32, 32);
  marker = new GMarker(centre, opts);
  map.addOverlay(marker);
  GEvent.addListener(marker, "dragend", function(){
      map.panTo(marker.getLatLng());
  });
}

function zoomMapToWorld(mapDomElem)
{
  var map = new GMap2(mapDomElem);
  // clean up
  map.clearOverlays();
  
  new GMap2(mapDomElem).setCenter( new GLatLng(0,0), 1);
}