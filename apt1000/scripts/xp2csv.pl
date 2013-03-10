#!/usr/bin/perl
# NAME: xp2csv.pl
# AIM: Read X-Plane (Robin Pell) earth_nav.dat and apt.dat, and output as CSV and json to 
# a target directory
# geoff mclane - http://geoffmclane.com/mperl/index.htm - 20100801
use strict;
use warnings;
use File::Copy;
use Math::Trig;
use Time::HiRes qw( gettimeofday tv_interval );
my $os = $^O;
my $perl_dir = '/home/geoff/bin';
my $PATH_SEP = '/';
my $temp_dir = '/tmp';
if ($os =~ /win/i) {
    $perl_dir = 'C:\GTools\perl';
    $temp_dir = $perl_dir;
    $PATH_SEP = "\\";
}
unshift(@INC, $perl_dir);
require 'lib_utils.pl' or die "Unable to load 'lib_utils.pl' Check paths in \@INC...\n";
require 'fg_wsg84.pl' or die "Unable to load fg_wsg84.pl ...\n";
#require "Bucket2.pm" or die "Unable to load Bucket2.pm ...\n";
require "Bucket.pm" or die "Unable to load Bucket.pm ...\n";
# =============================================================================
# This NEEDS to be adjusted to YOUR particular default location of these files.
my $FGROOT = "D:/FG/xplane/1000";
###my $FGROOT = "D:/SAVES/xplane";
my $APT_FILE 	= "$FGROOT/apt.dat";	# the airports data file
###my $APT_FILE   = "$FGROOT/apt4.dat";	# the airports data file
my $NAV_FILE 	= "$FGROOT/earth_nav.dat";	# the NAV, NDB, etc. data file
my $FIX_FILE    = "$FGROOT/earth_fix.dat";	# the FIX data file
my $LIC_FILE    = "$FGROOT/AptNavGNULicence.txt";
# =============================================================================

# log file stuff
our ($LF);
my $pgmname = $0;
if ($pgmname =~ /(\\|\/)/) {
    my @tmpsp = split(/(\\|\/)/,$pgmname);
    $pgmname = $tmpsp[-1];
}
my $outfile = $temp_dir.$PATH_SEP."temp.$pgmname.txt";
open_log($outfile);

my $t0 = [gettimeofday];

my $out_path = 'C:\FG\17\fgx-globe\apt1000';
#my $out_path = $temp_dir.$PATH_SEP."temp-apts3";
#my $out_path = $temp_dir.$PATH_SEP."temp-apts2";
#my $out_path = $temp_dir.$PATH_SEP."temp-apts";

# program variables - set during running
# different searches -icao=LFPO, -latlon=1,2, or -name="airport name"
# KSFO San Francisco Intl (37.6208607739872,-122.381074803838)
my $aptdat = $APT_FILE;
my $navdat = $NAV_FILE;
my $licfil = $LIC_FILE;

my $SRCHICAO = 0;	# search using icao id ... takes precedence
my $SRCHONLL = 0;	# search using lat,lon
my $SRCHNAME = 0;	# search using name
my $SHOWNAVS = 0;	# show navaids around airport found

my $aptname = "strasbourg";
my $apticao = 'KSFO';
my $lat = 37.6;
my $lon = -122.4;
my $maxlatd = 0.5;
my $maxlond = 0.5;
my $nmaxlatd = 0.1;
my $nmaxlond = 0.1;
my $max_cnt = 0;	# maximum airport count - 0 = no limit
my $max_range_km = 5;   # range search using KILOMETERS
my $tmp_out_file = $temp_dir.$PATH_SEP."tempapt";
my $out_base = 'apt1000';

# features and options
my $tryharder = 0;  # Expand the search for NAVAID, until at least 1 found
my $usekmrange = 0; # search using KILOMETER range - see $max_range_km
my $sortbyfreq = 1; # sort NAVAIDS by FREQUENCY
my $load_log = 0;

my $write_output = 1;
my $add_newline = 1;
my $skip_done_files = 0;

my $output_full_list = 0;
my $do_nav_filter = 1;

# variables for range using distance calculation
my $PI = 3.1415926535897932384626433832795029;
my $D2R = $PI / 180;
my $R2D = 180 / $PI;
my $ERAD = 6378138.12;
my $DIST_FACTOR = $ERAD;
#/** Meters to Nautical Miles.  1 nm = 6076.11549 feet */
my $METER_TO_NM = 0.0005399568034557235;
#/** Nautical Miles to Meters */
my $NM_TO_METER = 1852;

my ($file_version);

my $av_apt_lat = 0;	# later will be $tlat / $ac;
my $av_apt_lon = 0; # later $tlon / $ac;

# apt.dat CODES - see http://x-plane.org/home/robinp/Apt850.htm for DETAILS
#my $aln =     '1';	# airport line
#my $rln =    '10';	# runways/taxiways line 810 OLD CODE
#my $sealn =  '16'; # Seaplane base header data.
#my $heliln = '17'; # Heliport header data.  

#my $rln =    '100';	# land runways
#my $water =  '101'; # Water runway
#my $heli =   '102'; # Helipad

# offsets into land runway array
#my $of_lat1 = 9;
#my $of_lon1 = 10;
#my $of_lat2 = 18;
#my $of_lon2 = 19;

my $twrln =  '14'; # Tower view location. 
my $rampln = '15'; # Ramp startup position(s) 
my $bcnln =  '18'; # Airport light beacons  
my $wsln =   '19'; # windsock
my $minatc = '50';
my $twrfrq = '54';	# like 12210 TWR
my $appfrq = '55';  # like 11970 ROTTERDAM APP
my $maxatc = '56';
my $lastln = '99'; # end of file

# nav.dat.gz CODES
my $navNDB = '2';
my $navVOR = '3';
my $navILS = '4';
my $navLOC = '5';
my $navGS  = '6';
my $navOM  = '7';
my $navMM  = '8';
my $navIM  = '9';
my $navVDME = '12';
my $navNDME = '13';
my @navset = ($navNDB, $navVOR, $navILS, $navLOC, $navGS, $navOM, $navMM, $navIM, $navVDME, $navNDME);
my @navtypes = qw( NDB VOR ILS LOC GS OM NM IM VDME NDME );

my $maxnnlen = 4;
my $actnav = '';
my $line = '';
my $apt = '';
my $alat = 0;
my $alon = 0;
my $glat = 0;
my $glon = 0;
my $rlat = 0;
my $rlon = 0;
my $dlat = 0;
my $dlon = 0;
my $diff = 0;
my $rwycnt = 0;
my $icao = '';
my $name = '';
my @aptlist = ();
my @aptlist2 = ();
my @navlist = ();
my @navlist2 = ();
my $totaptcnt = 0;
my $acnt = 0;
my @lines = ();
my $cnt = 0;
my $loadlog = 0;
my $outcount = 0;
my @tilelist = ();

my @warnings = ();

# debug tests
# ===================
my $test_name = 0;	# to TEST a NAME search
my $def_name = "hong kong";

my $test_ll = 0;	# to TEST a LAT,LON search
my $def_lat = 37.6;
my $def_lon = -122.4;

my $test_icao = 0;	# to TEST an ICAO search
my $def_icao = 'VHHH'; ## 'KHAF';  ## LFPO'; ## 'KSFO';

# debug
my $dbg1 = 0;	# show airport during finding ...
my $dbg2 = 0;	# show navaid during finding ...
my $dbg3 = 0;	# show count after finding
my $verb3 = 0;
my $dbg10 = 0;  # show EVERY airport
my $dbg11 = 0;  # prt( "$name $icao runways $rwycnt\n" ) if ($dbg11);
# ===================

### program variables
my $verbosity = 0;

sub VERB1() { return $verbosity >= 1; }
sub VERB2() { return $verbosity >= 2; }
sub VERB5() { return $verbosity >= 5; }
sub VERB9() { return $verbosity >= 9; }

sub show_warnings($) {
    my ($val) = @_;
    if (@warnings) {
        prt( "\nGot ".scalar @warnings." WARNINGS...\n" );
        foreach my $itm (@warnings) {
           prt("$itm\n");
        }
        prt("\n");
    } else {
        prt( "\nNo warnings issued.\n\n" ) if (VERB9());
    }
}

sub pgm_exit($$) {
    my ($val,$msg) = @_;
    if (length($msg)) {
        $msg .= "\n" if (!($msg =~ /\n$/));
        prt($msg);
    }
    show_warnings($val);
    close_log($outfile,$load_log);
    exit($val);
}


sub prtw($) {
   my ($tx) = shift;
   $tx =~ s/\n$//;
   prt("$tx\n");
   push(@warnings,$tx);
}


########################################################################
### SUBS
#/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
#/* Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2012             */
#/*                                                                                                */
#/* from: Vincenty inverse formula - T Vincenty, "Direct and Inverse Solutions of Geodesics on the */
#/*       Ellipsoid with application of nested equations", Survey Review, vol XXII no 176, 1975    */
#/*       http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf                                             */
#/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
#
#/**
# * Calculates geodetic distance between two points specified by latitude/longitude using 
# * Vincenty inverse formula for ellipsoids
# *
# * @param   {Number} lat1, lon1: first point in decimal degrees
# * @param   {Number} lat2, lon2: second point in decimal degrees
# * @returns (Number} distance in metres between points
# */
use constant PI    => 4 * atan2(1, 1);

my $FG_PI = PI;
my $FG_D2R = $FG_PI / 180;
my $FG_R2D = 180 / $FG_PI;
my $FG_MIN = 2.22507e-308;
my $NaN = -sin(9**9**9);
sub toRad($) {
    my $deg = shift;
    return ($deg * $FG_D2R);
}
sub toDeg($) {
    my $rad = shift;
    return ($rad * $FG_R2D);
}

sub isNaN { ! defined( $_[0] <=> 9**9**9 ) }
# function distVincenty(lat1, lon1, lat2, lon2) {
sub distVincenty($$$$$$$) {
    my ($lat1, $lon1, $lat2, $lon2, $raz1, $raz2, $rs) = @_;
    my $a = 6378137;
    my $b = 6356752.314245;
    my $f = 1/298.257223563;  #// WGS-84 ellipsoid params
    my $L = toRad($lon2-$lon1); #.toRad();
    my $U1 = atan((1-$f) * tan(toRad($lat1)));
    my $U2 = atan((1-$f) * tan(toRad($lat2)));
    my $sinU1 = sin($U1);
    my $cosU1 = cos($U1);
    my $sinU2 = sin($U2);
    my $cosU2 = cos($U2);
    my $lambda = $L;
    my ($lambdaP);
    my $iterLimit = 100;
    my ($sinLambda,$cosLambda,$sinSigma,$cosSigma,$sigma);
    my ($sinAlpha,$cosSqAlpha,$cos2SigmaM,$C);
    do {

        $sinLambda = sin($lambda);
        $cosLambda = cos($lambda);
        $sinSigma = sqrt(($cosU2*$sinLambda) * ($cosU2*$sinLambda) + 
            ($cosU1*$sinU2-$sinU1*$cosU2*$cosLambda) * ($cosU1*$sinU2-$sinU1*$cosU2*$cosLambda));
        if ($sinSigma==0) { return 0; } # co-incident points
        $cosSigma = $sinU1*$sinU2 + $cosU1*$cosU2*$cosLambda;
        $sigma = atan2($sinSigma, $cosSigma);
        $sinAlpha = $cosU1 * $cosU2 * $sinLambda / $sinSigma;
        $cosSqAlpha = 1 - $sinAlpha*$sinAlpha;
        $cos2SigmaM = $cosSigma - 2*$sinU1*$sinU2/$cosSqAlpha;
        if (isNaN($cos2SigmaM)) { $cos2SigmaM = 0; } #// equatorial line: cosSqAlpha=0 (§6)
        $C = $f/16*$cosSqAlpha*(4+$f*(4-3*$cosSqAlpha));
        $lambdaP = $lambda;
        $lambda = $L + (1-$C) * $f * $sinAlpha *
            ($sigma + $C*$sinSigma*($cos2SigmaM+$C*$cosSigma*(-1+2*$cos2SigmaM*$cos2SigmaM)));

    } while (abs($lambda-$lambdaP) > 1e-12 && --$iterLimit>0);

    if ($iterLimit==0) { 
        prt("formula failed to converge!\n");
        return 1; # $NaN; #// formula failed to converge
    }
    my $uSq = $cosSqAlpha * ($a*$a - $b*$b) / ($b*$b);
    my $A = 1 + $uSq/16384*(4096+$uSq*(-768+$uSq*(320-175*$uSq)));
    my $B = $uSq/1024 * (256+$uSq*(-128+$uSq*(74-47*$uSq)));
    my $deltaSigma = $B*$sinSigma*($cos2SigmaM+$B/4*($cosSigma*(-1+2*$cos2SigmaM*$cos2SigmaM)-
        $B/6*$cos2SigmaM*(-3+4*$sinSigma*$sinSigma)*(-3+4*$cos2SigmaM*$cos2SigmaM)));
    my $s = $b*$A*($sigma-$deltaSigma);
  
    #  // note: to return initial/final bearings in addition to distance, use something like:
    my $fwdAz = atan2($cosU2*$sinLambda,  $cosU1*$sinU2-$sinU1*$cosU2*$cosLambda);
    my $revAz = atan2($cosU1*$sinLambda, -$sinU1*$cosU2+$cosU1*$sinU2*$cosLambda);
    # return { distance: s, initialBearing: fwdAz.toDeg(), finalBearing: revAz.toDeg() };
    ${$raz1} = toDeg($fwdAz);
    ${$raz2} = toDeg($revAz);
    # s = s.toFixed(3); // round to 1mm precision
    ${$rs} = (int($s * 1000) / 1000);
    return 0;
}

sub trimall($) {	# version 20061127
	my ($ln) = shift;
	chomp $ln;			# remove CR (\n)
	$ln =~ s/\r$//;		# remove LF (\r)
	$ln =~ s/\t/ /g;	# TAB(s) to a SPACE
	$ln =~ s/\s\s/ /g while ($ln =~ /\s\s/); # all double space to SINGLE
	$ln = substr($ln,1) while ($ln =~ /^\s/); # remove all LEADING space
	$ln = substr($ln,0, length($ln) - 1) while ($ln =~ /\s$/); # remove all TRAILING space
	return $ln;
}

sub show_airports_found {
	my ($mx) = shift;	# limit the AIRPORT OUTPUT
	my $scnt = $acnt;
	my $tile = '';
	if ($mx && ($mx < $scnt)) {
		$scnt = $mx;
		prt( "Listing $scnt of $acnt aiports " );
	} else {
		prt( "Listing $scnt aiport(s) " );
	}

	if ($SRCHICAO) {
		prt( "with ICAO [$apticao] ...\n" );
	} elsif ($SRCHONLL) {
		prt( "around lat,lon [$lat,$lon], using diff [$maxlatd,$maxlond] ...\n" );
	} else {    # $SRCHNAME
		prt( "matching [$aptname] ...\n" );
	}
	for (my $i = 0; $i < $scnt; $i++) {
		$diff = $aptlist2[$i][0];
		$icao = $aptlist2[$i][1];
		$name = $aptlist2[$i][2];
		$alat = $aptlist2[$i][3];
		$alon = $aptlist2[$i][4];
		$tile = get_bucket_info( $alon, $alat );
		while (length($icao) < 4) {
			$icao .= ' ';
		}
		$line = $diff;
		while (length($line) < 6) {
			$line = ' '.$line;
		}
		#$line .= ' '.$icao.' '.$name.' ('.$alat.','.$alon.") tile=$tile";
		$line .= ' '.$icao.' '.$name.' ('.$alat.','.$alon.") tile=".get_tile($alon,$alat);
		prt("$line\n");
		$outcount++;
		add_2_tiles($tile);
	}
	prt( "Done $scnt list ...\n" );
}


