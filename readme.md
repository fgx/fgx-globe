![FGx Logo]( http://fgx.github.io/fgx-cap-40x30.png) FGx Globe Read Me
======================================================================

Your world - in ways you have never seen before.

[FGx Globe R5]( http://fgx.github.io/fgx-globe/fgx-globe-r5/ )

See also:

[FGx Globe R5: New Globe type, More Aircraft, More thumbnails]( http://www.jaanga.com/2013/12/fgx-globe-r5-new-globe-type-more.html )

## Project Links

You have two ways of viewing the FGx Globe files:  

* Code hosted on GitHub: [fgx.github.io]( http://fgx.github.io/fgx-globe/ "view the files as apps." ) <input value="<< You are now probably here." size=28 style="font:bold 12pt monospace;border-width:0;" >  
* Source code on GitHub: [github.com/fgx]( https://github.com/fgx/fgx.github.io/fgx-globe/ "View the files as source code." ) <scan style=display:none ><< You are now probably here.</scan>

## Road Map
* Add paint the stars using their relative luminosity in their correct positions, see Marble. Data is available via x-plane .dat

## Updates ~ 2013-11-19

This is the hot stuff:

[FGx Globe R5]( http://fgx.github.io/fgx-globe/fgx-globe-r5/ )

[Air Run Nav R1]( http://fgx.github.io/fgx-globe/cookbook/air-run-nav-01/ )

* Release 1.0 ~ Many issues.
* Takes too long to load. But, once loaded, you can pan, zoom and rotate with your mouse,
* Edit the Latitude and the longitude to go to new location
* Or choose a different city from the drop down list.
* Both of these actions take way too long. We will have to learn how to cheat here,
* Next is the list of 27,151 airports with 27,151 tooltips << Try that with PostGIS.
* Click on an airport to paint the screen with its data. GitHub data is behind Gitorious data - so many errors occur.
* Clicking on an airport only shows its pariculars. Upcoming release will take you there
* Error: Painted text can prevent you from rotating screen. Work-around: Click outside text area or load airport with no data.
* Click 'Get Nearby Airports' to see all airports in the current tile. 
* Airports with ILS display each ILS as a correctly headed but badly positioned green bar. All other airports just show a red cube.
* Airport placards now uses Three.js Sprites. Placards will look toward you no matter where you move.
* Some locations have moving 3D objects. These objects are inserted at specified locations by a Google Docs spreadsheet. Why? Just because we can.
* Different map types got turned off, They will be back
 


## Copyright Notice and License

[ FGx copyright notice and license](https://github.com/fgx/fgx.github.com/blob/master/FGx%20copyright%20notice%20and%20license.md)

## Change log

2013-12-11 ~ Theo

* R5 is up
* Add new bump-map globe with clouds
* Add ablity to stop globe rotating to Global Settings tab
* Just about all thumbnails now appear correctly

2013-12-05 ~ Theo

* New index.html
* fixed links so works with new FGx Aircraft dirs

2013-12-04 ~ Theo

* Updated so as to work with revised FGx Aircraft repo
* Add logo/text to read me
* Tried adding sprites that always camera as alternate to fixed postion placars for aircraft placards but result was confusing so reverted.
 

2013-11-24 ~ Theo

* Added link and notes to info panel
* Started adding auto-rotate checbox

2013-11-19 ~ Theo

* Air Run Nav R1 added
* History pages added and older text moved there

2013-11-18 ~ Theo

* New release folder 4.0
* Now loads Geoff FG to JSON models
* Loads latest jQuery/jQueryUI/te,plates


2013-05-03 ~ Theo
* smaller file size models from FG via blender
* fgx globe: seymour is pre-loaded

2013-05-02 ~ Theo
* fgx globe airports: lot of UI work

2013-05-01 ~ Theo
* Loaded Aerostar model - exported from FlightGear

2013-04-30 ~ Theo
* Load multiple types of planes
* Eight types of models now avalable
* Improved call back handling
* Improved already loaded handling
* More logical variable names
* Better deletion of terminated flights
* Aircraft scale changes with camera distance
* Camera motion stops when you zoom in

2013-04-28 ~ Theo
* Number of planes shows in window title bars
* Planes are now all b777 3D models
* Flight windows with OSM has select zoom and retained in permalinks
* Flight windows now show a 2D image of plane rotated to current headding 
* The main menu is using small text in most places
* Text on Info page updated

2013-04-27 ~ Theo
* 4flight-window-settings.html: simplified JavaScript and HTML
* 3globa-settings.html: simplified JavaScript and HTML
* 0info.html tidied
* Added more maps
* Planes are deleted as and when Crossfeed no longer lists them
* Windows stay closed - and are deleted from the permalink 
* started work on bringing in 3D models

2013-04-26 ~ 
* Updated index page for fgx-globe
* Added load-plane-3d
* Updated fgx-globe-r3

2013-04-19 ~ Theo
* Added j3QUE FGx r1
* New index page for fgx-globe
* fgx-globe-r2-dev uses updated Crossfeed link 

2013-04-13 ~ Theo
* World Airports,Runways and Navaids r2.4: airport image links to Google Maps
* World Airports,Runways and Navaids r2.4: tightened up Heads-up diaply
* World Airports,Runways and Navaids r2.4: added link to wunderground.com

2013-03-20 ~ Theo
* airport symbol size is scaled to the camera distance
* display output prettified with degree symbols
* Checked Geoff's naivaid file for commas in name field. Found none
* Deleted quotes from file. Reduced file size by 3%
* Checked Geoff's icao file for commas in name field. Found none
* Deleted quotes from file. Reduced file size by 4.2%
* Replaced custon XMLHttpRequest functions with generic function
* Was loading two starfield bitmaps, now just one!

2013-03-19 ~ Theo
* updates to airports-runways-navaids r2.2
* Added loading, reading display of Geoff's navaid data
* Completed namespacification
* Added mousewheel event capture and linked it to onMouseUp function

2013-03-18 ~ Theo
* update airports-runways-navaids r2.1
* Distance calculations now relate to camera position, not a separate airplane object
* Number of airports displayed relates to camera altitude versus number of ILS and distance from camera
* Scale of airport symbols relates to alitude
* Settings display updated
* Heads-up display shows number of runways and ILS
* More variables embedded in the FGx name space  
* Ongoing code clean-up

2013-03-17 ~ Theo
* Added airports-runways-navaids r2
* r2: skysphere with one of Paul Blunt's PNGs
* r2: globe has texture
* r2: added lights
* r2: fixes silly bug where heads-up displayed incorrectly. Fixed position of sidebatr causing issue

2013-03-09 ~ Theo
* Adding airports-runways-navaids folders + data

2013-03-09 ~ Theo
* Adding copyright and licensing information

2013-03-07 ~ Theo
* added word-wrap:break-word; to heads-up css in globe-circumscribe-airports-2k-json.html

2013-03-06 ~ Theo
* added aptinfo folder with navaid data for 2,123 airports
* cookbook: added globe-circumscribe-airports-2k-json.html 
- not fully working

2013-03-05 ~ Theo
* cookbook: added open-geoff-file-head-ups-only-nearby.html
- Shows details of nearest of 27,000 airports
* cookbook: added globe-circumscribe-airports.html
- ditto with nicer UI
* cookbook: added globe-circumscribe-airports-2k-only
- what does a globe with 2,134 airports look like? Crowded.


2013-03-04 ~ Theo
* cookbook: added 'open-geoff-file-show-only-nearby.html'

2013-03-03 ~ Theo
* cookbook: added 'open-geoff-file-and-display.html'
* cookbook: added 'open-geoff-file-and-find-nearby.html'

2013-03-02 ~ Theo
* cookbook: added 'find-nearby.html'
* cookbook: added 'globe-circumscribe.html'

2013-03-02 ~ Theo
* Wiki: worked on mission statement 

2013-02-28 ~ Theo
* Started & completed process of putting variables in a name space. Thanks to Pete for the push...
* mothball: looks for latest update number otherwise delete...
* Added GoSFO and GoWorld ~ wormholes into parallel worlds

2013-02-27 ~ Theo
* Updated public home page regarding dev version, new code 
* default camera position is set by laitude, longitude and radius using new update position function
* Started adding API with access via query string 

*2013-02-26 ~ Theo
* Rejigged placard and heads-up distrubition of info
* Added display of thumbnails to heads-up where model thumbnails exist.

2013-02-25 ~ R2 ~ Theo  
* Started Change Log in GitHub Read Me  
* Created folders for textures & fgx-globe r2 & populated fgx-globe-r2  
* OBJ.planeId.hdg & dist_nm: no longer arrays, now single values  
* Addeded OBJ.planeId.update  
* Moved propellers back into correct location r1 + r2  
* Cleaned up processFlightsData()  
* Added 'mothball' function - to remove non-active planes from the scene  
* Updated text to show the count of 'flying' and 'flown'  
* Added an Equator  
* Added back skywriting  

2013-02-25 ~ R1 ~ Theo  
* simplified object management
* globe has diameter of 100 units
* planes have heading - but I think they are off by 90 degrees or 270 or something but I have not taken the time to track this down yet.
* sliders allow you to set plane scale and altitude scale
* planes with an altitude of 0, are grayed.
* moving the cursor over a plane cause a 'heads-up' display to appear which displays model name and the remaining data from the feed not shown on the placard

