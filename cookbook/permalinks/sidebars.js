
	var sidebarLeft, statusBar, sidebarRight, sidebarRightBody;

	var css = function(){
		var css = document.createElement('style');
		css.innerHTML +=
			'h1 { margin: 0; min-width: 200px; }' +

			'#sbl { background-color: #eee; outline: 1px solid; left: 30px; margin: 10px; opacity: 0.8; padding: 10px; position: absolute; ' +
				'text-align: left; top: 50px; max-width: 350px;}' +

			'#stbHeader { background-color: #eee; outline: 1px solid; margin: 10px auto; opacity: 0.8; padding: 10px; ' +
				'text-align: left; top: 20px; width: 500px;}' +

			'#sbr { background-color: #eee; outline: 1px solid; margin: 10px; opacity: 0.8; padding: 10px; position: absolute; ' +
				'right: 20px; text-align: left; top: 30px; max-width: 350px;}' +

			'#sbr-body {  height: 95%; overflow-y: scroll; }' +

			'div.control { color: #aaa; cursor: hand; cursor: pointer; float: right; }' ;

		document.body.appendChild( css );
	}();

	var sbl = function(){
		sidebarLeft = document.createElement( 'div' );
		sidebarLeft.id = 'sbl';
		document.body.appendChild( sidebarLeft );
		sidebarLeft.innerHTML =
			'<div class="control" onclick="toggleBar( sidebarLeft )">[X]</div>' +
			'<h1>Hash Query Permalinks</h1>' +
			'<p><a id="permalink" href="#">permalink</a></p>' +
			'<p><button onclick="updateHash(); " >Update hash</button> </p>' +
			'<p><button onclick="clearHash(); " >Clear hash</button></p>' +
			'<p><button onclick="parseHash(); " >Parse hash</button></p>';
			'';

	}();

	var stb = function(){
		statusBarHeader = document.createElement( 'div' );
		statusBarHeader.id = 'stbHeader';
		document.body.appendChild( statusBarHeader );
		statusBarHeader.innerHTML =
			'<div id="toggle" class="control" onclick="toggleStatusBar()">[-]</div>' +
			'<div class="control" onclick="toggleBar( sidebarLeft ); toggleBar( sidebarRight );">[<span style="font-size: small; vertical-align: text-top; ">[]</span>] &nbsp;</div>' +
			'<h1>Hash Query Status</h1 "h1">';

		statusBarBody = document.createElement( 'div' );
		statusBarBody.id = 'stbBody';
		statusBarHeader.appendChild( statusBarBody );
		statusBarBody.innerHTML =
			'<p>Numeric and other data that is updating in real-time goes here...</p>';
	}();

	var sbr = function(){
		sidebarRight = document.createElement( 'div' );
		sidebarRight.id = 'sbr';
		document.body.appendChild( sidebarRight );
		sidebarRight.innerHTML =
			'<div class="control" onclick="toggleBar( sidebarRight )">[X]</div>' +
			'<h1>Control Panel</h1>';

		sidebarRightBody = document.createElement( 'div' );
		sidebarRightBody.style.height = (window.innerHeight - 120) + 'px';
		sidebarRightBody.id = 'sbr-body';
		sidebarRight.appendChild( sidebarRightBody );
		sidebarRightBody.innerHTML =
			'<p>This sidebar </p>' +
		'' ;

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
		if ( statusBarBody.style.display === '' ) {
			statusBarBody.style.display = 'none';
			tg.innerText = '[+]';
		} else {
			statusBarBody.style.display = '';
			tg.innerText = '[-]';
		}
	}

	function p( str, obj ) { var p = obj.appendChild( document.createElement( 'p' ) );
		p.innerHTML = str;
	};

