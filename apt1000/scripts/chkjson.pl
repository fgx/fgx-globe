#!/usr/bin/perl -w
# NAME: chkjson.pl
# AIM: Read a JSON file, and re-line it and output
# 06/03/2013 - Added batch file to run it
# 26/12/2012 - Add some default test code
use strict;
use warnings;
use File::Basename;  # split path ($name,$dir,$ext) = fileparse($file [, qr/\.[^.]*/] )
use Cwd;
use JSON;
use Data::Dumper;
use Time::gmtime;
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
# log file stuff
our ($LF);
my $pgmname = $0;
if ($pgmname =~ /(\\|\/)/) {
    my @tmpsp = split(/(\\|\/)/,$pgmname);
    $pgmname = $tmpsp[-1];
}
my $outfile = $temp_dir.$PATH_SEP."temp.$pgmname.txt";
open_log($outfile);

# user variables
my $VERS = "0.0.2 2013-03-06";
#my $VERS = "0.0.1 2012-07-18";
my $load_log = 0;
my $in_file = '';
my $verbosity = 0;
my $out_file = '';
my $use_json_module = 1;

# ### DEBUG ###
my $debug_on = 0;
my $def_file = 'C:\GTools\perl\temp-apts\PHLI.json';
#my $def_file = 'C:\FG\17\build-cf\expired.json';
my $tmp_json = $perl_dir.'\temptest.json';
# my $tmp_json = $def_file;

### program variables
my @warnings = ();
my $cwd = cwd();

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

sub get_test_json() {
    my $json = <<EOF;
{"success":true,
"source":"test_http.cxx",
"started":"2012-12-25 19:05:06",
"info":[{
	"TTL_secs":"10",
	"min_dist_m":"2000",
	"min_speed_kt":"20",
	"min_hdg_chg_deg":"1",
	"min_alt_chg_ft":"100",
	"tracker_log":"none",
	"tracker_db":"fgxtracker" ,
	"current_time":"2012-12-25 19:08:18 UTC",
	"secs_in_http":"0.2",
	"secs_running":"192.1"}]
,"ips":[
	{"ip":"127.0.0.1","cnt":"2","br":["MSIE"]},
	{"ip":"192.168.1.105","cnt":"7","br":["Opera","Lynx"]},
	{"ip":"192.168.1.174","cnt":"7","br":["MSIE","Safari"]}]
,"ip_stats":[{
	"rq":"16",
	"rcv":"12",
	"wb":"4",
	"err":"0",
	"rb":"3999",
	"se":"0",
	"sb":"52207",
	"av":"0.011 secs"}]
}
EOF
    return $json;
}