sub get_tile { # $alon, $alat
	my ($lon, $lat) = @_;
	my $tile = 'e';
	if ($lon < 0) {
		$tile = 'w';
		$lon = -$lon;
	}
	my $ilon = int($lon / 10) * 10;
	if ($ilon < 10) {
		$tile .= "00$ilon";
	} elsif ($ilon < 100) {
		$tile .= "0$ilon";
	} else {
		$tile .= "$ilon"
	}
	if ($lat < 0) {
		$tile .= 's';
		$lat = -$lat;
	} else {
		$tile .= 'n';
	}
	my $ilat = int($lat / 10) * 10;
	if ($ilat < 10) {
		$tile .= "0$ilat";
	} elsif ($ilon < 100) {
		$tile .= "$ilat";
	} else {
		$tile .= "$ilat"
	}
	return $tile;
}

sub add_2_tiles {	# $tile
	my ($tl) = shift;
	if (@tilelist) {
		foreach my $t (@tilelist) {
			if ($t eq $tl) {
				return 0;
			}
		}
	}
	push(@tilelist, $tl);
	return 1;
}

sub is_valid_nav {
	my ($t) = shift;
    if ($t && length($t)) {
        my $txt = "$t";
        my $cnt = 0;
        foreach my $n (@navset) {
            $cnt++;
            if ($n eq $txt) {
                $actnav = $navtypes[$cnt];
                return $cnt;
            }
        }
    }
	return 0;
}

sub set_average_apt_latlon {
	my $ac = scalar @aptlist2;
	my $tlat = 0;
	my $tlon = 0;
	if ($ac) {
		for (my $i = 0; $i < $ac; $i++ ) {
			$alat = $aptlist2[$i][3];
			$alon = $aptlist2[$i][4];
			$tlat += $alat;
			$tlon += $alon;
		}
		$av_apt_lat = $tlat / $ac;
		$av_apt_lon = $tlon / $ac;
	}
}

# push(@aptlist2, [$diff, $icao, $name, $alat, $alon]);
# my $nmaxlatd = 1.5;
# my $nmaxlond = 1.5;
sub near_an_airport {
	my ($lt, $ln, $dist, $az) = @_;
    my ($az1, $az2, $s, $ret);
	my $ac = scalar @aptlist2;
    my ($x,$y,$z) = fg_ll2xyz($ln,$lt);    # get cart x,y,z
    my $d2 = $max_range_km * 1000;      # get meters
	for (my $i = 0; $i < $ac; $i++ ) {
		$diff = $aptlist2[$i][0];
		$icao = $aptlist2[$i][1];
		$name = $aptlist2[$i][2];
		$alat = $aptlist2[$i][3];
		$alon = $aptlist2[$i][4];
        if ($usekmrange) {
            my ($xb, $yb, $yz) = fg_ll2xyz($alon, $alat);
            my $dst = sqrt( fg_coord_dist_sq( $x, $y, $z, $xb, $yb, $yz ) ) * $DIST_FACTOR;
            if ($dst < $d2) {
                $s = -1;
                $az1 = -1;
                $ret = fg_geo_inverse_wgs_84($alat, $alon, $lt, $ln, \$az1, \$az2, \$s);
                $$dist = $s;
                $$az = $az1;
                return ($i + 1);
            }
        } else {
    		my $td = abs($lt - $alat);
	    	my $nd = abs($ln - $alon);
		    if (($td < $nmaxlatd)&&($nd < $nmaxlond)) {
                $s = -1;
                $az1 = -1;
                $ret = fg_geo_inverse_wgs_84($alat, $alon, $lt, $ln, \$az1, \$az2, \$s);
                $$dist = $s;
                $$az = $az1;
			    return ($i + 1);
		    }
        }
	}
	return 0;
}

sub show_navaids_found {
	my ($ic, $in, $line, $lcnt, $dnone);
	my ($diff, $icao, $alat, $alon);
	my ($typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name, $off);
    my ($dist, $az, $adkm, $ahdg);
    my $hdr = "Type  Latitude     Logitude        Alt.  Freq.  Range  Frequency2    ID  Name";
	#prt( "$actnav, $typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name ($off)\n");
	#push(@navlist2, [$typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name, $off]);
	my $ac = scalar @aptlist2;
    @navlist2 = sort mycmp_ascend_n4 @navlist2 if ($sortbyfreq);
	my $nc = scalar @navlist2;
	prt( "For $ac airports, found $nc NAVAIDS, " );
    if ($usekmrange) {
    	prt( "within [$max_range_km] Km ...\n" );
    } else {
    	prt( "within [$nmaxlatd,$nmaxlond] degrees ...\n" );
    }
	$lcnt = 0;
	for ($ic = 0; $ic < $ac; $ic++) {
		$diff = $aptlist2[$ic][0];
		$icao = $aptlist2[$ic][1];
		$name = $aptlist2[$ic][2];
		$alat = $aptlist2[$ic][3];
		$alon = $aptlist2[$ic][4];
		$icao .= ' ' while (length($icao) < 4);
		$line = $diff;
		$line = ' '.$line while (length($line) < 6);
		$line .= ' '.$icao.' '.$name.' ('.$alat.','.$alon.')';
        prt("\n") if ($ic);
		prt("$line\n");
		$outcount++;
		$dnone = 0;
		for ( $in = 0; $in < $nc; $in++ ) {
			$typ = $navlist2[$in][0];
			$nlat = $navlist2[$in][1];
			$nlon = $navlist2[$in][2];
			$nalt = $navlist2[$in][3];
			$nfrq = $navlist2[$in][4];
			$nrng = $navlist2[$in][5];
			$nfrq2 = $navlist2[$in][6];
			$nid = $navlist2[$in][7];
			$name = $navlist2[$in][8];
			$off = $navlist2[$in][9];
            $dist = $navlist2[$in][10];
            $az = $navlist2[$in][11];
			if ($off == ($ic + 1)) {
				# it is FOR this airport
				is_valid_nav($typ);
    			#     NDB  50.049000, 008.328667,   490,   399,    25,      0.000,  WBD, Wiesbaden NDB (ap=2 nnnKm on 270.1)
                #     Type Latitude   Logitude     Alt.  Freq.  Range  Frequency2    ID  Name
                #     VOR  37.61948300, -122.37389200,    13, 11580,    40,       17.0,  SFO, SAN FRANCISCO VOR-DME (ap=1 nnnKm on 1.1)
				#prt( "$actnav, $typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name ($off)\n");
				$line = $actnav;
				$line .= ' ' while (length($line) < $maxnnlen);
				$line .= ' ';
				$nalt = ' '.$nalt while (length($nalt) < 5);
				$nfrq = ' '.$nfrq while (length($nfrq) < 5);
				$nrng = ' '.$nrng while (length($nrng) < 5);
				$nfrq2 = ' '.$nfrq2 while (length($nfrq2) < 10);
				$nid = ' '.$nid while (length($nid) < 4);
                $nlat = ' '.$nlat while (length($nlat) < 12);
                $nlon = ' '.$nlon while (length($nlon) < 13);
                $adkm = sprintf( "%0.2f", ($dist / 1000.0));    # get kilometers
                $ahdg = sprintf( "%0.1f", $az );    # and azimuth
				$line .= "$nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name (ap=$off ".$adkm."Km on $ahdg)";
				if ($dnone == 0) {
					#prt( "Type  Latitude     Logitude        Alt.  Freq.  Range  Frequency2    ID  Name\n" );
					prt( "$hdr\n" );
					$dnone = 1;
				}
				prt( "$line\n" );
				$outcount++;
				$lcnt++;
				add_2_tiles( get_bucket_info( $nlon, $nlat ) );
			}
		}
		prt( "$hdr\n" ) if ($dnone);
	}
	prt( "Listed $lcnt NAVAIDS ...\n" );
}

sub set_apt_version($$) {
    my ($ra,$cnt) = @_;
    if ($cnt < 5) {
        prt("ERROR: Insufficient lines to be an apt.dat file!\n");
        exit(1);
    }
    my $line = trimall(${$ra}[0]);
    if ($line ne 'I') {
        prt("ERROR: File does NOT begin with an 'I'!\n");
        exit(1);
    }
    $line = trimall(${$ra}[1]);
    if ($line =~ /^(\d+)\s+Version\s+/i) {
        $file_version = $1;
        prt("Dealing with file version [$file_version]\n");
    } else {
        prt("ERROR: File does NOT begin with Version info!\n");
        exit(1);

    }
}

# sort by type
sub mycmp_ascend_n0 {
   return -1 if (${$a}[0] < ${$b}[0]);
   return  1 if (${$a}[0] > ${$b}[0]);
   return 0;
}


# sort by ICAO text
sub mycmp_ascend_t1 {
   return -1 if (${$a}[1] lt ${$b}[1]);
   return  1 if (${$a}[1] gt ${$b}[1]);
   return 0;
}

# sort by distance
sub mycmp_ascend_n1 {
   return -1 if (${$a}[1] < ${$b}[1]);
   return  1 if (${$a}[1] > ${$b}[1]);
   return 0;
}


# put least first
sub mycmp_ascend_n4 {
   if (${$a}[4] < ${$b}[4]) {
      return -1;
   }
   if (${$a}[4] > ${$b}[4]) {
      return 1;
   }
   return 0;
}

sub mycmp_ascend_n5 {
   if (${$a}[5] < ${$b}[5]) {
      return -1;
   }
   if (${$a}[5] > ${$b}[5]) {
      return 1;
   }
   return 0;
}

sub mycmp_ascend_n6 {
   if (${$a}[6] < ${$b}[6]) {
      return -1;
   }
   if (${$a}[6] > ${$b}[6]) {
      return 1;
   }
   return 0;
}

# put least first
sub mycmp_ascend {
   if (${$a}[0] < ${$b}[0]) {
      prt( "-[".${$a}[0]."] < [".${$b}[0]."]\n" ) if $verb3;
      return -1;
   }
   if (${$a}[0] > ${$b}[0]) {
      prt( "+[".${$a}[0]."] < [".${$b}[0]."]\n" ) if $verb3;
      return 1;
   }
   prt( "=[".${$a}[0]."] == [".${$b}[0]."]\n" ) if $verb3;
   return 0;
}

sub mycmp_decend {
   if (${$a}[0] < ${$b}[0]) {
      prt( "+[".${$a}[0]."] < [".${$b}[0]."]\n" ) if $verb3;
      return 1;
   }
   if (${$a}[0] > ${$b}[0]) {
      prt( "-[".${$a}[0]."] < [".${$b}[0]."]\n" ) if $verb3;
      return -1;
   }
   prt( "=[".${$a}[0]."] == [".${$b}[0]."]\n" ) if $verb3;
   return 0;
}

# sort by distance
sub mycmp_ascend_n11 {
   return -1 if (${$a}[11] < ${$b}[11]);
   return  1 if (${$a}[11] > ${$b}[11]);
   return 0;
}

sub fix_airport_name($) {
    my $name = shift;
    my @arr = split(/\s/,$name);
    my $nname = '';
    my $len;
    foreach $name (@arr) {
        $nname .= ' ' if (length($nname));
        $nname .= uc(substr($name,0,1));
        $len = length($name);
        if ($len > 1) {
            $nname .= lc(substr($name,1));
        }
    }
    return $nname;
}

sub in_world_range($$) {
    my ($lat,$lon) = @_;
    if (($lat <= 90)&&
        ($lat >= -90)&&
        ($lon <= 180)&&
        ($lon >= -180)) {
        return 1;
    }
    return 0;
}


sub find_ils_for_apt($) {
    my $find = shift;
    #                0     1     2     3     4     5    6     7   8     9    10
    # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    my $max = scalar @navlist;
    my ($i,$ra,$icao,$cnt,$type);
    $cnt = 0;
    for ($i = 0; $i < $max; $i++) {
        $ra = $navlist[$i];
        $type = ${$ra}[0];
        $icao = ${$ra}[8];
        next if ($type != 4); # 20130307 was 6, which is GS?
        $cnt++ if ($find eq $icao);
    }
    return $cnt;
}

my %navaid_code = (
    2  => 'NDB',    # (Non-Directional Beacon) Includes NDB component of Locator Outer Markers (LOM)
    3  => 'VOR',    # (including VOR-DME and VORTACs) Includes VORs, VOR-DMEs and VORTACs
    4  => 'ILS',    # Localiser component of an ILS (Instrument Landing System)
    5  => 'LOC',    # Localiser component of a localiser-only approach Includes for LDAs and SDFs
    6  => 'GS',     # Glideslope component of an ILS Frequency shown is paired frequency, not the DME channel
    7  => 'OM',     # Outer markers (OM) for an ILS Includes outer maker component of LOMs
    8  => 'MM',     # Middle markers (MM) for an ILS
    9  => 'IM',     # Inner markers (IM) for an ILS
    12 => 'DME',    # including the DME component of an ILS, VORTAC or VOR-DME Frequency display suppressed on X-Plane’s charts
    13 => 'SDME'    # Stand-alone DME, or the DME component of an NDB-DME Frequency will displayed on X-Plane’s charts
);


sub get_ils_info($) {
    my $find = shift;
    my @arr = ();
    #                0     1     2     3     4     5    6     7   8     9    10
    # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    my $max = scalar @navlist;
    my ($i,$ra,$icao,$cnt,$type);
    $cnt = 0;
    for ($i = 0; $i < $max; $i++) {
        $ra = $navlist[$i];
        $type = ${$ra}[0];
        $icao = ${$ra}[8];
        ###next if ($type != 6); # WANT ALL TYPES with this ICAO
        if ($find eq $icao) {
            $cnt++;
            push(@arr,$ra);
            prt(join(",",@{$ra})."\n") if (VERB9());
        }
    }
    return \@arr;
}

my $min_nav_dist = 100;     # 100 nautical miles
my $pole_2_pole = 20014000; # m
my $min_nav_cnt = 10;
#  my $rnavs = get_nav_info($alat,$alon,$icao);
sub get_nav_info($$$) {
    my ($alat,$alon,$find) = @_;
    my @arr = ();
    my @dists = ();
    #                0     1     2     3     4     5    6     7   8     9    10
    # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    my $max = scalar @navlist;
    my ($i,$ra,$icao,$cnt,$type,$lat,$lon);
    my ($az1,$az2,$dist,$ret,$rd,$i2);
    my $mdist = $min_nav_dist * $NM_TO_METER;
    $cnt = 0;
    for ($i = 0; $i < $max; $i++) {
        $ra = $navlist[$i];
        $type = ${$ra}[0];
        $icao = ${$ra}[8];
        # WANT ALL TYPES without this ICAO, whihc was returned in get_ils_info
        # next if ($find eq $icao);
        next if (length($icao)); # ignore other airport ILS stuff
        $lat = ${$ra}[1];
        $lon = ${$ra}[2];
        $ret = fg_geo_inverse_wgs_84($alat, $alon, $lat, $lon, \$az1, \$az2, \$dist);
        if ($ret > 0) {
            $dist = $pole_2_pole; # make it BIG
            $az1 = 0;
        }
        push(@dists,[$i,$dist,$az1]);
        next if ($dist > $mdist);
        my @a = @{$ra};
        push(@a,(int($dist * $METER_TO_NM * 10) / 10));
        push(@a,(int($az1 * 10) / 10));
        push(@arr,\@a);
        $cnt++;
        prt("icao:$cnt: $find: ".join(",",@a)."\n") if (VERB9());
    }
    my @as = ();
    if ($cnt < $min_nav_cnt) {
        @dists = sort mycmp_ascend_n1 @dists;
        $cnt = 0;   # restart count
        for ($i = 0; $i < $max; $i++) {
            $rd = $dists[$i];
            $i2   = ${$rd}[0];
            $dist = ${$rd}[1];
            $az1 =  ${$rd}[2];
            $ra = $navlist[$i2];
            my @a = @{$ra};
            push(@a,(int($dist * $METER_TO_NM * 10) / 10));
            push(@a,(int($az1 * 10) / 10));
            push(@as,\@a);
            $cnt++;
            prt("icao:$cnt: $find: ".join(",",@a)."\n") if (VERB9());
            last if ($cnt >= $min_nav_cnt);
        }
    } else {
        @as = sort mycmp_ascend_n11 @arr;
    }
    return \@as;
}


