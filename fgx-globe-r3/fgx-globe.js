	
	$(function() {	
		$.planes = {};
		
		$.getCrossfeed = function() {
			$.getJSON('http://crossfeed.fgx.ch/flights.json', function(data) {
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
								"<td>" + flt.model.split("/")[1] + "</td>"+
							"<tr>";
						}
					);
					
					if (!$.planes[ flt.callsign ] ) {
						var pl = $.planes[ flt.callsign ] = {
							model: flt.model.split("/")[1],
							data: flt,
							plane: null
						};	
						pl.plane = $.ifr.contentWindow.makePlane( pl );
					}
					var pl = $.planes[ flt.callsign ];				
					pl.data = flt;
					$.ifr.contentWindow.updatePlane( pl );
				});
				
				$('#title').replaceWith( "<scan id='title'>Planes flying: " + data.flights.length + "</scan>" );
				$('#status').replaceWith( "<p id='status'>Last update: " + $.fltData.last_updated + "</p>" );

				$.each( $('.flt_window'), function( item, element) {
					var flt =  $.lookup[ element.id ];
					if ( flt !== undefined ) {
						var wid = $.elements.win[flt.callsign].width - 60;
						var hgt = $.elements.win[flt.callsign].height - 165;						
// console.log( item, wid, hgt );						
						element.innerHTML = $.setMap( flt, parseInt($.elements.thm.mapType), wid, hgt);						
					} else {
						element.innerHTML = element.id + " does not seem to be flying right now.";
					}
				});
			})
		};
		
		$.setMap = function( flt, type, wid, hgt) {
			if (type === 0) {
				return flt.model.split("/")[1] + '<br>' +
					'Hdg: ' + flt.hdg + ' Alt: ' + flt.alt_ft + ' Spd: ' + flt.spd_kts + '<br>' +
					'Lat: ' + flt.lat.toFixed(2) + '&deg Lon: ' +  flt.lon.toFixed(2) + '&deg<br>' +
					// '<img src"http://www.openstreetmap.org/index.html?lat=' + flt.lat + '&lon=' + flt.lon + '&zoom=12" />' +
					'<a href="http://maps.google.com/maps?z=14&t=k&q=loc:' + flt.lat + ',' + flt.lon + '" target="_blank">' +
					'<img src="http://maps.googleapis.com/maps/api/staticmap?center=' + flt.lat + ',' + flt.lon + '&maptype=satellite&zoom=14&size=' + wid + 'x' + hgt + '&sensor=false" >' +
					'</a>' + '<br>' +
				'';			
			} else if (type === 1) {
				return flt.model.split("/")[1] + '<br>' +
					'Hdg: ' + flt.hdg + ' Alt: ' + flt.alt_ft + ' Spd: ' + flt.spd_kts + '<br>' +
					'Lat: ' + flt.lat.toFixed(2) + '&deg Lon: ' +  flt.lon.toFixed(2) + '&deg<br>' +
					'<iframe width="' + wid + '" height="' + hgt + '" frameborder="0" scrolling="no" marginheight="0" marginwidth="0" src="http://www.openstreetmap.org/export/embed.html?bbox=' +
					(flt.lon + 0.2) + ',' + (flt.lat - 0.2) + ',' + (flt.lon - 0.2) + ',' + (flt.lat + 0.2) + '&amp;layer=mapnik" style="border: 1px solid black"></iframe>' +
					'<a href="http://www.openstreetmap.org/index.html?lat=' + flt.lat + '&lon=' + flt.lon + '&zoom=12" target="_blank"><br>link' +
					'</a>' + '<br>' +
				'';					
			} else {
				return flt.model.split("/")[1] + '<br>' +
					'Hdg: ' + flt.hdg + ' Alt: ' + flt.alt_ft + ' Spd: ' + flt.spd_kts + '<br>' +
					'Lat: ' + flt.lat.toFixed(2) + '&deg Lon: ' +  flt.lon.toFixed(2) + '&deg<br>' +
					'<a href="http://maps.google.com/maps?z=14&t=m&q=loc:' + flt.lat + ',' + flt.lon + '" target="_blank">' +
					'<img src="http://maps.googleapis.com/maps/api/staticmap?center=' + flt.lat + ',' + flt.lon + '&maptype=roadmap&zoom=14&size=' + wid + 'x' + hgt + '&sensor=false" >' +
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
				left: "100",
				title: flt.callsign,
				top: "100",
				width: "370",
			};
			$.newDialog( $.elements.win[flt.callsign]  );
			$.getCrossfeed();
			$.setHash();
		};
	});	