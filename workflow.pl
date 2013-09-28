#!/usr/bin/perl

use Term::ReadKey;

print " .---------------------------------------------.\n";
print " | cpan-explorer.org static content generation |\n";
print " '---------------------------------------------'\n";

echo ""
echo "Step 1 - Downloading database.."
#`./download_sqlite.pl`;

echo ""
echo "Step 2 - Manual spatialization : press any key when svg is ready"
ReadMode 4; # Turn off controls keys
while (not defined ($key = ReadKey(-1)) {
    # No key yet
}
ReadMode 0; # Reset tty mode before exiting


print "\nStep 3 - Generating high-res PNGs..\n";

my $scale = 20000;
my $inputfile = 'packages.svg';
my $outputfile = 'packages.png';
my $rsvgpath = 'rsvg';

die "couldn't find $inputfile" unless -e $inputfile;
`$rsvgpath -x $scale -y $scale $inputfile $outputfile`;

my $inputfile = 'authors.svg';
my $outputfile = 'authors.png';
my $rsvgpath = 'rsvg';

die "couldn't find $inputfile" unless -e $inputfile;
`$rsvgpath -x $scale -y $scale $inputfile $outputfile`;

print "\nStep 4 - Generating tiles..\n";
`./generate_tiles.pl';