sub reline_json($) {
    my $ra = shift; # \@lines);
    my $line = join("\n",@{$ra});
    my $len = length($line);
    my @braces = ();
    my ($i,$ch,$brcnt,$ind,$indent,$inquot,$tag,$ch2,$i2);
    my ($pc,$lnn,$warns,$lc,$ri,$name,$it,$stag);
    $indent = '    ';
    $inquot = 0;
    $tag = '';
    $lnn = 1;
    $warns = 0;
    my @actitem = ();
    $lc = '';
    $name = '';
    my @itemtyp = ();
    my @master = ();
    for ($i = 0; $i < $len; $i++) {
        $ch = substr($line,$i,1);
        if ($inquot) {
            $inquot = 0 if ($ch eq '"');
        } else {
            if ($ch =~ /\s/) {
                if ($ch eq "\n") {
                    $lnn++;
                }
                next;
            }
            if ($ch eq '"') {
                $inquot = 1;
            } elsif ($ch eq '{') {
                $lc = $ch;
                if (length($tag)) {
                    if (@actitem) {
                        $ri = $actitem[-1];
                        $it = $itemtyp[-1];
                        #$stag = strip_quotes($tag);
                        #if ($it eq '{') {
                        #    ${$ri}{$name} = $stag;
                        #} elsif ($it eq '[') {
                        #    push(@{$ri},[$name,$stag]);
                        #} else {
                        #    prt("WARNING: $lnn: Got $ch with $it, NO last character\n");
                        #    $warns++;
                        #}
                    } else {
                        prtw("WARNING: $lnn: Got $ch with NO items on stack!\n");
                        $warns++;
                    }
                }
                my %h = ();
                push(@actitem,\%h); # start hash
                push(@itemtyp,$lc); # and keep type
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                if (length($tag)) {
                    prt($ind.$name.':'.$tag." $ch\n");
                } else {
                    prt($ind."$ch\n");
                }
                push(@braces,$ch);
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $ch = '';
                $tag = ''
            } elsif ($ch eq '}') {
                if (length($tag)) {
                    $stag = strip_quotes($tag);
                    prt($ind.$name.':'."$stag\n");
                }
                if (@braces) {
                    $pc = pop @braces;
                    $ri = pop @actitem;
                    $it = pop @itemtyp;
                    if ($pc ne '{') {
                        prtw("WARNING: $lnn: popped '$pc' NOT '{'!\n");
                        $warns++;
                    } else {
                        $stag = strip_quotes($tag);
                        if ($it eq '{') {
                            ${$ri}{$name} = $stag;
                        } elsif ($it eq '[') {
                            push(@{$ri},[$name,$stag]);
                        } else {
                            prt("WARNING: $lnn: Got $ch with $it, NO last character\n");
                            $warns++;
                        }
                        push(@master,$ri);
                    }
                } else {
                    prtw("WARNING: $lnn: Got $ch with none on stack!\n");
                    $warns++;
                }
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $i2 = $i + 1;
                for (; $i2 < $len; $i2++) {
                    $ch2 = substr($line,$i2,1);
                    next if ($ch2 =~ /\s/);
                    if ($ch2 eq ',') {
                        $ch .= $ch2;
                        $i = $i2;
                        last;
                    } else {
                        last;
                    }
                }
                prt($ind."$ch\n");
                $ch = '';
                $tag = '';
            } elsif ($ch eq '[') {
                $lc = $ch;
                my @a = ();
                push(@actitem,\@a); # start array
                push(@itemtyp,$lc); # and type
                prt($ind.$name.':'.$tag." $ch\n");
                # $ind .= $indent;
                push(@braces,$ch);
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $tag = '';
                $ch = '';
            } elsif ($ch eq ']') {
                if (length($tag)) {
                    $stag = strip_quotes($tag);
                    prt($ind.$name.':'."$stag\n");
                }
                if (@braces) {
                    $pc = pop @braces;
                    $ri = pop @actitem;
                    $it = pop @itemtyp;
                    if ($pc ne '[') {
                        prtw("WARNING: $lnn: popped '$pc' NOT '['!\n");
                        $warns++;
                    } else {
                        $stag = strip_quotes($tag);
                        if ($it eq '{') {
                            ${$ri}{$name} = $stag;
                        } elsif ($it eq '[') {
                            push(@{$ri},[$name,$stag]);
                        } else {
                            prt("WARNING: $lnn: Got $ch with $it, NO last character\n");
                            $warns++;
                        }
                        push(@master,$ri);
                    }
                } else {
                    prt("WARNING: $lnn: Got $ch with none on stack\n");
                    $warns++;
                }
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $i2 = $i + 1;
                for (; $i2 < $len; $i2++) {
                    $ch2 = substr($line,$i2,1);
                    next if ($ch2 =~ /\s/);
                    if ($ch2 eq ',') {
                        $ch .= $ch2;
                        $i = $i2;
                        last;
                    } else {
                        last;
                    }
                }
                prt($ind." $ch\n");
                $ch = '';
                $tag = '';
            } elsif ($ch eq ',') {
                if (length($tag)) {
                    $stag = strip_quotes($tag);
                    prt($ind.$name.':'.$stag."$ch\n");
                    if (@actitem) {
                        $ri = $actitem[-1];
                        $lc = $itemtyp[-1];
                        if ($lc eq '{') {
                            ${$ri}{$name} = $stag;
                        } elsif ($lc eq '[') {
                            push(@{$ri},[$name,$stag]);
                        } else {
                            prt("WARNING: $lnn: Got $ch with NO last character\n");
                            $warns++;
                        }
                    } else {
                        prt("WARNING: $lnn: Got $ch with none on stack\n");
                        $warns++;
                    }
                } else {
                    prt($ind."$ch\n");
                }
                $ch = '';
                $tag = '';
            } elsif ($ch eq ':') {
                if (length($tag)) {
                    $name = strip_quotes($tag);
                } else {
                    prt("WARNING: $lnn: Got $ch with NO object name!\n");
                    $warns++;
                }
                $ch = '';
                $tag = '';
            } 
        }
        $tag .= $ch;
    }
    if ($warns) {
        prt("Got $warns warnings!\n");
    } else {
        prt("\nDump of master array...\n");
        $lnn = Dumper(@master);
        prt("$lnn\n");
        prt("End of DUMP\n");
    }
}

