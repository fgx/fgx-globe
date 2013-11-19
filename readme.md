FGx Globe
===========

[ FGx copyright notice and license](https://github.com/fgx/fgx.github.com/blob/master/FGx%20copyright%20notice%20and%20license.md)


FGX Globe

2013-05-03 ~ Current beta: FGX Globe R3.3 ~ beta

Re-jigged the models so as to have smaller file sizes. Also now have a certain amout of pre-loading. Many issues with deleting, aircraft scal and direction remain.

2013-04-30 ~ Current beta: FGX Globe R3.3 ~ beta

Many shiny new things in this release. FGx Globe can now load any number of 3D models and these may be allocated to the variety of Crossfeed flights as desired. Currently there are eight available models, and this number should increase over time. The hurdle of dealing with callbacks and the load and delete on demand issues have mostly been worked out - though there may be some zombies still flying about from time to time.All of this seems to be working with a reasonable response time and with a good FPS rate.There are still a lot of bugs and much crafting and finishing to do, as well as a number of user experience matters to be considered.For example, perhaps the planes in the main 3D globe view are headed incorrectly.

There have been a number of other tweaks. For example, the scale of the aircraft changes as you zoom in and out. The camera motion is less jerky and stops automaticall if you zoom in and restarts if you zoom all the way out.

2013-04-28 ~ Current beta: FGX Globe R3.2 ~ beta

There is a significant new feature in that the airplanes are now all b777 3D models. The issue is that these models are taking longer to load and because of timing (callback) are not getting to the browser in time to be rendered. The quick fix is to keep re-loading the page. After three or so page reloads the models will be in the browser's cache and will be displayed. This issue will be dealt with ASAP. The other cool things are in response to Geoff's requests and these are the additions to the flight windows. A flight windows with OSM now has a select zoom drop-down list and your current setting is retained after the refresh and in permalinks Also the flight windows now shows a 2D image (courtesy of pigeond.net) of a plane rotated to current heading.

Also there are several smaller tweaks: The number of planes flying is displayed in the app window title bar and in the main menu title bar. The main menu is using smaller text in most places and margins have been adjusted - all without disrupting the jQuery UI themes. And the text on Info, TBD and other pages has been edited and updated.

2013-04-27 ~ Current beta: FGX Globe R3.1 ~ beta

The drop-down lists have received a lot of attention. It should now be a fairly straightforward process to select a different theme or map. Also what gets closed stays closed. This includes windows that have been closed and flights that have been terminated. More world maps have been added to the globe and the TBD panel is beginning to have a healthy set of issues to fix and features to add.

Work has also continued on bringing in 3D models of airplanes. The current issue has to with dealing with what to do while waiting during the loading times for the 3D models, but this appears to be a solvable issue.

2013-04-26 ~ Current beta: FGX Globe R3 ~ beta

This revision begins to feel as if its getting somewhere. The code is simpler, shorter and does more than before. In particular there is much better separation between the user interface and the 3D world. The user interface is now built using jQuery UI while the 3D all resides in a separate file embedded in an iframe.

The user interface now provides a table that displays all the flights currently underway. For each flight there is a clickable button that opens a separate window. Multiple windows may be opened - each of which displays the current position and navigation data for a single plane. You may select from a variety of map data sources. The user interface is theme-able with all the standard 20+ jQuery UI themes available at the click of a button. All significant settings are savable as 'permalinks'.

On the 3D side, the data-handling procedures have been re-written in a much more simple and more straightforward fashion. Also, there first steps have been taken introduce more realistic planes. See below.

There is still much unfinished work in this build. In particular the only way to remove terminated flights id to reload the window and the only way to completely delete a window is to reset the permalink. And there are several issues with the drop-down lists. Please note that all building and testing has been on Google Chrome. Other browsers will have issues. Other issues are listed in the TBD panel of the main menu.

Current revision: FGX Globe R2 - dev

FGx Globe Cookbook Files

While working on the next revision of FGx Globe, various demo files showing particular aspects of an issue are being created. Here they are, with most recent file at the top.

2013-05-03 ~ airports-runways-navaids r3

New jQuery UI livery. Updates to the way zooming affects the level of detail.

2013-04-26 ~ load-plane-3d

This file is the result of trying to ascertain the complexity of sourcing FOSS 3D models of airplanes on the web, importing them in Blender, simplifying and centering the model, exporting the model in JSON format and then importing the file into a Three.je web page. This file demonstrates several interesting things: It took no more than two hours to source the file, fire up Blender and reignite some memory of its complex user interface, install the Three.js exporter, delete extraneous detail such as landing wheels, export the new file and then create this little demo. Eventually, it would appear that it's likely to be possible to convert several planes an hour.

It also looks like there are little or no performance issues with Three.js with loading a number of nearly but not completely identical models. Note that each is a different color, but each could wear a different bitmap.

2013-04-19 ~ j3qUE FGx r1

A proposed user experience/interface for FGx Globe based on jQuery UI. Includes the abilities to select a theme and to save all current settings as permalinks.

2013-04-13 ~ airports-runways-navaids r2.4 - no changes in file name

Adds images of airports, links and more.

2013-03-20 ~ airports-runways-navaids r2.3 - no changes in file name

Code cleanup and fixes. Preparing to bring the planes back in

2013-03-19 ~ airports-runways-navaids r2.2 - no changes in file name

Geoff's navaids data has been folded into the mix. There is now mousewheel support. And the app is fully name space compliant.

2013-03-18 ~ airports-runways-navaids r2.1 - no changes in file name

Leaving the test case sceanrios and heading towards a usable user interface: Distances are now calculated from the camera position rather than a separate object. The number of airports displayed now relates to altitude and distance from camera. Plus nemerous changes to the display of text output.

2013-03-17 ~ airports-runways-navaids r2

Fixes heads-up display issues. Adds bitmaps. Some code clean-up. Runways and navaids display: not displayed for the moment.

2013-03-11 ~ airports-runways-navaids.

This is a later edition of one of the earlier apps. It loads the data for the 27K airports as well as runways and navaids from ourairports.com.

Each cube represents an airport. As you move your cursor over one of the cubes, the runway data details and nearby navigational aids are displayed in the 'Readout' sidebar.

2013-03-05 ~ open-geoff-file-head-ups-only-nearby.html.

This app loads and shows details of 27,000 airports nearest to a movable reference point. It uses a mouseover 'heads-p' pop-up to display data.

2013-03-05 ~ globe-circumscribe-airports.html.

As above with a nicer globe circumscribing user interface.

2013-03-05 ~ globe-circumscribe-airports-2k-only.

What does a globe with 2,134 airports look like? Crowded in some places. Empty in other places. BTW, France sure has a lot of airports.

See the globe at the top right corner of this page for a subset of the features - this globe has no heads-up, etc..

2013-03-04 ~ Open Geoff's file show only nearby.

Loads the data file with 27,000 airports, but displays only the cubes representing airports that are close to the tracking sphere. This demo appears to airports that may be of immediate interest to the pilot and yet allow for an acceptable FPS.

2013-03-03 ~ Open Geoff's file and find nearby. Loads 27,000 airports and places a cube for each in 3D space. Allows you move a sphere using the X, Y, and Z slider bars. The cubes within a selectable nearby range of the tracking sphere are highlighted.

This demo will mostl likely bring your computer to its knees. The fan should turn on, the FPS will drop to below 5.

The issue at stake: Can we provide this data - along with pretty titles and mouseover capabilities and so on - and still attain 25 FPS?

Open Geoff's file and display. Loads 27,000 airports and places a cube for each in 3D space. Takes long time to load.

2013-03-02 ~ Find nearby. Highlight objects nearby a movable point of interest in 3D space.

2013-03-02 ~ Globe Circumscribe. Investigating ways of moving the camera around a globe.


FGX Globe R2 - dev

2013-02-28

All global variables have been incoporated into the FGx name space. This was easier than anticipated and offers unanticipated benefits in that with the addition of just a few keystrokes all variable values may be persused in the JavaScript console

And a lot of other cool 3D/2D wormhole stuff was done as well...

2013-02-27

The beginning of an API via query string has been added. Currently you can set the intitial view by adjusting the default camera latitude, longitude and radius. Other variables include being able to set the airplane scale, altitude scale, refresh rate as well as controlling the rate of movement of your pointing device.

The following are some URLs with query strings that you may try out:

Default - no query string

SFO

Western Europe

Japan

OZ/NZ

South America

For further details please the FGX Globe API Documentation.

2013-02-26

R2 code has been copied to a new folder - at the link provided above.

Development work will continue from here. From time to time the code will be copied to the R2 or 'build' folder.

Progress for the day included re-jigging the placard and heads-up displays to follow Geoff's requests. Thumbnail images of the planes (where available) are displayed in the heads-up.

FGX Globe R2

2013-02-25 ~ Fixed bugs, added comments, streamlined the code and added new features. What more could you ask for?

Some of the highlights of the release are that planes not being updated by CrossFeed are being 'mothballed' and removed from the flight view. The display now now tells you how many planes are currently flying and have flown in the current session. There is a pretty new Equator indicator. The skywriting feature is now back in operation. And, propellers are back where they should be - on the front of the plane.

FGX Globe R1

2013-02-23 ~ This was the first release after being renamed and moved over from being Data Globe #4 at Urdacha.

FGX Globe acquires data from FGX, a special effects group hosted in Switzerland. FGX builds add-ons for FlightGear - the popular FOSS flight simulator. FGX Globe talks to FGX's Crossfeed near real-time data feed which shows all the Internet-connected FlightGear planes currently in the air.

The release adds headings being updated, plane and alitutude scaling, North and South Poles, inactive planes being grayed as well as a number of code clean-ups.

2013-02-25 ~ just getting off the ground...

Geographic data represented on spheres has certainly created some pretty maps.

But can a globe be used to represented non-geographical big-data in successful ways?

This repository is about the exploration of such possibilities.

The first data globe to arrive here is FGX Globe.

FGX Globe acquires data from [FGX](http://www.fgx.ch/). FGX builds add-ons for [FlightGear](http://www.flightgear.org/) - the popular FOSS flight simulator, 

In particular, FGX Globe uses the [Crossfeed](http://crossfeed.fgx.ch/data) near real-time data feed which shows all the Internet-connected planes in the air.

For the latest updates please have a look at [FGx Open Source Projects](http://fgx.github.com)


## Change log

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