#Runway line
##   0   1     2 3 4    5 6 7 8   9            10            11    12   13 14 15 16 17  18           19           20     21   22 23 24 25
#EG: 100 29.87 3 0 0.00 0 0 0 16  -24.20505300 151.89156100  0.00  0.00 1  0  0  0  34  -24.19732300 151.88585300 0.00   0.00 1  0  0  0
#OR: 100 29.87 1 0 0.15 0 2 1 13L 47.53801700  -122.30746100 73.15 0.00 2  0  0  1  31R 47.52919200 -122.30000000 110.95 0.00 2  0  0  1
#Land Runway
#0  - 100 - Row code for a land runway (the most common) 100
#1  - 29.87 - Width of runway in metres Two decimal places recommended. Must be >= 1.00
#2  - 3 - Code defining the surface type (concrete, asphalt, etc) Integer value for a Surface Type Code
#3  - 0 - Code defining a runway shoulder surface type 0=no shoulder, 1=asphalt shoulder, 2=concrete shoulder
#4  - 0.15 - Runway smoothness (not used by X-Plane yet) 0.00 (smooth) to 1.00 (very rough). Default is 0.25
#5  - 0 - Runway centre-line lights 0=no centerline lights, 1=centre line lights
#6  - 0 - Runway edge lighting (also implies threshold lights) 0=no edge lights, 2=medium intensity edge lights
#7  - 1 - Auto-generate distance-remaining signs (turn off if created manually) 0=no auto signs, 1=auto-generate signs
#The following fields are repeated for each end of the runway
#8  - 13L - Runway number (eg. 31R, 02). Leading zeros are required. Two to three characters. Valid suffixes: L, R or C (or blank)
#9  - 47.53801700 - Latitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
#10 - -122.30746100 - Longitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
#11 - 73.15 - Length of displaced threshold in metres (this is included in implied runway length) Two decimal places (metres). Default is 0.00
#12 - 0.00 - Length of overrun/blast-pad in metres (not included in implied runway length) Two decimal places (metres). Default is 0.00
#13 - 2 - Code for runway markings (Visual, non-precision, precision) Integer value for Runway Marking Code
#14 - 0 - Code for approach lighting for this runway end Integer value for Approach Lighting Code
#15 - 0 - Flag for runway touchdown zone (TDZ) lighting 0=no TDZ lighting, 1=TDZ lighting
#16 - 1 - Code for Runway End Identifier Lights (REIL) 0=no REIL, 1=omni-directional REIL, 2=unidirectional REIL
#17 - 31R
#18 - 47.52919200
#19 - -122.30000000
#20 - 110.95 
#21 - 0.00 
#22 - 2
#23 - 0
#24 - 0
#25 - 1

#Surface Type Code Surface type of runways or taxiways
#1 Asphalt
#2 Concrete
#3 Turf or grass
#4 Dirt (brown)
#5 Gravel (grey)
#12 Dry lakebed (eg. At KEDW) Example: KEDW (Edwards AFB)
#13 Water runways Nothing displayed
#14 Snow or ice Poor friction. Runway markings cannot be added.
#15 Transparent Hard surface, but no texture/markings (use in custom scenery)
# offset 2 in runway array
my %runway_surface = (
    1  => 'Asphalt',
    2  => 'Concrete',
    3  => 'Turf/grass',
    4  => 'Dirt',
    5  => 'Gravel',
    6  => 'H-Asphalt', # helepad (big 'H' in the middle).
    7  => 'H_Concrete', # helepad (big 'H' in the middle).
    8  => 'H_Turf', # helepad (big 'H' in the middle).
    9  => 'H_Dirt', # helepad (big 'H' in the middle). 
    10 => 'T_Asphalt', # taxiway - with yellow hold line across long axis (not available from WorldMaker).
    11 => 'T_Concrete', # taxiway - with yellow hold line across long axis (not available from WorldMaker).
    12 => 'Dry_Lakebed', # (eg. at KEDW Edwards AFB).
    13 => 'Water', # runways (marked with bobbing buoys) for seaplane/floatplane bases (available in X-Plane 7.0 and later). 
    14 => 'Snow',
    15 => 'Transparent'
);

my %frequency_code = (
    50 => "ATIS",   # 50 ATC – Recorded AWOS, ASOS or ATIS
    51 => "CTAF",   # 51 ATC – Unicom Unicom (US), CTAF (US), Radio (UK)
    52 => "CLD",    # 52 ATC – CLD Clearance Delivery
    53 => "GND",    # 53 ATC – GND Ground
    54 => "TWR",    # 54 ATC – TWR Tower
    55 => "APP",    # 55 ATC – APP Approach
    56 => "DEP"     # 56 ATC - DEP Departure
    );

sub output_apts_to_json($) {
    my $rapts = shift; # = \@sorted
    my $max = scalar @{$rapts};
    my ($i,$ra,$icao,$name,$alat,$alon,$rwycnt,$rwa,$ils,$line,$rfqa,$o_file,$base);
    my ($rcnt,$j,$rrwy,$i2,$j2);
    my ($wid,$surf,$code,$smth,$ctln,$elit);
    my ($rwy1,$lat1,$lon1,$rwy2,$lat2,$lon2);
    my ($rlen,$az1,$az2,$dist,$racnt,$type,$rha);
    my ($freq,$serv,$feet,$slope,$tmp,$rng,$rwwa);
    prt("Loaded $max airports...\n");
    my $bgntm = [gettimeofday];
    my ($elap,$lnspsec,$remain);
    # $line = "icao,name,lat,lon,runways,ils\n";
    $base = '{"success":true,"source":"'.$pgmname.'","last_updated":"'.
        lu_get_YYYYMMDD_hhmmss_UTC(time()).' UTC"';
    #                 0          1      2      3      4      5  6    7        8    9    10    11
    # push(@aptlist, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils, \@h]);
    for ($i = 0; $i < $max; $i++) {
        $i2 = $i + 1;
        $ra = ${$rapts}[$i];
        ###$type = ${$ra}[0]; # now all type '1' land airports
        $icao = ${$ra}[1];
        $name = fix_airport_name(${$ra}[2]);
        $alat = ${$ra}[3];
        $alon = ${$ra}[4];
        #$bucket = ${$ra}[5];
        $rwwa = ${$ra}[6];
        $rwycnt = ${$ra}[7];
        $rwa  = ${$ra}[8];
        $rfqa = ${$ra}[9];
        $ils  = ${$ra}[10];
        $rha  = ${$ra}[11];
        # generate the json FILE
        $o_file = $out_path.$PATH_SEP."$icao.json";
        if ($skip_done_files && (-f $o_file)) {
            prt("ICAO: $icao json exists. skipping... $i2 of $max\n") if (VERB1());
            next;
        }
        prt("ICAO: $icao: $alat,$alon - doing json... $i2 of $max\n") if (VERB5());
        # my $b = Bucket2->new();
        my $b = Bucket->new();
        $b->set_bucket($alon,$alat);

        # start JSON text with base
        $line = $base;
        $line .= "\n" if ($add_newline);
        $line .= ',"icao":"'.$icao.'"';
        $line .= ',"name":"'.$name.'"';
        $line .= ',"lat":'.$alat;
        $line .= ',"lon":'.$alon;
        $line .= ',"rwys":'.$rwycnt;
        $line .= ',"ils":'.$ils;
        # TODO - CHECK bucket code - but looks ok
        $line .= ',"index":'.$b->gen_index();
        $line .= ',"path":"'.$b->gen_base_path().'"';
        $line .= "\n" if ($add_newline);
        $rcnt = scalar @{$rwa};
        if ($rcnt) {
            $line .= ',"runways":[';
            $line .= "\n" if ($add_newline);
            prt("RWYS: $icao adding $rcnt...\n") if (VERB5());
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                # 0     1       2   3 4    5 6 7 8    9           10              11       12   13 14 15 16 17   18          19             20        21   22 23 24 25
                # 100   60.96   1   1 0.25 0 2 1 07   49.01911500 -122.37996700    0.00    0.00 3  5  0  0  25   49.02104800 -122.34005800  131.06    0.00 3  11 0  1
                # 100   60.96   1   1 0.25 0 2 1 01   49.01877000 -122.37871800   75.90    0.00 3  0  0  1  19   49.03176400 -122.36917600    0.00    0.00 3  10 0  0
                # 100   28.96   3   0 0.00 0 0 0 01L  49.02608640 -122.37408779    0.00    0.00 1  0  0  0  19R  49.02976278 -122.37147182    0.00    0.00 1   0 0  0
                $rrwy = ${$rwa}[$j];
                $racnt = scalar @{$rrwy};
                if ($racnt < 20) {
                    prtw("WARNING: icao=$icao: Array count $racnt! SKIPPING\n");
                    prt(join(",",@{$rrwy})."\n");
                    next;
                }
                # hmmmm, seems this is NOT always with BOTH ends!!! - see BIKF, BKPR, ....
                # AHA, seems when there are HELIPORTS also
                $type = ${$rrwy}[1]; #0  - 100 for land runways
                $wid  = ${$rrwy}[1]; #1  - 29.87 - Width of runway in metres Two decimal places recommended. Must be >= 1.00
                $surf = ${$rrwy}[2]; #2  - 3 - Code defining the surface type (concrete, asphalt, etc) Integer value for a Surface Type Code
                $code = ${$rrwy}[3]; #3  - 0 - Code defining a runway shoulder surface type 0=no shoulder, 1=asphalt shoulder, 2=concrete shoulder
                $smth = ${$rrwy}[4]; #4  - 0.15 - Runway smoothness (not used by X-Plane yet) 0.00 (smooth) to 1.00 (very rough). Default is 0.25
                $ctln = ${$rrwy}[5]; #5  - 0 - Runway centre-line lights 0=no centerline lights, 1=centre line lights
                $elit = ${$rrwy}[6]; #6  - 0 - Runway edge lighting (also implies threshold lights) 0=no edge lights, 2=medium intensity edge lights
                # #7  - 1 - Auto-generate distance-remaining signs (turn off if created manually) 0=no auto signs, 1=auto-generate signs
                # #The following fields are repeated for each end of the runway
                $rwy1 = ${$rrwy}[8]; #8  - 13L - Runway number (eg. 31R, 02). Leading zeros are required. Two to three characters. Valid suffixes: L, R or C (or blank)
                $lat1 = sprintf("%.8f",${$rrwy}[9]); #9  - 47.53801700 - Latitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
                $lon1 = sprintf("%.8f",${$rrwy}[10]); #10 - -122.30746100 - Longitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
                # #11 - 73.15 - Length of displaced threshold in metres (this is included in implied runway length) Two decimal places (metres). Default is 0.00
                # #12 - 0.00 - Length of overrun/blast-pad in metres (not included in implied runway length) Two decimal places (metres). Default is 0.00
                # #13 - 2 - Code for runway markings (Visual, non-precision, precision) Integer value for Runway Marking Code
                # #14 - 0 - Code for approach lighting for this runway end Integer value for Approach Lighting Code
                # #15 - 0 - Flag for runway touchdown zone (TDZ) lighting 0=no TDZ lighting, 1=TDZ lighting
                # #16 - 1 - Code for Runway End Identifier Lights (REIL) 0=no REIL, 1=omni-directional REIL, 2=unidirectional REIL
                $rwy2 = ${$rrwy}[17]; #17 - 31R
                $lat2 = sprintf("%.8f",${$rrwy}[18]); #18 - 47.52919200
                $lon2 = sprintf("%.8f",${$rrwy}[19]); #19 - -122.30000000
                # #20 - 110.95 
                # #21 - 0.00 
                # #22 - 2
                # #23 - 0
                # #24 - 0
                # #25 - 1
                $rlen = fg_geo_inverse_wgs_84($lat1, $lon1, $lat2, $lon2, \$az1, \$az2, \$dist);
                $line .= '{';
                $line .= '"len_m":'.int($dist);
                $line .= ',"wid_m":'.$wid;
                $line .= ',"hdg":'.int($az1);
                $line .= ',"surf":"';
                if (defined $runway_surface{$surf}) {
                    $line .= $runway_surface{$surf};
                } else {
                    $line .= $surf;
                }
                $line .= '"';
                $line .= ',"rwy1":"'.$rwy1.'"';
                $line .= ',"lat1":'.$lat1;
                $line .= ',"lon1":'.$lon1;
                $line .= ',"rwy2":"'.$rwy2.'"';
                $line .= ',"lat2":'.$lat2;
                $line .= ',"lon2":'.$lon2;
                $line .= "}";
                if ($j2 < $rcnt) {
                    $rrwy = ${$rwa}[$j2];
                    $racnt = scalar @{$rrwy};
                    $line .= "," if ($racnt >= 20);
                }
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }

        # add helipads, if any
        $rcnt = scalar @{$rha};
        if ($rcnt) {
            prt("HELIPADS: $icao adding $rcnt...\n") if (VERB5());
            # 102 H19  63.98375180 -022.58960171 268.42   35.05   35.05   1 0   0 0.00 0
            # 102 H20  63.97607407 -022.64376126   0.00   49.99   49.99   2 0   0 0.00 0
            $line .= ',"helipads":[';
            $line .= "\n" if ($add_newline);
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                $rrwy = ${$rha}[$j];
                $racnt = scalar @{$rrwy};
                $type = ${$rrwy}[0];  #0 102           Row code for a helipad 101
                $rwy1 = ${$rrwy}[1];  #1 H1            Designator for a helipad. Must be unique at an airport. Usually “H” suffixed by an integer (eg. “H1”, “H3”)
                $lat1 = sprintf("%.8f",${$rrwy}[2]);  #2 47.53918248   Latitude of helipad centre in decimal degrees Eight decimal places supported
                $lon1 = sprintf("%.8f",${$rrwy}[3]);  #3 -122.30722302 Longitude of helipad centre in decimal degrees Eight decimal places supported
                $az1  = ${$rrwy}[3];  #4 2.00          Orientation (true heading) of helipad in degrees Two decimal places recommended
                $wid  = ${$rrwy}[5];  #5 10.06         Helipad length in metres Two decimal places recommended (metres), must be >=1.00
                $dist = ${$rrwy}[6];  #6 10.06         Helipad width in metres Two decimal places recommended (metres), must be >= 1.00
                $surf = ${$rrwy}[7];  #7 1             Helipad surface code Integer value for a Surface Type Code (see below)
                #0             Helipad markings 0 (other values not yet supported)
                #0             Code defining a helipad shoulder surface type 0=no shoulder, 1=asphalt shoulder, 2=concrete shoulder
                #0.25          Helipad smoothness (not used by X-Plane yet) 0.00 (smooth) to 1.00 (very rough). Default is 0.25
                #0             Helipad edge lighting 0=no edge lights, 1=yellow edge lights
                $line .= '{"rwy1":"'.$rwy1.'"';
                $line .= ',"len_m":'.int($dist);
                $line .= ',"wid_m":'.$wid;
                $line .= ',"hdg":'.int($az1);
                $line .= ',"surf":"';
                if (defined $runway_surface{$surf}) {
                    $line .= $runway_surface{$surf};
                } else {
                    $line .= $surf;
                }
                $line .= '"';
                $line .= ',"lat1":'.$lat1;
                $line .= ',"lon1":'.$lon1;
                $line .= "}";
                $line .= "," if ($j2 < $rcnt);
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }

        # add waterways, if any
        $rcnt = scalar @{$rwwa};
        if ($rcnt) {
            # 0   1      2 3  4           5             6  7           8
            # 101 243.84 0 16 29.27763293 -089.35826258 34 29.26458929 -089.35340410
            # 101 22.86  0 07 29.12988952 -089.39561501 25 29.13389936 -089.38060001
            prt("WATERWAYS: $icao adding $rcnt...\n") if (VERB5());
            $line .= ',"waterways":[';
            $line .= "\n" if ($add_newline);
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                $rrwy = ${$rwwa}[$j];
                $racnt = scalar @{$rrwy};
                $type = ${$rrwy}[0]; #0 101 Row code for a water runway 101
                $wid  = ${$rrwy}[1]; #1 49 Width of runway in metres Two decimal places recommended. Must be >= 1.00
                $surf = ${$rrwy}[2]; #2 1 Flag for perimeter buoys 0=no buoys, 1=render buoys
                # The following fields are repeated for each end of the water runway
                $rwy1 = ${$rrwy}[3]; #3 08 Runway number. Not rendered in X-Plane (it’s on water!) Valid suffixes are “L”, “R” or “C” (or blank)
                $lat1 = sprintf("%.8f",${$rrwy}[4]); #4 35.04420911 Latitude of runway end (on runway centerline) in decimal degrees Eight decimal places supported
                $lon1 = sprintf("%.8f",${$rrwy}[5]); #5 -106.59855711 Longitude of runway end (on runway centerline) in decimal degrees Eight decimal places supported            
                $rwy2 = ${$rrwy}[6]; #6 08 Runway number. Not rendered in X-Plane (it’s on water!) Valid suffixes are “L”, “R” or “C” (or blank)
                $lat2 = sprintf("%.8f",${$rrwy}[7]); #7 35.04420911 Latitude of runway end (on runway centerline) in decimal degrees Eight decimal places supported
                $lon2 = sprintf("%.8f",${$rrwy}[8]); #5 -106.59855711 Longitude of runway end (on runway centerline) in decimal degrees Eight decimal places supported            
                $rlen = fg_geo_inverse_wgs_84($lat1, $lon1, $lat2, $lon2, \$az1, \$az2, \$dist);

                # add json
                $line .= '{';
                $line .= '"len_m":'.int($dist);
                $line .= ',"wid_m":'.int($wid);
                $line .= ',"hdg_t":'.int($az1);
                $line .= ',"buoys":';
                $line .= ($surf ? 'true' : 'false');
                $line .= ',"rwy1":"'.$rwy1.'"';
                $line .= ',"lat1":'.$lat1;
                $line .= ',"lon1":'.$lon1;
                $line .= ',"rwy2":"'.$rwy2.'"';
                $line .= ',"lat2":'.$lat2;
                $line .= ',"lon2":'.$lon2;
                $line .= "}";
                $line .= ',' if ($j2 < $rcnt);
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }

        # add frequencies
        $rcnt = scalar @{$rfqa};
        if ($rcnt) {
            prt("RADIOS: $icao adding $rcnt...\n") if (VERB5());
            $line .= ',"radios":[';
            $line .= "\n" if ($add_newline);
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                $rrwy = ${$rfqa}[$j];
                $racnt = scalar @{$rrwy};
                if ($racnt < 3) {
                    prtw("WARNING: freq array ref cnt < 3! got $racnt. \n".join(",",@{$rrwy})."\n");
                    next;
                }
                #0 51 Row code for an ATC COM frequency 50 thru 56 (see above)
                #1 12775 Frequency in MHz x 100 (eg. use “12322” for 123.225MHz) Five digit integer, rounded DOWN where necessary
                #3 ATIS Descriptive name (displayed on X-Plane charts) Short text string (recommend less than 10 characters)
                $type = ${$rrwy}[0];
                $freq = (${$rrwy}[1] / 100);
                $rwy1 = join(' ', splice(@{$rrwy},2));
                $serv = $type;
                if (defined $frequency_code{$type}) {
                    $serv = $frequency_code{$type};
                }
                $line .= "{";
                $line .= '"type":"'.$serv.'"';
                $line .= ',"freq":'.$freq;
                if (length($rwy1)) {
                    $line .= ',"desc":"'.$rwy1.'"';
                }
                $line .= "}";
                if ($j2 < $rcnt) {
                    $rrwy = ${$rfqa}[$j2];
                    $racnt = scalar @{$rrwy};
                    $line .= "," if ($racnt >= 3);
                }
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }

        ###################################################
        # add ILS
        ###################################################
        my $rilss = get_ils_info($icao);
        $rcnt = scalar @{$rilss};
        if ($rcnt) {
            prt("ILS: $icao adding $rcnt...\n") if (VERB5());
            $line .= ',"ils":[';
            $line .= "\n" if ($add_newline);
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                $rrwy = ${$rilss}[$j];
                $racnt = scalar @{$rrwy};
                #                0     1     2     3     4     5    6     7   8     9    10
                # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
                $type = ${$rrwy}[0];
                $lat1 = sprintf("%.8f",${$rrwy}[1]);
                $lon1 = sprintf("%.8f",${$rrwy}[2]);
                $feet = ${$rrwy}[3];
                $freq  = (${$rrwy}[4] / 100);
                $rng = ${$rrwy}[5];
                ###$az1  = int(${$rrwy}[6]);
                $tmp  = ${$rrwy}[6];
                if ($type == 6) {
                    $az1 = 0;
                    ###$freq = (substr($tmp,3) / 100);
                    $slope = (substr($tmp,0,3) / 100);
                } else {
                    $az1 = sprintf("%.2f",$tmp);
                    $slope = 0;
                }
                $rwy1 = ${$rrwy}[7];    # actually ID
                # $icao = ${$rrwy}[8];  # was fetched using this
                $rwy2 = ${$rrwy}[9];    # associated runway, if ANY
                $name = ${$rrwy}[10];
                $serv = $type;
                if (defined $navaid_code{$type}) {
                    $serv = $navaid_code{$type};
                }

                # build json
                $line .= "{";
                $line .= '"type":"'.$serv.'"';
                $line .= ',"freq":'.$freq;
                $line .= ',"lat":'.$lat1;
                $line .= ',"lon":'.$lon1;
                $line .= ',"rng_nm":'.$rng;
                $line .= ',"alt_fmsl":'.$feet;
                $line .= ',"hdg":'.$az1 if ($type == 4);
                $line .= ',"id":"'.$rwy1.'"' if (length($rwy1));
                $line .= ',"rwy":"'.$rwy2.'"' if (length($rwy2));
                $line .= ',"desc":"'.$name.'"' if (length($name));
                $line .= ',"gs":'.$slope if ($type == 6);
                $line .= "}";
                $line .= "," if ($j2 < $rcnt);
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }
        #####################################################

        # add navaids nearyby
        my $rnavs = get_nav_info($alat,$alon,$icao);
        $rcnt = scalar @{$rnavs};
        if ($rcnt) {
            prt("NAV: $icao adding $rcnt...\n") if (VERB5());
            $line .= ',"navaids":[';
            $line .= "\n" if ($add_newline);
            for ($j = 0; $j < $rcnt; $j++) {
                $j2 = $j + 1;
                $rrwy = ${$rnavs}[$j];
                $racnt = scalar @{$rrwy};
                #                0     1     2     3     4     5    6     7   8     9    10
                # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
                $type = ${$rrwy}[0];
                $lat1 = sprintf("%.8f",${$rrwy}[1]);
                $lon1 = sprintf("%.8f",${$rrwy}[2]);
                $feet = ${$rrwy}[3];
                if ($type == 2) {
                    $freq  = ${$rrwy}[4];
                } else {
                    $freq  = (${$rrwy}[4] / 100);
                }
                $rng = ${$rrwy}[5];
                ###$az1  = int(${$rrwy}[6]);
                $tmp  = ${$rrwy}[6];
                if ($type == 6) {
                #    $az1 = 0;
                #    ###$freq = (substr($tmp,3) / 100);
                    $slope = (substr($tmp,0,3) / 100);
                } else {
                #    $az1 = sprintf("%.2f",$tmp);
                    $slope = 0;
                }
                $rwy1 = ${$rrwy}[7];    # actually ID
                # $icao = ${$rrwy}[8];  # was fetched using this
                $rwy2 = ${$rrwy}[9];    # associated runway, if ANY
                $name = ${$rrwy}[10];
                $dist = ${$rrwy}[11];
                $az1  = ${$rrwy}[12];
                $serv = $type;
                if (defined $navaid_code{$type}) {
                    $serv = $navaid_code{$type};
                }

                # build json
                $line .= "{";
                $line .= '"type":"'.$serv.'"';
                $line .= ',"hdg_t":'.$az1;
                $line .= ',"dist_nm":'.$dist;
                $line .= ',"freq":'.$freq;
                $line .= ',"lat":'.$lat1;
                $line .= ',"lon":'.$lon1;
                $line .= ',"rng_nm":'.$rng;
                $line .= ',"alt_fmsl":'.$feet;
                ###$line .= ',"hdg":'.$az1 if ($type == 4);
                $line .= ',"id":"'.$rwy1.'"' if (length($rwy1));
                $line .= ',"rwy":"'.$rwy2.'"' if (length($rwy2));
                $line .= ',"desc":"'.$name.'"' if (length($name));
                $line .= ',"gs":'.$slope if ($type == 6);
                $line .= "}";
                $line .= "," if ($j2 < $rcnt);
                $line .= "\n" if ($add_newline);
            }
            $line .= "]";
            $line .= "\n" if ($add_newline);
        }

        $line .= "}\n";
        write2file($line,$o_file);
        prt("ICAO: $icao json written to [$o_file]. $i2 of $max\n") if (VERB1());
        if ($i && (($i % 250) == 0)) {
            $elap = tv_interval ( $bgntm, [gettimeofday]);
            $lnspsec = ($i2 / $elap);
            $remain =  (($max / $lnspsec) - $elap);
            $lnspsec = (int($lnspsec * 10) / 10);
            prt("File $i2 of $max (est $lnspsec files/sec, elap=".secs_HHMMSS(int($elap)).", rem=".secs_HHMMSS(int($remain)).").\n");
        }
    }   # for ($i = 0; $i < $max; $i++)

    ##### all done #####
    $elap = tv_interval ( $bgntm, [gettimeofday]);
    $lnspsec = ($i / $elap);
    $remain =  (($max / $lnspsec) - $elap);
    $lnspsec = (int($lnspsec * 10) / 10);
    prt("File $i of $max (est $lnspsec files/sec, elap=".secs_HHMMSS(int($elap)).", rem=".secs_HHMMSS(int($remain)).").\n");
}