sub reline_json_OK($) {
    my $ra = shift; # \@lines);
    my $line = join("\n",@{$ra});
    my $len = length($line);
    my @braces = ();
    my ($i,$ch,$brcnt,$ind,$indent,$inquot,$tag,$ch2,$i2);
    $indent = '    ';
    $inquot = 0;
    $tag = '';
    for ($i = 0; $i < $len; $i++) {
        $ch = substr($line,$i,1);
        if ($inquot) {
            $inquot = 0 if ($ch eq '"');
        } else {
            next if ($ch =~ /\s/);
            if ($ch eq '"') {
                $inquot = 1;
            } elsif ($ch eq '{') {
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                prt($ind.$tag." $ch\n");
                push(@braces,$ch);
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $ch = '';
                $tag = ''
            } elsif ($ch eq '}') {
                prt($ind."$tag\n") if (length($tag));
                $tag = '';
                if (@braces) {
                    pop @braces;
                } else {
                    prt("WARNING: Got $ch with none on stack\n");
                }
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                $i2 = $i + 1;
                for (; $i2 < $len; $i2++) {
                    $ch2 = substr($line,$i2,1);
                    next if ($ch2 =~ /\s/);
                    if ($ch2 eq ',') {
                        $ch .= $ch2;
                        $i = $i2;
                        last;
                    } else {
                        last;
                    }
                }
                prt($ind."$ch\n");
                $ch = '';
            } elsif ($ch eq '[') {
                prt($ind.$tag." $ch\n");
                $tag = '';
                $ch = '';
                $ind .= $indent;
            } elsif ($ch eq ']') {
                $i2 = $i + 1;
                $brcnt = scalar @braces;
                $ind = $indent x $brcnt;
                for (; $i2 < $len; $i2++) {
                    $ch2 = substr($line,$i2,1);
                    next if ($ch2 =~ /\s/);
                    if ($ch2 eq ',') {
                        $ch .= $ch2;
                        $i = $i2;
                        last;
                    } else {
                        last;
                    }
                }
                prt($ind."$tag\n") if (length($tag));
                $tag = '';
                prt($ind." $ch\n");
                $ch = '';
            } elsif ($ch eq ',') {
                prt($ind.$tag."$ch\n");
                $ch = '';
                $tag = '';
            } 
        }
        $tag .= $ch;
    }
}


sub process_in_file($) {
    my ($inf) = @_;
    if (! open INF, "<$inf") {
        pgm_exit(1,"ERROR: Unable to open file [$inf]\n"); 
    }
    my @lines = <INF>;
    close INF;
    my $lncnt = scalar @lines;
    my ($line,$cnt,$lnn,$i,$fid,$secs,$ctr,$tm,$ccnt);
    $cnt = sprintf("%3d",$lncnt);
    prt("Processing $cnt lines, from [$inf]...\n");
    $lnn = 0;
    if ($use_json_module) {
        $line = join(" ",@lines);
        my $json = JSON->new->allow_nonref;
        my $perl_scalar = $json->decode( $line );
        $lnn = Dumper($perl_scalar);
        if (VERB5()) {
            prt("Dump of perl scalar...\n");
            prt("$lnn\n");
            prt("End DUMP\n");
        }
    } else {
        reline_json(\@lines);
    }
}

#########################################
### MAIN ###
parse_args(@ARGV);
process_in_file($in_file);
pgm_exit(0,"");
########################################

sub need_arg {
    my ($arg,@av) = @_;
    pgm_exit(1,"ERROR: [$arg] must have a following argument!\n") if (!@av);
}

sub parse_args {
    my (@av) = @_;
    my ($arg,$sarg);
    while (@av) {
        $arg = $av[0];
        if ($arg =~ /^-/) {
            $sarg = substr($arg,1);
            $sarg = substr($sarg,1) while ($sarg =~ /^-/);
            if (($sarg =~ /^h/i)||($sarg eq '?')) {
                give_help();
                pgm_exit(0,"Help exit(0)");
            } elsif ($sarg =~ /^v/) {
                if ($sarg =~ /^v.*(\d+)$/) {
                    $verbosity = $1;
                } else {
                    while ($sarg =~ /^v/) {
                        $verbosity++;
                        $sarg = substr($sarg,1);
                    }
                }
                prt("Verbosity = $verbosity\n") if (VERB1());
            } elsif ($sarg =~ /^l/) {
                if ($sarg =~ /^ll/) {
                    $load_log = 2;
                } else {
                    $load_log = 1;
                }
                prt("Set to load log at end. ($load_log)\n") if (VERB1());
            } elsif ($sarg =~ /^o/) {
                need_arg(@av);
                shift @av;
                $sarg = $av[0];
                $out_file = $sarg;
                prt("Set out file to [$out_file].\n") if (VERB1());
            } else {
                pgm_exit(1,"ERROR: Invalid argument [$arg]! Try -?\n");
            }
        } else {
            $in_file = $arg;
            prt("Set input to [$in_file]\n") if (VERB1());
        }
        shift @av;
    }

    if ($debug_on) {
        prtw("WARNING: DEBUG is ON\n");
        if ((length($in_file) ==  0) && $debug_on) {
            $in_file = $def_file;
            ##$arg = get_test_json();
            ##write2file($arg,$tmp_json);
            ##$in_file = $tmp_json;
            prt("Set DEFAULT input to [$in_file]\n");
            ##$load_log = 2;
        }
    }
    if (length($in_file) ==  0) {
        pgm_exit(1,"ERROR: No input files found in command!\n");
    }
    if (! -f $in_file) {
        pgm_exit(1,"ERROR: Unable to find in file [$in_file]! Check name, location...\n");
    }
}

sub give_help {
    prt("$pgmname: version $VERS\n");
    prt("Usage: $pgmname [options] in-file\n");
    prt("Options:\n");
    prt(" --help  (-h or -?) = This help, and exit 0.\n");
    prt(" --verb[n]     (-v) = Bump [or set] verbosity. def=$verbosity\n");
    prt(" --load        (-l) = Load LOG at end. ($outfile)\n");
    prt(" --out <file>  (-o) = Write output to this file.\n");
}

# eof - template.pl
