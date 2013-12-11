// Source for a number of the ideas here: http://net.tutsplus.com/tutorials/javascript-ajax/creating-a-windows-like-interface-with-jquery-ui/

$(function() {

	var _init = $.ui.dialog.prototype._init;

	$.ui.dialog.prototype._init = function() {
		_init.apply(this, arguments);

		var dialog_element = this;
		var dialog_id = this.uiDialogTitlebar.next().attr("id");

		this.uiDialogTitlebar.append('<a href="#" id="' + dialog_id + '-minbutton" class="ui-dialog-titlebar-minimize ui-state-default ui-corner-all">'+
			'<span class="ui-icon ui-icon-newwin ui-icon-minusthick"></span></a>');

		$('#dialog_window_minimized_container').append(
			'<div class="dialog_window_minimized ui-widget ui-state-default ui-corner-all" id="' + dialog_id + '_minimized">' +
			this.uiDialogTitlebar.find('.ui-dialog-title').text() +  '<span class="ui-icon ui-icon-newwin"></div>');

		$("#" + dialog_id + "-minbutton").hover(function() {
			$(this).addClass("ui-state-hover");
		}, function() {
			$(this).removeClass("ui-state-hover");
		}).click(function() {
			dialog_element.close();
			$("#" + dialog_id + "_minimized").show();
		});

		$("#" + dialog_id + "_minimized").click(function() {
			$(this).hide();
			dialog_element.open();
		});
	};

	$.newDialog = function ( win ) {
		$("body").append('<div class="dialog_window" id="' + win.id + '"  >loading...</div>');
console.log ( "left+" + win.left + " top+" + win.top );		
		dialog = $('#' + win.id).dialog({
			autoOpen: true,
			height: win.height,
// perfect this...				
			position: { 
				my: "left top",
				at: "left+" + win.left + " top+" + win.top,
				of: window
			},
			title: win.title,
			width: win.width,
			dragStop: function( event, ui ) {
				win.left = ui.position.left;
				win.top = ui.position.top;
				$.setHash();
			},
// source: http://acuriousanimal.com/blog/2011/08/16/customizing-jquery-ui-dialog-hiding-close-button-and-changing-opacity/				
			open: function( event, ui) {
				if ( win.closer === "false" ) $(this).parent().children().children(".ui-dialog-titlebar-close").hide(); 
				$(this).parent().css({ opacity: 0.60 });
			},
		
			resize: function( event, ui ) {
				win.height = ui.size.height.toFixed();
				win.width = ui.size.width.toFixed();
				$.setHash();
			}
		});
		$( "#" + win.id).load( win.fname );
		
	};

// permalinks
	var e = $.elements = {};
	
	$.setHash = function() {
		var settings = "";
		for (var item in e) {
			if ( item.substr(0,5) == "theme") {
				settings += item + "=" +  e[item] + "#";
				link.setAttribute("href", "http://code.jquery.com/ui/1.10.2/themes/" + e[item] + "/jquery-ui.css");
			}
			if (item.substr(0,5) == "check" || item.substr(0,2) == "Tj" || item.substr(0,6) == "select") {
				settings += item + "=" +  e[item] +  "#";
			} else if ( item.substr(0,6) == "window") {
				for (var bits in e[item] ) {
					settings += item + "." + bits + "=" + e[item][bits]  +  "#";
				}
			}
		}
		$.permalink = location.hash = settings;
	};

	$.resetHash = function () {
		window.history.pushState( "", "", window.location.pathname);
		$.permalink = "";
	};

// defaults
	$.getHash = function () {
		if ( location.hash === "" ) {
			e.thm = {
				name: "smoothness"
				select: 16
			}
			e.window1 = {
				closer: "false",
				fname: "ajax/hello-world.html",
				height: window.innerHeight - 200,
				id: "dialog_window_1",
				left: "3000",
				title: "j3qUE FGx r1",
				top: "50",
				width: "500"
			};
			e.window2 = {
				closer: "true",
				fname: "ajax/bonjour-monde.html",
				height: "450",
				id: "dialog_window_2",
				left: "30",
				title: "Bonjour Monde!",
				top: "200",
				width: "350"
			};

			e.TjLineWidth = 5;
			e.TjScaleX = 1;
			e.TjScaleY = 1;
			e.TjScaleZ = 1;

			$.permalink = "";
			
// or load from hash fragment				
		} else {
			var item, win, hashes = location.hash.split("#");
			for (var i = 1, len = hashes.length - 1; i < len; i++) {
				item =  hashes[i].split("=");
				
// will change the following to three level object" elements.window.item...					
				if ( item[0].substr(0,6) === "window") {
					if ( e[item[0].substr(0,7) ] === undefined ) {
						win = e[ item[0].substr(0,7) ] = {};
					}
					win[ item[0].substr(8) ] = item[1];
				} else {
					// if ( item[1] === "false" ) item[1] = false;
					e[ item[0] ] = item[1];
				}
			}
			$.permalink = location.hash;
		}
	};
});