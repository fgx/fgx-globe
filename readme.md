FGx Globe
===========

2013-02-25 ~ just getting off the ground...

Geographic data represented on spheres has certainly created some pretty maps.

But can a globe be used to represented non-geographical big-data in successful ways.

This repository is about the exploration of such possibilities.

The first data globe to arrive here is FGX Globe.

FGX Globe acquires data from [FGX](http://www.fgx.ch/). FGX builds add-ons for [FlightGear](http://www.flightgear.org/) - the popular FOSS flight simulator, 

In particular, FGX Globe uses their [Crossfeed](http://crossfeed.fgx.ch/data) near real-time data feed which shows all the Internet-connected planes in the air.

Have a look at [FGX Globe R2](http://jaanga.github.com/data-globes/fgx-globe-r2/)


## Change log

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

