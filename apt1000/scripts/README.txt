file : README.txt - 20130310

xp2csv.pl - This script was used to read the X-Plane airport and 
navigation data file, and generate CSV and JSON outputs.

It uses some local 'require' libraries -
Bucket.pm    - Emulates the FlightGear 'bucket' technology
fg_wsg84.pl  - Provides some WSG-84 distance and direction functions
lib_utils.pl - Miscellaneous functions.

chkjson.pl - To check that the json can at least be parsed without 
error by the Perl json module.

WARNING: These scripts are not very user friendly in that they 
contain HARD CODED input and output paths. They would require 
manual change to run in other than the original environment.

Further, these scripts were run only in Windows. While some 
effort has been made that they should also run in linux, this 
has NOT been tested.

They are released under a GNU GPL version 2 license.

NOTE: The X-Plane navigation data was found to contain duplicated 
entries, and co-located objects like VOR and DME beacons given 
separate lines in the data.

This script attempts to eliminate such duplications, and present 
co-located objects as one. This elimination was based on them 
having the same id and radio frequency, and being within say 
10 meters, but there were some exceptions and anomolies that 
should be checked. See the sub filter_nav_list()


# eof
