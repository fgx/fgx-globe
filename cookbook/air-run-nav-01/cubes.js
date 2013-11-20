	console.log( new Date() );
	
	geometry = new THREE.IcosahedronGeometry( 10, 1 );
	material = new THREE.MeshBasicMaterial( { color: 0x000000, wireframe: true, wireframeLinewidth: 2 } );

	goodies = new THREE.Mesh( geometry, material );
	goodies.position.set( 50, 20, 50);
	scene.add( goodies );
	
	function doStuff() {
		goodies.rotation.x = Date.now() * 0.0002;
		goodies.rotation.y = Date.now() * 0.0005;
	}