################################################################
# 1000 Version - data cycle 2012.08, build 20121293
sub load_apt_data {
    prt("Loading $aptdat file ...\n");
    mydie("ERROR: Can NOT locate $aptdat ...$!...\n") if ( !( -f $aptdat) );
    ###open IF, "<$aptdat" or mydie("OOPS, failed to open [$aptdat] ... check name and location ...\n");
    open IF, "<$aptdat" or mydie( "ERROR: CAN NOT OPEN $aptdat...$!...\n" );
    ##prt( "Processing $cnt lines ... airports, runways, and taxiways ...\n" );
    ##set_apt_version( \@lines, $cnt );
    my ($rlat1,$rlat2,$rlon1,$rlon2,$type,$len,$lasttype,@arr,@arr2,$ils);
    my ($apline,$ra,$helicnt,$wwcnt,$trcnt);
    my (@sorted, $o_file,$rwwa);
    my ($i,$rwa);
    my @runways = ();
    my @heliways = ();
    my @closedapts = ();
    my @helipads = ();
    my @seaapts = ();
    my @majapts = ();
    my @freqs = ();
    my @waterways = ();
    $lasttype = 0;
    my $estmax = 2133071;
    my $bgntm = [gettimeofday];
    my ($elap,$lnspsec,$remain);
    $helicnt = 0;
    $rwycnt = 0;
    $wwcnt = 0;
    while ($line = <IF>) {
        chomp $line;
        $line = trimall($line);
        $len = length($line);
        if (($. % 25000) == 0) {
            $elap = tv_interval ( $bgntm, [gettimeofday]);
            $lnspsec = $. / $elap;
            $remain = ($estmax / $lnspsec) - $elap;
            prt("Line $. of $estmax (est ".int($lnspsec)." lns/sec, elap=".secs_HHMMSS(int($elap)).", rem=".secs_HHMMSS(int($remain)).").\n");
        }
        next if ($len == 0);
        if ($. < 3) {
            if ($. == 2) {
                $o_file = $out_path.$PATH_SEP."VERSION.apt.txt";
                write2file($line,$o_file);
                prt(substr($line,0,50)."..., written to [$o_file]\n");
            }
            next;
        }
        ###prt("$.: $line\n");
        @arr = split(/\s+/,$line);
        $type = $arr[0];
        if ($type == 99) {
            prt( "$.: Reached END OF FILE ... \n" ); # if ($dbg1);
            last;
        }
        ###pgm_exit(1,"END") if ($. > 15);
        ### if (($line =~ /^$aln\s+/)||($line =~ /^$sealn\s+/)||($line =~ /^$heliln\s+/)) {
        #if ($line =~ /^$aln\s+/) {	# start with '1'
        if (($type == 1)||($type == 16)||($type == 17)) {
            # start of a NEW airport line
            if (length($apt)) {
                # deal with previous
                $trcnt = $rwycnt;
                $trcnt += $helicnt;
                $trcnt += $wwcnt;
                if ($trcnt > 0) {
                    $alat = $glat / $trcnt;
                    $alon = $glon / $trcnt;
                    if (!in_world_range($alat,$alon)) {
                        prtw("WARNING: $apline: OOW [$apt] $alat,$alon $rwycnt\n");
                        next;
                    }
                } else {
                    $alat = 0;
                    $alon = 0;
                    prtw("WARNING: $.: No RUNWAYS [$apt]\n");
                    next;
                }
                @arr2 = split(/\s/,$apt);
                $icao = $arr2[4];
                $name = join(' ', splice(@arr2,5));
                prt( "[$name] $icao $alat $alon rwys=$rwycnt\n" ) if ($dbg11);
                ##prt("[$apt] (with $rwycnt runways at [$alat, $alon]) ...\n");
                ##prt("[$icao] [$name] ...\n");
                my @a = @runways;
                my @f = @freqs;
                my @h = @heliways;
                my @w = @waterways;
                if ($name =~ /\[X\]/) {
                    $ra = \@closedapts;
                } elsif (($name =~ /\[H\]/)||($lasttype == 17)) {
                    $ra = \@helipads;
                } else {
                    if ($lasttype == 1) {
                        $ra = \@aptlist;
                        $totaptcnt++;	# count another AIRPORT
                    } elsif ($lasttype == 16) {
                        $ra = \@seaapts;
                    } else {
                        prtw("$.: ERROR: Unknown last type $lasttype. [$apt]\n");
                        pgm_exit(1,"");
                    }
                    $ils = find_ils_for_apt($icao);
                    if ($ils > 0) {
                        push(@majapts, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils, \@h]);
                    }
                }
                push(@{$ra}, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils, \@h]);
            } elsif (length($apt)) {
                prtw("WARNING: $.: Skipping line [$line]\n");
                pgm_exit(1,"");
            }
            $apline = $.;
            $apt = $line;   # set the NEW AIRPORT line
            $rwycnt  = 0;   # restart RUNWAY counter
            $helicnt = 0;   # restart helipad counter
            $wwcnt   = 0;   # restart waterway counter
            $glat    = 0;   # clear lat accumulator
            $glon    = 0;   # clear lon accumulator
            @runways = ();
            @freqs = ();
            @heliways = ();
            @waterways = ();
            $lasttype = $type;
            prt("$apt\n") if ($dbg10);
        #} elsif ($line =~ /^$rln\s+/) {
        } elsif ($type == 100) {	# land runways
            # 0     1       2   3 4    5 6 7 8    9           10              11       12   13 14 15 16 17   18          19             20        21   22 23 24 25
            # 100   60.96   1   1 0.25 0 2 1 07   49.01911500 -122.37996700    0.00    0.00 3  5  0  0  25   49.02104800 -122.34005800  131.06    0.00 3  11 0  1
            # 100   60.96   1   1 0.25 0 2 1 01   49.01877000 -122.37871800   75.90    0.00 3  0  0  1  19   49.03176400 -122.36917600    0.00    0.00 3  10 0  0
            # 100   28.96   3   0 0.00 0 0 0 01L  49.02608640 -122.37408779    0.00    0.00 1  0  0  0  19R  49.02976278 -122.37147182    0.00    0.00 1   0 0  0
            $rlat1 = $arr[9];  # [$of_lat1];
            $rlon1 = $arr[10]; # [$of_lon1];
            $rlat2 = $arr[18]; # [$of_lat2];
            $rlon2 = $arr[19]; # [$of_lon2];
            $rlat = sprintf("%.8f",(($rlat1 + $rlat2) / 2));
            $rlon = sprintf("%.8f",(($rlon1 + $rlon2) / 2));
            if (!in_world_range($rlat,$rlon)) {
                prt( "$.: $line [$rlat, $rlon]\n" );
                next;
            }
            $glat += $rlat;
            $glon += $rlon;
            $rwycnt++;
            my @a2 = @arr;
            push(@runways, \@a2);
        } elsif ($type == 101) {	# Water runways
            # 0   1      2 3  4           5             6  7           8
            # 101 243.84 0 16 29.27763293 -089.35826258 34 29.26458929 -089.35340410
            # 101 22.86  0 07 29.12988952 -089.39561501 25 29.13389936 -089.38060001
            # prt("$.: $line\n");
            $rlat1 = $arr[4];
            $rlon1 = $arr[5];
            $rlat2 = $arr[7];
            $rlon2 = $arr[8];
            $rlat = sprintf("%.8f",(($rlat1 + $rlat2) / 2));
            $rlon = sprintf("%.8f",(($rlon1 + $rlon2) / 2));
            if (!in_world_range($rlat,$rlon)) {
                prtw( "WANRING: $.: $line [$rlat, $rlon] NOT IN WORLD\n" );
                next;
            }
            $glat += $rlat;
            $glon += $rlon;
            my @a2 = @arr;
            push(@waterways, \@a2);
            $wwcnt++;
        } elsif ($type == 102) {	# Heliport
            # my $heli =   '102'; # Helipad
            # 0   1  2           3            4      5     6     7 8 9 10   11
            # 102 H2 52.48160046 013.39580674 355.00 18.90 18.90 2 0 0 0.00 0
            # 102 H3 52.48071507 013.39937648 2.64   13.11 13.11 1 0 0 0.00 0
            # prt("$.: $line\n");
            $rlat = sprintf("%.8f",$arr[2]);
            $rlon = sprintf("%.8f",$arr[3]);
            if (!in_world_range($rlat,$rlon)) {
                prtw( "WARNING: $.: $line [$rlat, $rlon] NOT IN WORLD\n" );
                next;
            }
            $glat += $rlat;
            $glon += $rlon;
            my @a2 = @arr;
            push(@heliways, \@a2);
            $helicnt++;
        } elsif ($type == 10) { # old 810 runway/taxiway code!!!
            # 0  1           2             3   4      5   6   7   8  9      10 11 12 13   14
            # 10 68.72074130 -052.79344940 xxx 168.00 160 0.0 0.0 60 161161 1  0  0  0.25 0
            $rlat = $arr[1];
            $rlon = $arr[2];
            $name = $arr[3];
            if ($name ne 'xxx') {
                prtw("WARNING: $.: [$line] NOT A TAXIWAY!\n");
            }
        } elsif ($type == 110) { # 110  Pavement (taxiway or ramp) header Must form a closed loop
        } elsif ($type == 120) { # 120  Linear feature (painted line or light string) header Can form closed loop or simple string
        } elsif ($type == 130) { # 130  Airport boundary header Must form a closed loop
        } elsif ($type == 111) { # 111  Node All nodes can also include a “style” (line or lights)
        } elsif ($type == 112) { # 112  Node with Bezier control point Bezier control points define smooth curves
        } elsif ($type == 113) { # 113  Node with implicit close of loop Implied join to first node in chain
        } elsif ($type == 114) { # 114  Node with Bezier control point, with implicit close of loop Implied join to first node in chain
        } elsif ($type == 115) { # 115  Node terminating a string (no close loop) No “styles” used
        } elsif ($type == 116) { # 116  Node with Bezier control point, terminating a string (no close loop) No “styles” used
        } elsif ($type == 14) { # 14   Airport viewpoint One or none for each airport
        } elsif ($type == 15) { # 15   Aeroplane startup location *** Convert these to new row code 1300 ***
        } elsif ($type == 18) { # 18   Airport light beacon One or none for each airport
        } elsif ($type == 19) { # 19   Windsock Zero, one or many for each airport
        } elsif ($type == 20) { # 20   Taxiway sign (inc. runway distance-remaining signs) Zero, one or many for each airport
        } elsif ($type == 21) { # 21   Lighting object (VASI, PAPI, Wig-Wag, etc.) Zero, one or many for each airport
        } elsif ($type == 1000) { # 1000 Airport traffic flow Zero, one or many for an airport. Used if following rules met (rules of same type are ORed together, rules of a different type are ANDed together to). First flow to pass all rules is used.
        } elsif ($type == 1001) { # 1001 Traffic flow wind rule One or many for a flow. Multiple rules of same type “ORed”
        } elsif ($type == 1002) { # 1002 Traffic flow minimum ceiling rule Zero or one rule for each flow
        } elsif ($type == 1003) { # 1003 Traffic flow minimum visibility rule Zero or one rule for each flow
        } elsif ($type == 1004) { # 1004 Traffic flow time rule One or many for a flow. Multiple rules of same type “ORed”
        } elsif ($type == 1100) { # 1100 Runway-in-use arrival/departure constraints First constraint met is used. Sequence matters
        } elsif ($type == 1101) { # 1101 VFR traffic pattern Zero or one pattern for each traffic flow
        } elsif ($type == 1200) { # 1200 Header indicating that taxi route network data follows
        } elsif ($type == 1201) { # 1201 Taxi route network node Sequencing is arbitrary. Must be part of one or more edges
        } elsif ($type == 1202) { # 1202 Taxi route network edge Must connect two nodes
        } elsif ($type == 1204) { # 1204 Taxi route edge active zone Can refer to up to 4 runway ends
        } elsif ($type == 1300) { # 1300 Airport location Not explicitly connected to taxi route network
        } elsif (($type >= 50)&&($type <= 56)) { # 50–56 Communication frequencies Zero, one or many for each airport
            my @tfa = @arr;
            push(@freqs, \@tfa); # save the freq array
        } else {
            pgm_exit(1,"$.: [$line] UNPARSED! FIX ME!!\n");
        }
    }

    $elap = tv_interval ( $bgntm, [gettimeofday]);
    $lnspsec = $. / $elap;
    $remain = ($estmax / $lnspsec) - $elap;
    prt("Line $. of $estmax (est ".int($lnspsec)." lns/sec, elap=".secs_HHMMSS(int($elap)).", rem=".secs_HHMMSS(int($remain)).") - all done.\n");
    # prt("Line $. - all done\n");
    close(IF);
    # do any LAST entry
    if (length($apt)) {
        $trcnt = $rwycnt;
        $trcnt += $helicnt;
        $trcnt += $wwcnt;
        if ($trcnt > 0) {
            $alat = $glat / $trcnt;
            $alon = $glon / $trcnt;
            if (!in_world_range($alat,$alon)) {
                prtw("WARNING: $apline: OOW [$apt] $alat,$alon $rwycnt\n");
            }
        } else {
            $alat = 0;
            $alon = 0;
            prtw("WARNING: $.: No RUNWAYS [$apt]\n");
        }
        @arr2 = split(/ /,$apt);
        $icao = $arr2[4];
        $name = join(' ', splice(@arr2,5));
        ###prt("$diff [$apt] (with $rwycnt runways at [$alat, $alon]) ...\n");
        ###prt("$diff [$icao] [$name] ...\n");
        my @a = @runways;
        my @f = @freqs;
        my @h = @heliways;
        my @w = @waterways;
        if ($name =~ /\[X\]/) {
            $ra = \@closedapts;
        } else {
            if ($lasttype == 1) {
                $ra = \@aptlist;
                $totaptcnt++;	# count another AIRPORT
            } elsif ($lasttype == 16) {
                $ra = \@seaapts;
            } elsif ($lasttype == 17) {
                $ra = \@helipads;
            } else {
                prtw("$.: ERROR: Unknown last type $lasttype. [$apt]\n");
                pgm_exit(1,"");
            }
            $ils = find_ils_for_apt($icao);
            if ($ils > 0) {
                push(@majapts, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils, \@h]);
            }
        }
        push(@{$ra}, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils, \@h]);
    }

    $diff = scalar @aptlist;
    prt("Loaded $diff airports... \n");
    if (!$write_output) {
        return \@aptlist;
    }
    ######################################################################
    @sorted = sort mycmp_ascend_t1 @aptlist;
    $diff = scalar @sorted;
    $o_file = $out_path.$PATH_SEP.$out_base."-icao.csv";
    prt("Loaded $diff airports... writing to $o_file\n");
    $line = 'icao,"name",lat,lon,runways,ils'."\n";
    #                 0          1      2      3      4      5  6     7        8    9    10
    # push(@aptlist, [$lasttype, $icao, $name, $alat, $alon, 0, \@w,  $rwycnt, \@a, \@f, $ils]);
    for ($i = 0; $i < $diff; $i++) {
        $ra = $sorted[$i];
        ###$type = ${$ra}[0]; # now all type '1' land airports
        $icao = ${$ra}[1];
        $name = fix_airport_name(${$ra}[2]);
        $alat = ${$ra}[3];
        $alon = ${$ra}[4];
        #$bucket = ${$ra}[5];
        $rwwa = ${$ra}[6];
        $rwycnt = ${$ra}[7];
        $rwa  = ${$ra}[8];
        $ils  = ${$ra}[10];
        $line .= "$icao,\"$name\",$alat,$alon,$rwycnt,$ils\n";
    }
    write2file($line,$o_file);
    prt("icao CSV written to [$o_file]\n");

    @sorted = sort mycmp_ascend_t1 @seaapts;
    $o_file = $out_path.$PATH_SEP.$out_base."-sea.csv";
    $diff = scalar @sorted;
    prt("Loaded $diff seaports... writing to $o_file\n");
    $line = 'icao,"name",lat,lon,runways,ils'."\n";
    #                 0          1      2      3      4      5  6    7        8    9    10
    # push(@aptlist, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils]);
    for ($i = 0; $i < $diff; $i++) {
        $ra = $sorted[$i];
        ###$type = ${$ra}[0]; # now all type '1' land airports
        $icao = ${$ra}[1];
        $name = fix_airport_name(${$ra}[2]);
        $alat = ${$ra}[3];
        $alon = ${$ra}[4];
        #$bucket = ${$ra}[5];
        $rwwa = ${$ra}[6];
        $rwycnt = ${$ra}[7];
        $rwa  = ${$ra}[8];
        $ils  = ${$ra}[10];
        $line .= "$icao,\"$name\",$alat,$alon,$rwycnt,$ils\n";
    }
    write2file($line,$o_file);
    prt("sea CSV written to [$o_file]\n");

    @sorted = sort mycmp_ascend_t1 @helipads;
    $o_file = $out_path.$PATH_SEP.$out_base."-heli.csv";
    $diff = scalar @sorted;
    prt("Loaded $diff heliports... writing to $o_file\n");
    $line = 'icao,"name",lat,lon,runways,ils'."\n";
    #                 0          1      2      3      4      5  6    7        8    9    10
    # push(@aptlist, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils]);

    for ($i = 0; $i < $diff; $i++) {
        $ra = $sorted[$i];
        ###$type = ${$ra}[0]; # now all type '1' land airports
        $icao = ${$ra}[1];
        $name = fix_airport_name(${$ra}[2]);
        $alat = ${$ra}[3];
        $alon = ${$ra}[4];
        #$bucket = ${$ra}[5];
        $rwwa  = ${$ra}[6];
        $rwycnt = ${$ra}[7];
        $rwa  = ${$ra}[8];
        $ils  = ${$ra}[10];
        $line .= "$icao,\"$name\",$alat,$alon,$rwycnt,$ils\n";
    }
    write2file($line,$o_file);
    prt("heli CSV written to [$o_file]\n");

    # ===============================================
    @sorted = sort mycmp_ascend_t1 @majapts;
    $o_file = $out_path.$PATH_SEP.$out_base."-ils.csv";
    $diff = scalar @sorted;
    prt("Loaded $diff ap/ils... writing to $o_file\n");
    $line = 'icao,"name",lat,lon,runways,ils'."\n";
    #                 0          1      2      3      4      5        6    7        8    9    10
    # push(@aptlist, [$lasttype, $icao, $name, $alat, $alon, 0, \@w, $rwycnt, \@a, \@f, $ils]);
    for ($i = 0; $i < $diff; $i++) {
        $ra = $sorted[$i];
        ###$type = ${$ra}[0]; # now all type '1' land airports
        $icao = ${$ra}[1];
        $name = fix_airport_name(${$ra}[2]);
        $alat = ${$ra}[3];
        $alon = ${$ra}[4];
        #$bucket = ${$ra}[5];
        $rwwa = ${$ra}[6];
        $rwycnt = ${$ra}[7];
        $rwa  = ${$ra}[8];
        $ils  = ${$ra}[10];
        $line .= "$icao,\"$name\",$alat,$alon,$rwycnt,$ils\n";
    }
    write2file($line,$o_file);
    prt("ILS CSV written to [$o_file]\n");
    # ===============================================

    ##############################################
    @sorted = sort mycmp_ascend_t1 @aptlist if ($output_full_list);
    output_apts_to_json(\@sorted);
    ##############################################
    return \@aptlist;
}

