// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var map_refs = {};

function ZoomMapTo(map_id, north, south, east, west, latitude_centre, longitude_centre)
{
  var map = map_refs[map_id];
  if (!map) return (alert ('Map with id ' + map_id + 'could not be found'));
  
  // clean up
  // map.clearOverlays();
  
  var centre = new google.maps.LatLng(latitude_centre, longitude_centre);
  sw = new google.maps.LatLng(south,west);
  ne = new google.maps.LatLng(north,east);
  bounds = new google.maps.LatLngBounds(sw, ne);
  
  map.panTo(centre);
  map.fitBounds(bounds)

  // icons source from http://www.visual-case.it/cgi-bin/vc/GMapsIcons.pl
  /* opts = {
    icon: new GIcon(G_DEFAULT_ICON, "http://maps.google.com/mapfiles/ms/micons/blue-pushpin.png"),
    draggable: false,
    bouncy: true
  }
  opts.icon.iconSize = new GSize(32, 32);
  marker = new GMarker(centre, opts);
  map.addOverlay(marker);
  GEvent.addListener(marker, "dragend", function(){
      map.panTo(marker.getLatLng());
  }); */
}

function ZoomMapToWorld(map_id)
{
  var map = map_refs[map_id];
  if (!map) return (alert ('Map with id ' + map_id + 'could not be found'));

  // clean up  
  // map.clearOverlays();
  map.setCenter( new google.maps.LatLng(0,0));
  map.setZoom (1);
}

function SetupMap(id, map_canvas)
{
  var map = new google.maps.Map(map_canvas, { zoom: 1, center: new google.maps.LatLng(0, 0), mapTypeId: google.maps.MapTypeId.ROADMAP } );
  map_refs[id] = map;

  SetupMapStyles(map);

  var overlayControlDiv = document.createElement('DIV');
  var overlayControl = new OverlayControl(overlayControlDiv, map);

  overlayControl.index = 1;
  map.controls[google.maps.ControlPosition.TOP_RIGHT].push(overlayControlDiv);
}

function SetupMapStyles(map)
{
  var stylez = [
    {
      featureType: "administrative",
      elementType: "all",
      stylers: [
        { visibility: 'off' }
      ]
    },
    {
      featureType: "poi",
      elementType: "all",
      stylers: [
        { visibility: 'off' }
      ]
    },
    {
      featureType: "road",
      elementType: "all",
      stylers: [
        { visibility: 'off' }
      ]
    },
    {
      featureType: "transit",
      elementType: "all",
      stylers: [
        { visibility: 'off' }
      ]
    },
    {
      featureType: "landscape",
      elementType: "all",
      stylers: [
        { hue: '#00FF00' }
      ]
    },
    {
      featureType: "water",
      elementType: "labels",
      stylers: [
        { visibility: 'off' }
      ]
    }
  ];

  var styledMapOptions = {
      name: "without_features"
  }
  var noFeaturesMapType = new google.maps.StyledMapType(stylez, styledMapOptions);
  map.mapTypes.set('without_features', noFeaturesMapType);

  // Set CSS styles for the DIV containing the control
  // Setting padding to 5 px will offset the control
  // from the edge of the map
  var controlDiv = document.createElement('DIV');
  controlDiv.style.padding = '5px';

  // Set CSS for the control border
  var controlUI = document.createElement('DIV');
  controlUI.style.backgroundColor = 'white';
  controlUI.style.borderStyle = 'solid';
  controlUI.style.borderWidth = '2px';
  controlUI.style.cursor = 'pointer';
  controlUI.style.textAlign = 'center';
  controlUI.title = 'Hide Features';
  controlDiv.appendChild(controlUI);

  // Set CSS for the control interior
  var controlText = document.createElement('DIV');
  controlText.style.fontFamily = 'Arial,sans-serif';
  controlText.style.fontSize = '12px';
  controlText.style.paddingLeft = '4px';
  controlText.style.paddingRight = '4px';
  controlText.innerHTML = 'Hide Features';
  controlUI.appendChild(controlText);

  // Setup the click event listeners:
  google.maps.event.addDomListener(controlUI, 'click', function() {
    featuresVisible = controlText.innerHTML.indexOf('Hide') == 0;

    if (featuresVisible)
    {
      // hide
      map.setMapTypeId('without_features');
      controlText.innerHTML = 'Show Features';
    } else {
      // show
      map.setMapTypeId(google.maps.MapTypeId.ROADMAP);
      controlText.innerHTML = 'Hide Features';
    }
  });

  map.controls[google.maps.ControlPosition.TOP_RIGHT].push(controlDiv);
}

