	var sidebarLeft;
	var statusBar;
	var sidebarRight;
	var headsUp;
	var stbHTML;
	var sbrBody = document.getElementById('sbr-body');


	var sbr = function(){
		var css = document.body.appendChild( document.createElement('style') );
		css.innerHTML =
			'body {background-color: transparent; font: normal 12pt monospace; margin: 0; overflow: hidden; text-align: center;}' +
			
			'a { color: #44e;}  ' +
			
			'button, input[type=range] { -webkit-appearance: none; background-color: silver; height: 20px; opacity: 0.5; }' +
			
			'h1, h2 { margin: 0; min-width: 200px; }' +
			
			'input[type="range"]::-webkit-slider-thumb {-webkit-appearance: none; background-color: #666; opacity: 0.5; width: 10px; height: 26px; }' +

			'#sbl { background-color: #eee; left: 30px; margin: 10px; opacity: 0.8; outline: 1px solid; padding: 10px; position: absolute; ' +
				'text-align: left; top: 120px; max-width: 300px;}' +

			'#stb { background-color: #eee; left: 25%; margin: 10px auto; opacity: 0.8; outline: 1px solid; padding: 10px; position: absolute;' +
				'text-align: left; top: 20px; width: 700px;}' +

			'#sbr { background-color: #eee; height: 90%; margin: 10px; opacity: 0.8; outline: 1px solid; padding: 10px; position: absolute; ' +
				'right: 20px; text-align: left; top: 30px; max-width: 350px; word-wrap:break-word;}' +

			'#sbr-body { font-size: 9pt; height: 95%; overflow-y: scroll; }' +

			'div.control { color: #aaa; cursor: hand; cursor: pointer; float: right; }' ;
	}();

	
	var bars = function() {
		sidebarLeft = document.body.appendChild( document.createElement( 'div' ) );
		sidebarLeft.id = 'sbl';

		statusBar = document.body.appendChild( document.createElement( 'div' ) );
		statusBar.id = 'stb';

		sidebarRight = document.body.appendChild( document.createElement( 'div' ) );
		sidebarRight.id = 'sbr';

		headsUp = document.body.appendChild( document.createElement( 'div' ) );
		headsUp.style.cssText = 'background-color: #ddd; border-radius: 8px; display: none; left: 50px; opacity: 0.85; padding: 5px 5px 10px 5px; ' +
			'position: absolute; text-align: left; width: 350px; word-wrap:break-word;';
		headsUp.innerHTML = '<h1>heads-up</h1>';
	}();

	function toggleBar( sidebar ) {
		if ( sidebar.style.display === '' ) {
			sidebar.style.display = 'none';
		} else {
			sidebar.style.display = '';
		}
	}

	function toggleStatusBar() {
		var tg = document.getElementById("toggle");
		var tgd = document.getElementById("toggled");
		if ( tgd.style.display === '' ) {
			tg.innerText = '[+]';
			tgd.style.display = 'none';
		} else {
			tg.innerText = '[-]';
			tgd.style.display = '';
		}
	}
	
	function initText() {
	
		sidebarLeft.innerHTML =
			'<div class="control" onclick="toggleBar( sidebarLeft )">[X]</div>' +
			'<h1>World<br>Airports,<br> Runways<br> and <br>Navaids r2.4</h1>' +
			'<p><i>This is a: cookbook demo / prototype / test case. Let\'s talk about appearance and minor blemishes another time...</i></p>' +
			'<p>Each stick represents an airport. Move your cursor over one of them to see its details.</p>' +
			'<p>Use your pointing device to update the view.</p>' +
			'<p><b><i>Rotate</i></b>: Left button/1 finger down<br><b><i>Zoom</i></b>: Wheel/2 fingers<br><b><i>Pan</i></b>: Right button/2 fingers down</p>' +
			
			'<p><a href="https://github.com/fgx/fgx-globe/wiki/airports-runways-navaids" target="_blank">Report issues: GitHub Wiki</a></p>' +
		'';

		stbHTML = 
			'<div id="toggle" class="control" onclick="toggleStatusBar()">[-]</div>' +
			'<div class="control" onclick="toggleBar( sidebarLeft ); toggleBar( sidebarRight );">[<span style="font-size: small; vertical-align: text-top; ">[]</span>] &nbsp;</div>' +
			'<h2>Settings</h2>' +
			'<div id="toggled" title=" ' +
				'Left mouse rotates the globe. Right mouse: pans. Wheel: zooms. Hover over cube/airport to display airport details"><br>' +
				//'Theta:<input type="range" id="spin" min="-3.1415" max="3.1415" onchange="theta=this.value; updatePlane()" step="0.01" value="' + theta + '" > ' +
				//'Phi:<input type="range" id="spin" min="-3.1415" max="3.1415" onchange="phi=this.value;updatePlane()" step="0.01" value="' + phi + '" > ' +
				//'Nearby:' +
				//'<input type="range" id="spin" min="-0" max="50" onchange="plane.nearby=this.value;" step="1" value="' + plane.nearby + '" > ' +			
			'</div>';  	

		statusBar.innerHTML = stbHTML;
		
		sbrHTML = 
			'<div class="control" onclick="toggleBar( sidebarRight )">[X]</div>' +
			'<h2>Readout</h2>' +
			'<div id="sbr-body">' +
			'</div>' +
		'';
		sidebarRight.innerHTML = sbrHTML;
		
		sbrBody = document.getElementById('sbr-body');
	}