sub load_nav_file {
	prt("\nLoading $navdat file ...\n");
	mydie("ERROR: Can NOT locate [$navdat]!\n") if ( !( -f $navdat) );
	open NIF, "<$navdat" or mydie( "ERROR: CAN NOT OPEN $navdat...$!...\n" );
	my @nav_lines = <NIF>;
	close NIF;
    my $cnt = scalar @nav_lines;
    prt("Loaded $cnt line...\n");
    return \@nav_lines;
}

sub search_nav {
	my ($typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name, $off);
    my ($alat, $alon);
    my ($dist, $az);
    my $rn = load_nav_file();
    my @nav_lines = @{$rn};
	my $nav_cnt = scalar @nav_lines;
	my $ac = scalar @aptlist2;
	prt("Processing $nav_cnt lines ...\n");
    if ($ac == 1) {
   		$alat = $aptlist2[0][3];
		$alon = $aptlist2[0][4];
        if ($usekmrange) {
            prt("Using distance of [$max_range_km] Km from $ac airport at $alat,$alon.\n" );
        } else {
            prt("Using deviation of [$nmaxlatd,$nmaxlond] from $ac airport at $alat,$alon.\n" );
        }
    } else {
        if ($usekmrange) {
            prt("Using maximum distance of [$max_range_km] from $ac airports.\n" );
        } else {
            prt("Using maximum lat,lon deviation of [$nmaxlatd,$nmaxlond] from $ac airports.\n" );
        }
    }
	my $vcnt = 0;
    my $navs_found = 0;
    my (@arr, $nc);
	foreach $line (@nav_lines) {
		$line = trimall($line);
		###prt("$line\n");
		@arr = split(/ /,$line);
		# 0   1 (lat)   2 (lon)        3     4   5           6   7  8++
		# 2   38.087769 -077.324919  284   396  25       0.000 APH  A P Hill NDB
		# 3   57.103719  009.995578   57 11670 100       1.000 AAL  Aalborg VORTAC
		# 4   39.980911 -075.877814  660 10850  18     281.662 IMQS 40N 29 ILS-cat-I
		# 4  -09.458922  147.231225  128 11010  18     148.650 IWG  AYPY 14L ILS-cat-I
		# 5   40.034606 -079.023281 2272 10870  18     236.086 ISOZ 2G9 24 LOC
		# 5   67.018506 -050.682072  165 10955  18      61.600 ISF  BGSF 10 LOC
		# 6   39.977294 -075.860275  655 10850  10  300281.205 ---  40N 29 GS
		# 6  -09.432703  147.216444  128 11010  10  302148.785 ---  AYPY 14L GS
		# 7   39.960719 -075.750778  660     0   0     281.205 ---  40N 29 OM
		# 7  -09.376150  147.176867  146     0   0     148.785 JSN  AYPY 14L OM
		# 8  -09.421875  147.208331   91     0   0     148.785 MM   AYPY 14L MM
		# 8  -09.461050  147.232544  146     0   0     328.777 PY   AYPY 32R MM
		# 9   65.609444 -018.052222   32     0   0      22.093 ---  BIAR 01 IM
		# 9   08.425319  004.475597 1126     0   0      49.252 IL   DNIL 05 IM
		# 12 -09.432703  147.216444   11 11010  18       0.000 IWG  AYPY 14L DME-ILS
		# 12 -09.449222  147.226589   11 10950  18       0.000 IBB  AYPY 32R DME-ILS
		$nc = scalar @arr;
		$typ = $arr[0];
        # Check for type number in @navset, and set $actnav to name, like VOR, NDB, etc
		if ( is_valid_nav($typ) ) {
			$vcnt++;
			$nlat = $arr[1];
			$nlon = $arr[2];
			$nalt = $arr[3];
			$nfrq = $arr[4];
			$nrng = $arr[5];
			$nfrq2 = $arr[6];
			$nid = $arr[7];
			$name = '';
			for (my $i = 8; $i < $nc; $i++) {
				$name .= ' ' if length($name);
				$name .= $arr[$i];
			}
			push(@navlist, [$typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name]);
            # Using $nmaxlatd, $nmaxlond, check airports in @aptlist2;
			$off = near_an_airport( $nlat, $nlon, \$dist, \$az );
			if ($off) {
				prt( "$actnav, $typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name ($off)\n") if ($dbg2);
				push(@navlist2, [$typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name, $off, $dist, $az]);
			}
        } elsif ($line =~ /^\d+\s+Version\s+-\s+DAFIF\s+/) {
            my $ind = index($line,',');
            prt( "NAVAID: ".substr($line, 0, (($ind > 0) ? $ind : 50) )."\n" );   # 810 Version - DAFIF ...
        } elsif (($line eq 'I')||($line eq '99')) {
            # ignore these
		} elsif (length($line)) {
            prtw("WARNING: What is this line? [$line]???\n");
        }
	}
    $navs_found = scalar @navlist2;
    if (($navs_found == 0) && $tryharder) {
        my $def_latd = $nmaxlatd;
        my $def_lond = $nmaxlond;
        my $def_dist = $max_range_km;
        while ($navs_found == 0) {
            $nmaxlatd += 0.1;
            $nmaxlond += 0.1;
            $max_range_km += 0.1;
            if ($usekmrange) {
                prt("Expanded to [$max_range_km] Km from $ac airport(s)...\n" );
            } else {
                prt("Expanded to [$nmaxlatd,$nmaxlond] from $ac airport(s)...\n" );
            }
            foreach $line (@nav_lines) {
                $line = trimall($line);
                ###prt("$line\n");
                @arr = split(/ /,$line);
                $nc = scalar @arr;
                $typ = $arr[0];
                # Check for type number in @navset, and set $actnav to name, like VOR, NDB, etc
                if ( is_valid_nav($typ) ) {
                    $nlat = $arr[1];
                    $nlon = $arr[2];
                    $nalt = $arr[3];
                    $nfrq = $arr[4];
                    $nrng = $arr[5];
                    $nfrq2 = $arr[6];
                    $nid = $arr[7];
                    $name = '';
                    for (my $i = 8; $i < $nc; $i++) {
                        $name .= ' ' if length($name);
                        $name .= $arr[$i];
                    }
                    # Using $nmaxlatd, $nmaxlond, check airports in @aptlist2;
                    $off = near_an_airport( $nlat, $nlon, \$dist, \$az );
                    if ($off) {
                        prt( "$actnav, $typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name ($off)\n") if ($dbg2);
                        push(@navlist2, [$typ, $nlat, $nlon, $nalt, $nfrq, $nrng, $nfrq2, $nid, $name, $off, $dist, $az]);
                    }
                }
            }
            $navs_found = scalar @navlist2;
        }
        prt("Found $navs_found nearby NAVAIDS, ");
        if ($usekmrange) {
            prt("using distance $max_range_km Km...\n" );
        } else {
            prt("using difference $nmaxlatd, $nmaxlond...\n" );
        }
        $nmaxlatd = $def_latd;
        $nmaxlond = $def_lond;
        $max_range_km = $def_dist;
    }
	prt("Done - Found $navs_found nearby NAVAIDS, of $vcnt searched...\n" );
}


