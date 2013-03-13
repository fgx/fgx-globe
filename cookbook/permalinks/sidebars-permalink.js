
	var sidebarLeft, statusBar, sidebarRight;

	var css = function(){
		var css = document.createElement('style');
		css.innerHTML =
			'body {background-color: transparent; font: 600 12pt monospace; margin: 0; overflow: hidden; text-align: center;}' +
			
			'a { color: #f00;}  ' +
			
			'button, input[type=range] { -webkit-appearance: none; background-color: silver; height: 20px; opacity: 0.5; }' +
			
			'input[type="range"]::-webkit-slider-thumb {-webkit-appearance: none; background-color: #666; opacity: 0.5; width: 10px; height: 26px; }'  +
			
			'h1 { margin: 0; min-width: 200px; }' +

			'#sbl { background-color: #eee; outline: 1px solid; left: 30px; margin: 10px; opacity: 0.8; padding: 10px; position: absolute; ' +
				'text-align: left; top: 30px; max-width: 350px;}' +

			'#stb { background-color: #eee; outline: 1px solid; margin: 10px auto; opacity: 0.8; padding: 10px; ' +
				'text-align: left; top: 30px; width: 500px;}' +

			'#sbr { background-color: #eee; height: 90%; margin: 10px; opacity: 0.8; outline: 1px solid; padding: 10px; position: absolute; ' +
				'right: 20px; text-align: left; top: 30px; max-width: 350px;}' +

			'#sbrBody {  height: 85%; overflow-y: scroll; }' +

			'div.control { color: #aaa; cursor: hand; cursor: pointer; float: right; }' ;

		document.body.appendChild( css );
	}();

	var bars = function(){
		sidebarLeft = document.body.appendChild( document.createElement( 'div' ) );
		sidebarLeft.id = 'sbl';

		statusBar = document.body.appendChild( document.createElement( 'div' ) );
		statusBar.id = 'stb';

		sidebarRight = document.body.appendChild( document.createElement( 'div' ) );
		sidebarRight.id = 'sbr';
		
		sidebarLeft.innerHTML =
			'<div class="control" onclick="toggleBar( sidebarLeft )">[X]</div>' +
			'<h1>Hash Query Permalinks</h1>' +
			'<p><a id="permalink" title="Copy this link." href="#" target="_blank">permalink</a></p>' +
			// '<p><button onclick="setUrlHash(); " >Update hash</button> </p>' +
			'<p><button onclick="clearHash(); " >Clear hash. Return to default settings</button></p>' +
			'<p>Click here if you have edited the query string in the address bar manually, <b>pressed Enter</b> and now want to update the display:</p>' +
			'<p><button onclick="onHashChange(); " >Update hash</button></p>' +
		'';

		statusBar.innerHTML =
			'<div id="toggle" class="control" onclick="toggleStatusBar()">[-]</div>' +
			'<div class="control" onclick="toggleBar( sidebarLeft ); toggleBar( sidebarRight );">[<span style="font-size: small; vertical-align: text-top; ">[]</span>] &nbsp;</div>' +
			'<h1>App Status</h1>' +
			'<div id="toggled">' +
				'<p>Numeric and other data that is updating in real-time goes here...</p>' +
			'</div>';

		sidebarRight.innerHTML =
			'<div class="control" onclick="toggleBar( sidebarRight )">[X]</div>' +
			'<h1>Control Panel</h1>' +
			'<div id="sbrBody">' +
			'</div>' +
		'';		
	}();
	
	//var statusBarBody = document.getElementById('toggled');
	//var sidebarRightBody = document.getElementById('sbr-body');

	function toggleBar( sidebar ) {
		if ( sidebar.style.display === '' ) {
			sidebar.style.display = 'none';
		} else {
			sidebar.style.display = '';
		}
	}

	function toggleStatusBar() {
		// var tg = document.getElementById("toggle");
		// var tgd = document.getElementById("toggled");
		if ( toggled.style.display === '' ) {
			toggle.innerText = '[+]';
			toggled.style.display = 'none';
		} else {
			toggle.innerText = '[-]';
			toggled.style.display = '';
		}
	}

	function p( str, obj ) { var p = obj.appendChild( document.createElement( 'p' ) );
		p.innerHTML = str;
	};