function OverlayControl(controlDiv, map) {
  // Set CSS styles for the DIV containing the control
  // Setting padding to 5 px will offset the control
  // from the edge of the map
  controlDiv.style.padding = '5px';

  // Set CSS for the control border
  var controlUI = document.createElement('DIV');
  controlUI.style.backgroundColor = 'white';
  controlUI.style.borderStyle = 'solid';
  controlUI.style.borderWidth = '2px';
  controlUI.style.cursor = 'pointer';
  controlUI.style.textAlign = 'center';
  controlUI.title = 'Show Land Mass Overlay';
  controlDiv.appendChild(controlUI);

  // Set CSS for the control interior
  var controlText = document.createElement('DIV');
  controlText.style.fontFamily = 'Arial,sans-serif';
  controlText.style.fontSize = '12px';
  controlText.style.paddingLeft = '4px';
  controlText.style.paddingRight = '4px';
  controlText.innerHTML = 'Show Land Mass Overlay';
  controlUI.appendChild(controlText);

  // Setup the click event listeners:
  google.maps.event.addDomListener(controlUI, 'click', function() {
    overlayVisible = controlText.innerHTML.indexOf('Hide') == 0;

    if (overlayVisible)
    {
      // hide
      map.overlayMapTypes.pop();
      controlText.innerHTML = 'Show Land Mass Overlay';
    } else {
      // show
      map.overlayMapTypes.push(new CoordMapType(new google.maps.Size(256, 256)));
      controlText.innerHTML = 'Hide Land Mass Overlay';
    }
  });
}

var MERCATOR_RANGE = 256;
 
function bound(value, opt_min, opt_max) {
  if (opt_min != null) value = Math.max(value, opt_min);
  if (opt_max != null) value = Math.min(value, opt_max);
  return value;
}

function degreesToRadians(deg) {
  return deg * (Math.PI / 180);
}
 
function radiansToDegrees(rad) {
  return rad / (Math.PI / 180);
}
 
function MercatorProjection() {
  this.pixelOrigin_ = new google.maps.Point(
      MERCATOR_RANGE / 2, MERCATOR_RANGE / 2);
  this.pixelsPerLonDegree_ = MERCATOR_RANGE / 360;
  this.pixelsPerLonRadian_ = MERCATOR_RANGE / (2 * Math.PI);
};
 
MercatorProjection.prototype.fromLatLngToPoint = function(latLng, opt_point) {
  var me = this;
 
  var point = opt_point || new google.maps.Point(0, 0);
 
  var origin = me.pixelOrigin_;
  point.x = origin.x + latLng.lng() * me.pixelsPerLonDegree_;
  // NOTE(appleton): Truncating to 0.9999 effectively limits latitude to
  // 89.189.  This is about a third of a tile past the edge of the world tile.
  var siny = bound(Math.sin(degreesToRadians(latLng.lat())), -0.9999, 0.9999);
  point.y = origin.y + 0.5 * Math.log((1 + siny) / (1 - siny)) * -me.pixelsPerLonRadian_;
  return point;
};
 
MercatorProjection.prototype.fromPointToLatLng = function(point) {
  var me = this;
  
  var origin = me.pixelOrigin_;
  var lng = (point.x - origin.x) / me.pixelsPerLonDegree_;
  var latRadians = (point.y - origin.y) / -me.pixelsPerLonRadian_;
  var lat = radiansToDegrees(2 * Math.atan(Math.exp(latRadians)) - Math.PI / 2);
  return new google.maps.LatLng(lat, lng);
};

function CoordMapType(tileSize) {
  this.tileSize = tileSize;
}

CoordMapType.prototype.getTile = function(coord, zoom, ownerDocument) {
  var div = ownerDocument.createElement('DIV');
  normCoords = this.normalisedCoordinates(coord, zoom);
  div.innerHTML = '<img src="/tiles/landmass/' + normCoords.x + '/' + normCoords.y + '/' + zoom + '.png" width="' + this.tileSize.width + '" height="' + this.tileSize.height + '" style="opacity:0.5;filter:alpha(opacity=50);"/>';
  div.style.width = this.tileSize.width + 'px';
  div.style.height = this.tileSize.height + 'px';
  return div;
};

CoordMapType.prototype.normalisedCoordinates = function(coord, zoom)
{
  maxVal = Math.pow(2, zoom);
  x = coord.x % maxVal; if (x < 0) x = x*-1;
  y = coord.y % maxVal; if (y < 0) y = y*-1;
  return ({ x: x, y: y });
}
   