##############
### functions

# 12/12/2008 - Additional distance calculations
# from 'signs' perl script
# Melchior FRANZ <mfranz # aon : at>
# $Id: signs,v 1.37 2005/06/01 15:53:00 m Exp $

# sub ll2xyz($$) {
sub ll2xyz {
	my $lon = (shift) * $D2R;
	my $lat = (shift) * $D2R;
	my $cosphi = cos $lat;
	my $di = $cosphi * cos $lon;
	my $dj = $cosphi * sin $lon;
	my $dk = sin $lat;
	return ($di, $dj, $dk);
}


# sub xyz2ll($$$) {
sub xyz2ll {
	my ($di, $dj, $dk) = @_;
	my $aux = $di * $di + $dj * $dj;
	my $lat = atan2($dk, sqrt $aux) * $R2D;
	my $lon = atan2($dj, $di) * $R2D;
	return ($lon, $lat);
}

# sub coord_dist_sq($$$$$$) {
sub coord_dist_sq {
	my ($xa, $ya, $za, $xb, $yb, $zb) = @_;
	my $x = $xb - $xa;
	my $y = $yb - $ya;
	my $z = $zb - $za;
	return $x * $x + $y * $y + $z * $z;
}


sub give_help {
	prt( "FLIGHTGEAR AIRPORT SEARCH UTILITY\n" );
	prt( "Usage: $pgmname options\n" );
	prt( "Options: A ? anywhere for this help.\n" );
	prt( " -icao=$apticao          - Search using icao.\n" );
	prt( " -latlon=$lat,$lon - Search using latitude, longitude.\n" );
	prt( " -maxout=$max_cnt           - Limit the airport output. A 0 for ALL.\n" );
	prt( " -maxll=$maxlatd,$maxlond      - Maximum difference, when searching ariports using lat,lon.\n" );
	prt( " -name=\"$aptname\"  - Search using airport name. (A -name=. would match all.)\n" );
	prt( " -shownavs (or -s)   - Show NAVAIDS around airport found, if any. " );
    prt( "(Def=". ($SHOWNAVS ? "On" : "Off") . ")\n" );
	prt( " -nmaxll=$nmaxlatd,$nmaxlond     - Maximum difference, when searching NAVAID lat,lon.\n" );
	prt( " -aptdata=$aptdat - Use a specific AIRPORT data file.\n" );
	prt( " -navdata=$navdat - Use a specific NAVAID data file.\n" );
    prt( " -range=$max_range_km          - Set Km range when checking for NAVAIDS.\n" );
    prt( " -r                  - Use above range ($max_range_km Km) for searching.\n" );
    prt( " -tryhard (or -t)    - Expand search if no NAVAIDS found in range. " );
    prt( "(Def=". ($tryharder ? "On" : "Off") . ")\n" );
	mydie( "                                     Happy Searching.\n" );
}

# Ensure argument exists, or die.
sub require_arg {
    my ($arg, @arglist) = @_;
    mydie( "ERROR: no argument given for option '$arg' ...\n" ) if ! @arglist;
}


sub get_bucket_info {
   my ($lon,$lat) = @_;
   #my $b = Bucket2->new();
   my $b = Bucket->new();
   $b->set_bucket($lon,$lat);
   return $b->bucket_info();
}

sub look_like_icao($) {
    my $icao = shift;
    my $up = uc($icao);
    my $len = length($icao);
    if (($len == 4) && ($up eq $icao)) {
        return 1;
    }
    return 0;
}

# How can I tell if a string is a number?
# The simplest method is:
#         if ($string == "$string") { 
#          # It is a number
#        } 
# Note the use of the == operator to compare the string to its numeric value. 
# However, this approach is dangerous because the $string might contain arbitrary 
# code such as @{[system "rm -rf /"]} which would be executed as a result of the 
# interpolation process. For safety, use this regular expression:
#   if ($var =~ /(?=.)M{0,3}(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})/) {
#    print "$var contains a number.\b";
#  }


# contains digits,commas and 1 period AND
# does not contain alpha's, more than 1 period
# commas or periods at the beggining and ends of
# each line AND
# is not null
sub IsANumber($) {
    my $var = shift;
    if ( ( $var =~ /(^[0-9]{1,}?$)|(\,*?)|(\.{1})/ ) &&
         !( $var =~ /([a-zA-Z])|(^[\.\,]|[\.\,]$)/ ) &&
         ($var ne '') ) {
         return 1;
    } 
    return 0;
}


sub looks_like_rwy($) {
    my $rwy = shift;
    if (length($rwy) > 0) {
        my $ch = substr($rwy,0,1);
        if (IsANumber($ch)) {  # or perhaps if ($ch == "$ch")
            return 1;
        }
    }
    return 0;
}

my %name_exceptions = (
    'BORYSPIL NDB' => 1,
    'DONETSK NDB' => 1,
    'LOPEZ ISLAND NDB' => 1,
    'PINCK NDB' => 1,
    'OKANAGAN NDB' => 1,
    'UTICA NDB' => 1,
    'DURBAN NDB' => 1,
    'NIZHNEYANSK NDB' => 1  # really should sort out LOCATION - Dist = 6585
    );

sub exception_names($) {
    my $name = shift;
    return 1 if (defined $name_exceptions{$name});
    return 0;
}

sub is_ndb_lom($$) {
    my ($ucnm1,$ucnm2) = @_;
    return 1 if (($ucnm1 =~ /NDB/)&&($ucnm2 =~ /LOM/));
    return 1 if (($ucnm1 =~ /LOM/)&&($ucnm2 =~ /NDB/));
    return 0;
}

# THESE SHOULD BE RE-CHECKED - EXCEPTIONS
sub is_big_exception($$) {
    my ($ucnm1,$ucnm2) = @_;
    return 1 if (($ucnm1 =~ /CHIHUAHUA/)&&($ucnm2 =~ /CHIHUAHUA/)); # dist 1223??? 12:3! VOR-DME
    return 1 if (($ucnm1 =~ /CATEY/)&&($ucnm2 =~ /CATEY/)); # dist 376 but one name starts 'EL ' VOR-DME/VORTAC
    return 1 if (($ucnm1 =~ /DONETSK/)&&($ucnm2 =~ /DONETSK/)); # dist 3971??? 13:3! DME/VOR-DME
    return 1 if (($ucnm1 =~ /GUANTANAMO/)&&($ucnm2 =~ /GUANTANAMO/)); # dist 2150??? 13:3! TACAN/VOR
    return 1 if (($ucnm1 =~ /BOURGET/)&&($ucnm2 =~ /BOURGET/)); # dist 92??? 13:12! DME VOR-DME
    return 0;
}


