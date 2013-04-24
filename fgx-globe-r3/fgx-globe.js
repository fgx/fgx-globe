	
	$(function() {	
		$.getCrossfeed = function() {
			$.getJSON('http://crossfeed.fgx.ch/flights.json', function(data) {
// console.log( $('#tbody').length );

				$.fltData = data;
				$.lookup = {};
				var flt;
				$('#tbody').empty();
				$.each(data.flights, function(dataItem){
					flt = data.flights[dataItem];
					$.lookup[ flt.callsign ] = flt;
					$('#tbody').append(
						function() {
							return "<tr>" +
								"<td><button onclick='$.doIt(" + dataItem + ")' >" + flt.callsign + "</button></td>" +
								//"<td>" + flt.lat + "</td>" +
								//"<td>" + flt.lon + "</td>" +
								"<td>" + flt.hdg + "</td>" +
								"<td>" + flt.alt_ft + "</td>" +
								"<td>" + flt.spd_kts + "</td>" +
								"<td>" + flt.model.replace("Aircraft/","") + "</td>"+
							"<tr>";
						}
					);
				});
				$('#status').replaceWith( "<p id='status'>Last update: " + $.fltData.last_updated + "</p>" );

				$.each( $('.flt_window'), function( item, element) {
// console.log( $.lookup[element.id ] );
					var flt =  $.lookup[ element.id ];
					if ( flt !== undefined ) {
						element.innerHTML = $.setMap( flt, $.elements.thm.mapType);						
					} else {
						element.innerHTML = element.id + " does not seem to be flying right now.";
					}
				});
			})
		};
		
		$.setMap = function( flt, type) {
			if (type === 1) {
			return 'Callsign: ' + flt.callsign + '<br>' +
					'Lat: ' + flt.lat.toFixed(2) + '&deg Lon: ' +  flt.lon.toFixed(2) + '&deg<br>' +
					'<iframe width="300" height="200" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://www.openstreetmap.org/export/embed.html?bbox=' +
					(flt.lon + 0.2) + ',' + (flt.lat - 0.2) + ',' + (flt.lon - 0.2) + ',' + (flt.lat + 0.2) + '&amp;layer=mapnik" style="border: 1px solid black"></iframe>' +
					'<a href="http://www.openstreetmap.org/index.html?lat=' + flt.lat + '&lon=' + flt.lon + '&zoom=12" target="_blank">link<br>' +
					'</a>' + '<br>' +
				'';			
			
			} else {
				return 'Callsign: ' + flt.callsign + '<br>' +
					'Lat: ' + flt.lat.toFixed(2) + '&deg Lon: ' +  flt.lon.toFixed(2) + '&deg<br>' +
					'<img src"http://www.openstreetmap.org/index.html?lat=' + flt.lat + '&lon=' + flt.lon + '&zoom=12" />' +
					'<a href="http://maps.google.com/maps?z=14&t=k&q=loc:' + flt.lat + ',' + flt.lon + '" target="_blank">' +
					'<img src="http://maps.googleapis.com/maps/api/staticmap?center=' + flt.lat + ',' + flt.lat + '&maptype=satellite&zoom=14&size=300x200&sensor=false" >' +
					'</a>' + '<br>' +
				'';			
			}
		};

		$.doIt = function( item ) {
// console.log( item );

			var flt = $.fltData.flights[ item ];
			$.elements.win[flt.callsign] = {
				className: 'flt_window',
				closer: "true",
				fname: "ajax/new-window.html",
				height: "370",
				id: flt.callsign,
				left: "400",
				title: flt.callsign,
				top: "100",
				width: "350"
			};
			$.newDialog( $.elements.win[flt.callsign]  );
			$.getCrossfeed();
			$.setHash();
		};
	});	