Data Globes
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

2013-02-25 ~ Theo  
Started Change Log in GitHub Read Me  
Created folders for textures & fgx-globe r2 & populated fgx-globe-r2  
OBJ.planeId.hdg & dist_nm: no longer arrays, now single values  
Addeded OBJ.planeId.update  
Moved propellers back into correct location r1 + r2  
Cleaned up processFlightsData()  
Added 'mothball' function - to remove non-active planes from the scene  
Updated text to show the count of 'flying' and 'flown'  
Added an Equator  
Added back skywriting  