# sub filter_nav_list() if ($do_nav_filter);
sub filter_nav_list() {
    my @sorted = sort mycmp_ascend_n0 @navlist;
    my $max = scalar @sorted;
    my ($i,$ra,$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name);
    my ($j,$ra2,$type2,$nlat2,$nlon2,$feet2,$freq2,$rng2,$bear2,$id2,$icao2,$rwy2,$name2);
    my ($max2,$fnd,$dist,$az1,$az2,$ret,$msg1,$msg2,$i2,$j2);
    my ($ucnm1,$ucnm2,@arr1,@arr2);
    prt("Filtering $max navaids...\n");
    #$line = "type,lat,lon,feet,freq,rng,bear,id,icao,rwy,\"name\"\n";
    #                0     1     2     3     4     5    6     7   8     9    10
    # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    my @navs = ();
    my $bgntm = [gettimeofday];
    for ($i = 0; $i < $max; $i++) {
        $i2 = $i + 1;
        $ra = $sorted[$i];
        $type = ${$ra}[0];
        $nlat = ${$ra}[1];
        $nlon = ${$ra}[2];
        $feet = ${$ra}[3];
        $freq = ${$ra}[4];
        $rng  = ${$ra}[5];
        $bear = ${$ra}[6];
        $id   = ${$ra}[7];
        $icao = ${$ra}[8];
        $rwy  = ${$ra}[9];
        $name = ${$ra}[10];
        $max2 = scalar @navs;
        $fnd = 0;
        if (length($icao) == 0) {
            for ($j = 0; $j < $max2; $j++) {
                $j2 = $j + 1;
                $ra2 = $navs[$j];
                $type2 = ${$ra2}[0];
                $nlat2 = ${$ra2}[1];
                $nlon2 = ${$ra2}[2];
                $feet2 = ${$ra2}[3];
                $freq2 = ${$ra2}[4];
                $rng2  = ${$ra2}[5];
                $bear2 = ${$ra2}[6];
                $id2   = ${$ra2}[7];
                $icao2 = ${$ra2}[8];
                $rwy2  = ${$ra2}[9];
                $name2 = ${$ra2}[10];
                next if (length($icao2) > 0);
                if ( ($id eq $id2) && ($freq == $freq2) ) {
                    $msg1 = join(",", @{$ra})."\n";
                    $msg2 = join(",", @{$ra2})."\n";
                    $ret = fg_geo_inverse_wgs_84($nlat, $nlon, $nlat2, $nlon2, \$az1, \$az2, \$dist);
                    if ($ret > 0) {
                        $dist = $pole_2_pole; # make it BIG
                        $az1 = 0;
                        prtw("$i2:$j2: WARNING: fg_geo_inverse_wgs_84($nlat, $nlon, $nlat2, $nlon2, ...) FAILED!\n");
                    } else {
                        $dist = int($dist);
                        $ucnm1 = uc($name);
                        $ucnm2 = uc($name2);
                        @arr1 = split(/\s+/,$ucnm1);
                        @arr2 = split(/\s+/,$ucnm2);
                        if ($type == $type2) {
                            if ($dist < 10000) {
                                if ($type == 2) {
                                    if (($ucnm1 eq $ucnm2) && (exception_names($ucnm1))) {
                                        $fnd = 1;   # exception - drop duplication
                                        prt("$i2:$j2: NDB exception - Dist $dist! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    } elsif (is_ndb_lom($ucnm1,$ucnm2)) {
                                        $fnd = 1;   # exception for NDB and LOM
                                        prt("$i2:$j2: NDB and LOM - Dist $dist! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    } elsif (($arr1[0] eq $arr2[0]) && ($dist < 1000)) {
                                        $fnd = 1;   # ok name starts same like
                                        # 2,-42.72933333,170.95622222,0,310,100,0.0,HK,,,HOKITIKA NDB-DME
                                        # 2,-42.72933333,170.95622222,0,310,50,0.0,HK,,,HOKITIKA NDB
                                        prt("$i2:$j2: NDB DUPLICATION - Dist $dist! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    } else {
                                        prt("$i2:$j2: Potential NDB DUPLICATION - Dist $dist! CHECK ME!\n".$msg1.$msg2);
                                    }
                                } elsif ($dist < 1000) {
                                    if ($arr1[0] eq $arr2[0]) {
                                        prt("$i2:$j2: NDB DUPE - SAME FIRST NAME - Dist $dist! Dropping first\n".$msg1.$msg2) if (VERB9());
                                        $fnd = 1;
                                    }

                                } else {
                                    prt("$i2:$j2: Potential DUPLICATION - Dist $dist! CHECK ME!\n".$msg1.$msg2);
                                }
                            }
                        } else {
                            if ($dist < 20) {
                                # *** CO-LOCATION ***
                                # ok, decide these can be dropped without notice if
                                if (( ($type == 3) && ($type2 == 13) ) || ( ($type == 13) && ($type2 == 3) )) {
                                    # like AOSTA DME <=> AOSTA VOR-DME Dist 0 or close, SAME frequency
                                    $fnd = 1;
                                    prt("$i2:$j2: Combine VOR & VOR-DME - Dist $dist dropping first!\n".$msg1.$msg2) if (VERB9());
                                } elsif (( ($type == 3) && ($type2 == 12) ) || ( ($type == 12) && ($type2 == 3) )) {
                                    # like AOSTA DME <=> AOSTA VOR-DME Dist 0 or close, SAME frequency
                                    $fnd = 1;
                                    prt("$i2:$j2: Combine VOR & VOR-DME - Dist $dist dropping first!\n".$msg1.$msg2) if (VERB9());
                                } elsif ($ucnm1 eq $ucnm2) {
                                    $fnd = 1;
                                    prt("$i2:$j2: Combine SAME NAME - Dist $dist dropping first!\n".$msg1.$msg2) if (VERB9());
                                } elsif ($arr1[0] eq $arr2[0]) {
                                    $fnd = 1;
                                    prt("$i2:$j2: Combine FIRST NAME - Dist $dist dropping first!\n".$msg1.$msg2) if (VERB9());
                                } else {
                                    prt("$i2:$j2: Combine these - CO-LOCATED - Dist $dist dropping first!\n".$msg1.$msg2);
                                    $fnd = 1;
                                }
                            } elsif ($dist < 10000 ) {
                                if ( ($ucnm1 eq $ucnm2) && ($dist < 1000) ) {
                                    prt("$i2:$j2: Close $dist, and SAME NAME, freq, id $type:$type2! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    $fnd = 1;
                                } elsif ( ($arr1[0] eq $arr2[0]) && ($dist < 1000) ) {
                                    prt("$i2:$j2: Close $dist, and SAME FIRST NAME, freq, id $type:$type2! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    $fnd = 1;
                                } elsif (is_big_exception($ucnm1,$ucnm2)) {
                                    prt("$i2:$j2: Close $dist, special exceptions. CHECK ME! $type:$type2! Dropping first\n".$msg1.$msg2) if (VERB9());
                                    $fnd = 1;
                                } else {
                                    prt("$i2:$j2: WARNING: Quite CLOSE $dist??? $type:$type2!\n".$msg1.$msg2);
                                }
                            }
                        }
                    }
                }
                last if ($fnd); # found dupe - dropping one
            }   # for ($j = 0; $j < $max2; $j++)
        }
        if ($fnd == 0) {
            push(@navs,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
        }
    }
    @navlist = @navs;
    $i = scalar @navlist;
    my $elap = tv_interval ( $bgntm, [gettimeofday]);
    prt("Returning $i of $max. That mess took ".secs_HHMMSS(int($elap))."\n");
}


##################################################################################
### Load x-plane earth_nav.dat - all added to @navlist
##############################
sub parse_nav_lines($) {
    my $rnava = shift;
    my $max = scalar @{$rnava};
    # add to my @navlist = ();
    my ($i,$line,$lnn,@arr,$acnt,$type,$len,$vnav);
    my ($nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$name,$rwy);
    my (@sorted,$ra,$diff,$o_file);
    $lnn = 0;
    prt("Processing $max line of NAV data...\n");
    for ($i = 0; $i < $max; $i++) {
        $line = ${$rnava}[$i];
        chomp $line;
        $line = trimall($line);
        $len = length($line);
        $lnn++;
        next if ($len == 0);
        if ($lnn < 3) {
            if ($lnn == 2) {
                $o_file = $out_path.$PATH_SEP.'VERSION.nav.txt';
                write2file("$line\n",$o_file);
                prt(substr($line,0,50)."..., written to [$o_file]\n");
            }
            next;
        }
        @arr = split(/\s+/,$line);
        $acnt = scalar @arr;
        $type = $arr[0];
        if ($type == 99) {
            prt("$lnn: Reached EOF (99)\n");
            last;
        }
        #0  1           2             3    4     5   6          7    8                 9    10
        #CD LAT         LON           ELEV FREQ  RNG BEARING    ID   NAME              RWY  NAME
        #                             FT         NM. GS Ang          ICAO
        #2  47.63252778 -122.38952778 0      362 50  0.0        BF   NOLLA NDB
        #3  47.43538889 -122.30961111 354  11680 130 19.0       SEA  SEATTLE VORTAC
        #4  47.42939200 -122.30805600 338  11030 18  180.343    ISNQ KSEA               16L ILS-cat-I
        #6  47.46081700 -122.30939400 425  11030 10  300180.343 ISNQ KSEA               16L GS
        if ($acnt < 9) {
            prt("Split only yielded $acnt!\n");
            prt("$lnn: [$line]\n");
            pgm_exit(1,"");
        }

        $nlat = $arr[1];
        $nlon = $arr[2];
        $feet = $arr[3];
        $freq = $arr[4];
        $rng  = $arr[5];
        $bear = $arr[6];
        $id   = $arr[7];
        $icao = $arr[8];
        $name = $icao;
        $rwy  = '';
        if ($type == 2) {
            # 2  NDB - (Non-Directional Beacon) Includes NDB component of Locator Outer Markers (LOM)
            # 2  47.63252778 -122.38952778 0      362 50  0.0        BF   NOLLA NDB
            $icao = '';
            $name = join(' ', splice(@arr,8));
        } elsif ($type == 3) {
            # 3  VOR - (including VOR-DME and VORTACs) Includes VORs, VOR-DMEs and VORTACs
            # 3  47.43538889 -122.30961111 354  11680 130 19.0       SEA  SEATTLE VORTAC
            $icao = '';
            $name = join(' ', splice(@arr,8));
        } elsif ($type == 4) {
            # 4  ILS - LOC Localiser component of an ILS (Instrument Landing System)
            # 0  1           2             3    4     5   6          7    8                  9   10
            # 4  47.42939200 -122.30805600 338  11030 18  180.343    ISNQ KSEA               16L ILS-cat-I
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 5) {
            # 5  LOC - Localiser component of a localiser-only approach Includes for LDAs and SDFs
            # 5  40.03460600 -079.02328100  2272 10870 18  236.086   ISOZ 2G9                25  LOC
            # 5  67.01850600 -050.68207200   165 10955 18   61.600   ISF  BGSF               10  LOC
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 6) {
            # 6  GS  - Glideslope component of an ILS Frequency shown is paired frequency, not the DME channel
            # 6  47.46081700 -122.30939400 425  11030 10  300180.343 ISNQ KSEA               16L GS
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 7) {
            # 7  OM  - Outer markers (OM) for an ILS Includes outer maker component of LOMs
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 8) {
            # 8  MM  - Middle markers (MM) for an ILS
            # 8  47.47223300 -122.31102500 433  0     0   180.343    ---- KSEA               16L MM
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 9) {
            # 9  IM  - Inner markers (IM) for an ILS
            $rwy = $arr[9];
            $name = $arr[10];
        } elsif ($type == 12) {
            # 12 DME - including the DME component of an ILS, VORTAC or VOR-DME Frequency display suppressed on X-Plane’s charts
            # 0  1           2             3    4     5   6          7    8                  9   10
            # 12 47.43433300 -122.30630000 369  11030 18  0.000      ISNQ KSEA               16L DME-ILS
            # 12 47.43538889 -122.30961111 354  11680 130 0.0        SEA  SEATTLE VORTAC DME
            if (($acnt > 10) && look_like_icao($icao) && looks_like_rwy($arr[9])) {
                $rwy = $arr[9];
                $name = $arr[10];
            } else {
                ###prt("$lnn: Split $acnt! [$line]\n");
                $icao = ''; # this is NOT an ICAO
                $name = join(' ', splice(@arr,8));
            }
        } elsif ($type == 13) {
            # 13 Stand-alone DME, or the DME component of an NDB-DME Frequency will displayed on X-Plane’s charts
            # 0  1           2             3    4     5      6       7    8
            # 13 57.10393300  009.99280800  57  11670 199    0.0     AAL  AALBORG TACAN
            # 13 68.71941900 -052.79275300 172  10875  25    0.0     AS   AASIAAT DME
            $icao = '';
            $name = join(' ', splice(@arr,8));
        } else {
            prt("$lnn: INVALID [$line]\n");
            next;
        }
        #               0     1     2     3     4     5    6     7   8     9   10
        push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    }

    filter_nav_list() if ($do_nav_filter);

    @sorted = sort mycmp_ascend_n0 @navlist;
    $o_file = $out_path.$PATH_SEP.$out_base."-nav.csv";
    $diff = scalar @sorted;
    prt("Loaded $diff navaids... writing to $o_file\n");
    $line = "type,lat,lon,feet,freq,rng,bear,id,icao,rwy,\"name\"\n";
    #                0     1     2     3     4     5    6     7   8     9    10
    # push(@navlist,[$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,$name]);
    for ($i = 0; $i < $diff; $i++) {
        $ra = $sorted[$i];
        $type = ${$ra}[0];
        $nlat = ${$ra}[1];
        $nlon = ${$ra}[2];
        $feet = ${$ra}[3];
        $freq = ${$ra}[4];
        $rng  = ${$ra}[5];
        $bear = ${$ra}[6];
        $id   = ${$ra}[7];
        $icao = ${$ra}[8];
        $rwy  = ${$ra}[9];
        $name = ${$ra}[10];
        $line .= "$type,$nlat,$nlon,$feet,$freq,$rng,$bear,$id,$icao,$rwy,\"$name\"\n";
    }
    write2file($line,$o_file);
    prt("nav CSV written to [$o_file]\n");
}


sub check_files() {
    if (! -f $aptdat) {
        pgm_exit(1,"ERROR: Input file $aptdat does NOT EXIST!\n");
    }
    if (! -f $navdat) {
        pgm_exit(1,"ERROR: Input file $navdat does NOT EXIST!\n");
    }
    if (! -f $licfil) {
        pgm_exit(1,"ERROR: Input file $licfil does NOT EXIST!\n");
    }
    if (! -d $out_path) {
        pgm_exit(1,"ERROR: Ouput path [$out_path] does NOT EXIST!\nCreate the path, and run again...\n");
    }

    copy($licfil,$out_path);
    prt("Copied the licence text to [$out_path]\n");
    #### pgm_exit(0,"TEMP EXIT");
}

############################################
### MAIN ###
###prt( "$pgmname ... Hello, World ... ".scalar localtime(time())."\n" );

# parse_args(@ARGV);	# collect command line arguments ...
check_files();
my $nav_ref = load_nav_file();
parse_nav_lines($nav_ref);

# pgm_exit(0,"");

my $apt_ref = load_apt_data();

my $elapsed = tv_interval ( $t0, [gettimeofday]);
prt( "Ran for $elapsed seconds ... ".secs_HHMMSS(int($elapsed))."\n" );

pgm_exit(0,"");

$acnt = scalar @aptlist2;
prt( "Found $acnt, of $totaptcnt, airports ...\n" ) if ($dbg3);
set_average_apt_latlon();
if ($SRCHICAO) {
	prt( "Found $acnt matching $apticao ...(av. $av_apt_lat,$av_apt_lon)\n" ) if ($dbg3);
} elsif ($SRCHONLL) {
	prt( "Found $acnt matching $lat, $lon ...(av. $av_apt_lat,$av_apt_lon)\n" ) if ($dbg3);
} else {    # $SRCHNAME
	prt( "Found $acnt matching $aptname ... (av. $av_apt_lat,$av_apt_lon)\n" ) if ($dbg3);
}

#my @aptsort = sort mycmp_ascend @aptlist;
show_airports_found($max_cnt);
if ($acnt && $SHOWNAVS) {
	search_nav();
	show_navaids_found();
    show_airports_found($max_cnt);
}

$cnt = scalar @tilelist;
if ($cnt) {
	prt( "Scenery Tile" );
	if ($cnt > 1) {
		prt( "s" );
	}
	prt( ": " );
	foreach $name (@tilelist) {
		prt( "$name " );
	}
	prt( "\n" );
}

show_warnings(0);

#my $elapsed = tv_interval ( $t0, [gettimeofday]);
#prt( "Ran for $elapsed seconds ...\n" );

$loadlog = 1 if (($outcount > 30) || $dbg10 || $dbg11);
close_log($outfile,$loadlog);
unlink($outfile);
exit(0);

############################################################

# set $SRCHICAO on/off
# set $SRCHONLL on/off
sub parse_args {
	my (@av) = @_;
	my (@arr);
	while(@av) {
		my $arg = $av[0]; # shift @av;
        my $lcarg = lc($arg);
		if ($arg =~ /\?/) {
			give_help();

        # BY ICAO
		} elsif ( $arg =~ /-icao=(.+)/i ) {
			$apticao = $1;
			$SRCHICAO = 1;
			$SRCHONLL = 0;
			$SRCHNAME = 0;
			prt( "Search using ICAO of [$apticao] ...\n" );
		} elsif ( $lcarg eq '-icao' ) {
			require_arg(@av);
			shift @av;
			$SRCHICAO = 1;
			$SRCHONLL = 0;
			$SRCHNAME = 0;
			$apticao = $av[0];
			prt( "Search using ICAO of [$apticao] ...\n" );

        # BY LAT,LON
		} elsif ( $arg =~ /-latlon=(.+)/i ) {
			$SRCHICAO = 0;
			$SRCHONLL = 1;
			$SRCHNAME = 0;
			@arr = split(',', $1);
			if (scalar @arr == 2) {
				$lat = $arr[0];
				$lon = $arr[1];
				prt( "Search using LAT,LON of [$lat,$lon] ...\n" );
			} else {
				mydie( "ERROR: Failed to find lat,lon in [$arg]...\n" );
			}
		} elsif ( $lcarg eq '-latlon' ) {
			require_arg(@av);
			shift @av;
			$SRCHICAO = 0;
			$SRCHONLL = 1;
			$SRCHNAME = 0;
			@arr = split(',', $av[0]);
			if (scalar @arr == 2) {
				$lat = $arr[0];
				$lon = $arr[1];
				prt( "Search using LAT,LON of [$lat,$lon] ...\n" );
			} else {
				mydie( "ERROR: Failed to find lat,lon in [$arg]...\n" );
			}

        # By NAME
		} elsif ( $arg =~ /-name=(.+)/i ) {
			$aptname = $1;
			$SRCHICAO = 0;
			$SRCHONLL = 0;
			$SRCHNAME = 1;
			prt( "Search using NAME of [$aptname] ...\n" );
		} elsif ( $lcarg eq '-name' ) {
			require_arg(@av);
			shift @av;
			$SRCHICAO = 0;
			$SRCHONLL = 0;
			$SRCHNAME = 1;
			$aptname = $av[0];
			prt( "Search using NAME of [$aptname] ...\n" );
		} elsif ( $arg =~ /^-loadlog$/i ) {
			$loadlog = 1;
			prt( "Load log into wordpad.\n" );
		} elsif ( $arg =~ /^-shownavs$/i ) {
			$SHOWNAVS = 1;
			prt( "And show NAVAIDS around airport, if any.\n" );
		} elsif ( $arg =~ /^-s$/i ) {
			$SHOWNAVS = 1;
			prt( "And show NAVAIDS around airport, if any.\n" );
		} elsif ( $arg =~ /-maxll=(.+)/i ) {
			@arr = split(',', $1);
			if (scalar @arr == 2) {
				$maxlatd = $arr[0];
				$maxlond = $arr[1];
				prt( "Search maximum difference LAT,LON of [$maxlatd,$maxlond] ...\n" );
			} else {
				mydie( "ERROR: Failed to find maximum lat,lon difference in [$arg]...\n" );
			}
		} elsif ( $lcarg eq '-maxll' ) {
			require_arg(@av);
			shift @av;
			@arr = split(',', $av[0]);
			if (scalar @arr == 2) {
				$maxlatd = $arr[0];
				$maxlond = $arr[1];
				prt( "Search maximum difference LAT,LON of [$maxlatd,$maxlond] ...\n" );
			} else {
				mydie( "ERROR: Failed to find maximum lat,lon difference in [$arg]...\n" );
			}
		} elsif ( $arg =~ /-nmaxll=(.+)/i ) {
			@arr = split(',', $1);
			if (scalar @arr == 2) {
				$nmaxlatd = $arr[0];
				$nmaxlond = $arr[1];
				prt( "Search maximum difference LAT,LON of [$nmaxlatd,$nmaxlond] ...\n" );
			} else {
				mydie( "ERROR: Failed to find maximum lat,lon difference in [$arg]...\n" );
			}
		} elsif ( $lcarg eq '-nmaxll' ) {
			require_arg(@av);
			shift @av;
			@arr = split(',', $av[0]);
			if (scalar @arr == 2) {
				$nmaxlatd = $arr[0];
				$nmaxlond = $arr[1];
				prt( "Search maximum difference LAT,LON of [$nmaxlatd,$nmaxlond] ...\n" );
			} else {
				mydie( "ERROR: Failed to find maximum lat,lon difference in [$arg]...\n" );
			}
		} elsif ( $arg =~ /-aptdata=(.+)/i ) {
			$aptdat = $1;	# the airports data file
			prt( "Using AIRPORT data file [$aptdat] ...\n" );
		} elsif ( $lcarg eq '-aptdata' ) {
			require_arg(@av);
			shift @av;
			$aptdat = $av[0];	# the airports data file
			prt( "Using AIRPORT data file [$aptdat] ...\n" );
		} elsif ( $arg =~ /-navdata=(.+)/i ) {
			$navdat = $1;
			prt( "Using NAVAID data file [$navdat] ...\n" );
		} elsif ( $lcarg eq '-navdata' ) {
			require_arg(@av);
			shift @av;
			$navdat = $av[0];
			prt( "Using NAVAID data file [$navdat] ...\n" );
		} elsif ( $arg =~ /-maxout=(.+)/i ) {
			$max_cnt = $1;
			prt( "Airport output limited to $max_cnt. A zero (0), for no limit\n" );
		} elsif ( $lcarg eq '-maxout' ) {
			require_arg(@av);
			shift @av;
			$max_cnt = $av[0];
			prt( "Airport output limited to $max_cnt. A zero (0), for no limit\n" );
		} elsif ( $arg =~ /-range=(.+)/i ) {
			$max_range_km = $1;
			prt( "Navaid search using $max_range_km Km. A zero (0), for no limit\n" );
            $usekmrange = 1;
			prt( "Navaid search using $max_range_km Km.\n" );
		} elsif ( $lcarg eq '-range' ) {
			require_arg(@av);
			shift @av;
			$max_range_km = $av[0];
			prt( "Navaid search using $max_range_km Km. A zero (0), for no limit\n" );
            $usekmrange = 1;
			prt( "Navaid search using $max_range_km Km.\n" );
        } elsif ( $lcarg eq '-r' ) {
            $usekmrange = 1;
			prt( "Navaid search using $max_range_km Km.\n" );
        } elsif (( $lcarg eq '-tryhard' )||( $lcarg eq '-t' )) {
            $tryharder = 1;  # Expand the search for NAVAID, until at least 1 found
			prt( "Navaid search 'tryharder' set.\n" );
		} else {
			if (substr($arg,0,1) eq '-') {
				mydie( "ERROR: Unknown argument [$arg]. Try ? for HELP ...\n" );
			} else {
				# ASSUME AN AIRPORT NAME, unless exactly 4 upper case
                if ((length($arg) == 4)&&(uc($arg) eq $arg)) {
                    $SRCHICAO = 1;
                    $SRCHONLL = 0;
                    $SRCHNAME = 0;
                    $apticao = $arg;
                    prt( "Search using ICAO of [$apticao] ...\n" );
                } else {
                    $SRCHICAO = 0;
                    $SRCHONLL = 0;
                    $SRCHNAME = 1;
                    $aptname = $av[0];
                    prt( "Search using NAME of [$aptname] ...\n" );
                }
			}
		}
		shift @av;
	}

	# *** ONLY FOR TESTING ***
	if ($test_name) {
		$SRCHICAO = 0;
		$SRCHONLL = 0;
		$SRCHNAME = 1;
		$SHOWNAVS = 1;
        $usekmrange = 1;
        $max_range_km = 5;
		$aptname = $def_name;
	} elsif ($test_ll) {
		$lat = $def_lat;
		$lon = $def_lon;
		$maxlatd = 0.1;
		$maxlond = 0.1;
		$SRCHICAO = 0;
		$SRCHONLL = 1;
		$SRCHNAME = 0;
	} elsif ($test_icao) {
		$SRCHICAO = 1;
		$SRCHONLL = 0;
		$SRCHNAME = 0;
		$SHOWNAVS = 1;
		$apticao = $def_icao;
        # now have $tryharder to expand this, if NO NAVAIDS found
		$tryharder = 1;
        $usekmrange = 1;
	}

	if ( ($SRCHICAO == 0) && ($SRCHONLL == 0) && ($SRCHNAME == 0) ) {
		prt( "ERROR: No valid command action found, like -\n" );
        prt( "By ICAO -icao=KSFO, by LAT/LON -latlon=21,-122, or NAME -name=something!\n" );
		give_help();
	}
}

# eof - xp2csv.pl

# X-Plane apt.dat codes
my $x_code = <<EOF

FROM : http://data.x-plane.com/designers.html#Formats

Airports:  1000 Version (latest - revised Mar 2012), 850 Version (expired) 715 Version (expired)
================================================================================================
from : http://data.x-plane.com/file_specs/XP%20APT1000%20Spec.pdf
1    Land airport header
16   Seaplane base header
17   Heliport header
100  Runway
101  Water runway
102  Helipad
110  Pavement (taxiway or ramp) header Must form a closed loop
120  Linear feature (painted line or light string) header Can form closed loop or simple string
130  Airport boundary header Must form a closed loop
111  Node All nodes can also include a “style” (line or lights)
112  Node with Bezier control point Bezier control points define smooth curves
113  Node with implicit close of loop Implied join to first node in chain
114  Node with Bezier control point, with implicit close of loop Implied join to first node in chain
115  Node terminating a string (no close loop) No “styles” used
116  Node with Bezier control point, terminating a string (no close loop) No “styles” used
14   Airport viewpoint One or none for each airport
15   Aeroplane startup location *** Convert these to new row code 1300 ***
18   Airport light beacon One or none for each airport
19   Windsock Zero, one or many for each airport
20   Taxiway sign (inc. runway distance-remaining signs) Zero, one or many for each airport
21   Lighting object (VASI, PAPI, Wig-Wag, etc.) Zero, one or many for each airport
1000 Airport traffic flow Zero, one or many for an airport. Used if following rules met (rules of same type are ORed together, rules of a different type are ANDed together to). First flow to pass all rules is used.
1001 Traffic flow wind rule One or many for a flow. Multiple rules of same type “ORed”
1002 Traffic flow minimum ceiling rule Zero or one rule for each flow
1003 Traffic flow minimum visibility rule Zero or one rule for each flow
1004 Traffic flow time rule One or many for a flow. Multiple rules of same type “ORed”
1100 Runway-in-use arrival/departure constraints First constraint met is used. Sequence matters
1101 VFR traffic pattern Zero or one pattern for each traffic flow
1200 Header indicating that taxi route network data follows
1201 Taxi route network node Sequencing is arbitrary. Must be part of one or more edges
1202 Taxi route network edge Must connect two nodes
1204 Taxi route edge active zone Can refer to up to 4 runway ends
1300 Airport location Not explicitly connected to taxi route network
50–56 Communication frequencies Zero, one or many for each airport

50 ATC – Recorded AWOS, ASOS or ATIS
51 ATC – Unicom Unicom (US), CTAF (US), Radio (UK)
52 ATC – CLD Clearance Delivery
53 ATC – GND Ground
54 ATC – TWR Tower
55 ATC – APP Approach
56 ATC - DEP Departure

Airport line
#   0 1  2 3 4    5++
EG: 1 70 0 0 YSVS 1770
0  - Row code for an airport, seaplane base or heliport 1, 16 or 17
1  - Elevation of airport in feet above mean sea level (AMSL)
2  - Flag for control tower (used only in the X-Plane ATC system) 0=no ATC tower, 1=has ATC tower
3  - Deprecated. Use default value (“0”) Use 0
4  - Airport ICAO code. If no ICAO code exists, use FAA code (USA only) Maximum four characters. Must be unique.
5+ - Airport name. May contain spaces. Do not use special (accented) characters Text string (up to 40 characters)
Runway line
#   0   1     2 3 4    5 6 7 8   9            10            11    12   13 14 15 16 17  18           19           20     21   22 23 24 25
EG: 100 29.87 3 0 0.00 0 0 0 16  -24.20505300 151.89156100  0.00  0.00 1  0  0  0  34  -24.19732300 151.88585300 0.00   0.00 1  0  0  0
OR: 100 29.87 1 0 0.15 0 2 1 13L 47.53801700  -122.30746100 73.15 0.00 2  0  0  1  31R 47.52919200 -122.30000000 110.95 0.00 2  0  0  1
Land Runway
0  - 100 - Row code for a land runway (the most common) 100
1  - 29.87 - Width of runway in metres Two decimal places recommended. Must be >= 1.00
2  - 3 - Code defining the surface type (concrete, asphalt, etc) Integer value for a Surface Type Code
3  - 0 - Code defining a runway shoulder surface type 0=no shoulder, 1=asphalt shoulder, 2=concrete shoulder
4  - 0.15 - Runway smoothness (not used by X-Plane yet) 0.00 (smooth) to 1.00 (very rough). Default is 0.25
5  - 0 - Runway centre-line lights 0=no centerline lights, 1=centre line lights
6  - 0 - Runway edge lighting (also implies threshold lights) 0=no edge lights, 2=medium intensity edge lights
7  - 1 - Auto-generate distance-remaining signs (turn off if created manually) 0=no auto signs, 1=auto-generate signs
The following fields are repeated for each end of the runway
8  - 13L - Runway number (eg. 31R, 02). Leading zeros are required. Two to three characters. Valid suffixes: L, R or C (or blank)
9  - 47.53801700 - Latitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
10 - -122.30746100 - Longitude of runway threshold (on runway centerline) in decimal degrees Eight decimal places supported
11 - 73.15 - Length of displaced threshold in metres (this is included in implied runway length) Two decimal places (metres). Default is 0.00
12 - 0.00 - Length of overrun/blast-pad in metres (not included in implied runway length) Two decimal places (metres). Default is 0.00
13 - 2 - Code for runway markings (Visual, non-precision, precision) Integer value for Runway Marking Code
14 - 0 - Code for approach lighting for this runway end Integer value for Approach Lighting Code
15 - 0 - Flag for runway touchdown zone (TDZ) lighting 0=no TDZ lighting, 1=TDZ lighting
16 - 1 - Code for Runway End Identifier Lights (REIL) 0=no REIL, 1=omni-directional REIL, 2=unidirectional REIL
17 - 31R
18 - 47.52919200
19 - -122.30000000
20 - 110.95 
21 - 0.00 
22 - 2
23 - 0
24 - 0
25 - 1

Nav-aids: 810 version (latest - revised Oct 2011), 740 Version (expired)
========================================================================
from : http://data.x-plane.com/file_specs/XP%20NAV810%20Spec.pdf
for earth_nav.dat

2  NDB - (Non-Directional Beacon) Includes NDB component of Locator Outer Markers (LOM)
3  VOR - (including VOR-DME and VORTACs) Includes VORs, VOR-DMEs and VORTACs
4  ILS - LOC Localiser component of an ILS (Instrument Landing System)
5  LOC - Localiser component of a localiser-only approach Includes for LDAs and SDFs
6  GS  - Glideslope component of an ILS Frequency shown is paired frequency, not the DME channel
7  OM  - Outer markers (OM) for an ILS Includes outer maker component of LOMs
8  MM  - Middle markers (MM) for an ILS
9  IM  - Inner markers (IM) for an ILS
12 DME - including the DME component of an ILS, VORTAC or VOR-DME Frequency display suppressed on X-Plane’s charts
13 Stand-alone DME, or the DME component of an NDB-DME Frequency will displayed on X-Plane’s charts

Sample data
0  1           2             3    4     5   6          7    8                 9    10
CD LAT         LON           ELEV FREQ  RNG BEARING    ID   NAME              RWY  NAME
                             FT         NM. GS Ang          ICAO
2  47.63252778 -122.38952778 0      362 50  0.0        BF   NOLLA NDB
3  47.43538889 -122.30961111 354  11680 130 19.0       SEA  SEATTLE VORTAC
4  47.42939200 -122.30805600 338  11030 18  180.343    ISNQ KSEA               16L ILS-cat-I
6  47.46081700 -122.30939400 425  11030 10  300180.343 ISNQ KSEA               16L GS
8  47.47223300 -122.31102500 433  0     0   180.343    ---- KSEA               16L MM
12 47.43433300 -122.30630000 369  11030 18  0.000      ISNQ KSEA               16L DME-ILS
12 47.43538889 -122.30961111 354  11680 130 0.0        SEA  SEATTLE VORTAC DME
13 57.10393300  009.99280800  57  11670 199    0.0     AAL  AALBORG TACAN
13 68.71941900 -052.79275300 172  10875  25    0.0     AS   AASIAAT DME

Fixes: 600 Version (latest - revised July 2009)
===============================================
from : http://data.x-plane.com/file_specs/XP%20FIX600%20Spec.pdf
for earth_fix.dat
Sample
37.428522 -097.419194 ACESI

Airways:  640 Version (latest)
==============================
from : http://data.x-plane.com/file_specs/Awy640.htm
sample
ABCDE  32.283733 -106.898669 ABC    33.282503 -107.280542 2 180 450 J13
ABC    33.282503 -107.280542 DEF    35.043797 -106.816314 2 180 450 J13
DEF    35.043797 -106.816314 KLMNO  35.438056 -106.649536 2 180 450 J13-J14-J15 

ABCDE       Name of intersection or nav-aid at the beginning of this segment (the fix ABCDE in this example). 
32.283733   Latitude of the beginning of this segment. 
-106.898669 Longitude of the beginning of this segment. 
ABC         Name of intersection or nav-aid at the end of this segment (the nav-aid ABC in this example). 
33.282503   Latitude of the end of this segment. 
-107.280542 Longitude of the end of this segment. 
2           This is a "High" airway (1 = "low", 2 = "high").  If an airway segment is both High and Low, then it should be listed twice (once in each category).  This determines if the airway is shown on X-Plane's "High Enroute" or "Low Enroute" charts. 
180         Base of airway in hundreds of feet (18,000 feet in this example). 
450         Top of airways in hundreds of feet (45,000 feet in this example). 
J13         Airway segment name.  If multiple airways share this segment, then all names will be included separated by a hyphen (eg. "J13-J14-J15")  

Astronomical:  740 Version (latest)
===================================
from : http://data.x-plane.com/file_specs/Astro740.htm
sample
 6.752569 -16.713143 -1.43 Sirius
19.846301   8.867385  0.77 Altair
 2.529743  89.264138  1.97 Polaris 

6.752569   Right Ascension in decimal hours.  Always a positive number. 
-16.713143 Declination in decimal degrees.  Positive declinations are north of the celestial equator (eg. the pole star, Polaris, is at a declination of 89.264138 degrees). 
-1.43      Visible magnitude of the star.  This is a weird logarithmic scale (low numbers are brightest), and stars to a magnitude of +6.5 are considered visible to the naked eye (though this will vary hugely with your local seeing conditions, light pollution, altitude, etc.).  Sirius (the brightest star in the night sky) has a negative magnitude (-1.43) because it is very, very bright.  
Sirius     Star name (optional - not used by X-Plane).  

Any units of angular measure can be used for right ascension, but it is customarily 
measured in hours ( h ), minutes ( m ), and seconds ( s ), with 24h being equivalent 
to a full circle.

EOF
# ================================
