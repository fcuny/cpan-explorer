#!/usr/bin/perl
use strict;
use warnings;
use DBI;

#################################################
my $mode = "date";
my $input = 'testers.db';
my $output = "cpan_full_with_".$mode.".gexf";
################################################

open(OUTPUT,">",$output);
print OUTPUT
"<gexf version=\"1.0\">\n\t<meta>\n\t\t<creator>rtgi</creator>\n\t</meta>
\t<graph type=\"dynamic\">
\t\t<attributes class=\"node\" type=\"dynamic\">
\t\t\t<attribute id=\"0\" title=\"dname\" type=\"string\"/>
\t\t\t<attribute id=\"1\" title=\"vname\" type=\"string\"/>
\t\t\t<attribute id=\"2\" title=\"version\" type=\"string\"/>
\t\t\t<attribute id=\"3\" title=\"dtype\" type=\"string\"/>
\t\t</attributes>\n";

my @drivers = DBI->available_drivers();
die "Error, please install DBI::SQLite"
    unless (grep { $_ eq "SQLite" } @drivers);
my $dbh = DBI->connect("dbi:SQLite:dbname=$input","","",
                       { AutoCommit => 0,
                         PrintError => 1 });

print OUTPUT "\t\t<nodes>";

my $minimalDate = "0";
if ($mode eq "date") {
    $minimalDate = "1997-01-01";
}
print OUTPUT "\n\t\t\t<node id=\"0\" label=\"Perl 5\" pid=\"0\" ".$mode."from=\"".$minimalDate."\">
\t\t\t\t<attvalue id=\"0\" value=\"Perl\"/>
\t\t\t\t<attvalue id=\"1\" value=\"Perl\"/>
\t\t\t\t<attvalue id=\"2\" value=\"5\"/>
\t\t\t</node>";

my $distrib_query =
 "select id, dist, package, vname, version, released from dist order by dist";

my $sth = $dbh->prepare($distrib_query);
$sth->execute;
if ($dbh->err()) { die "$DBI::errstr\n"; }

my $distributions = {};
my $n = 0;
while (my ($id, $dname, $package, $vname, $version, $date) = $sth->fetchrow) {
    my $from = "0";
    $vname = $dname unless $version;
    $version = 0 unless $version;
	 $date = "1997-01-01 00:00:00" unless $date;
    if ($mode eq "date") {
        # day-based epoch
        $date = substr($date, 0, 10);
    } elsif ($mode eq "step") {
        # day-based epoch
        $date = (int(substr($date, 0, 4))-1996) * 365
              + int(substr($date, 5, 2)) * 31
              + int(substr($date, 8, 2));  
    }

    $distributions->{$id} = $date;

    print OUTPUT "
\t\t\t<node id=\"$id\" label=\"$vname\" pid=\"0\" ".$mode."from=\"$date\">
\t\t\t\t<attvalue id=\"0\" value=\"$dname\"/>
\t\t\t\t<attvalue id=\"1\" value=\"$vname\"/>
\t\t\t\t<attvalue id=\"2\" value=\"$version\"/>
\t\t\t</node>";

    $n++;
}

$sth->finish;

print "\nfetched $n distributions.\n\n";
print OUTPUT "\n\t\t</nodes>\n\t\t<edges>";
my $prereq_query =
 "select id, dist, requires, in_dist from prereq order by dist";

$sth = $dbh->prepare($prereq_query);
$sth->execute;
if ($dbh->err()) { die "$DBI::errstr\n"; }

my $e = 0;
while (my ($id, $source_id, $target_dname, $target_id) = $sth->fetchrow) {
    $target_id = 0 unless $target_id;
    my $from = $distributions->{$target_id};
    print OUTPUT "
\t\t\t<edge cardinal=\"1\" id=\"$id\" source=\"$source_id\" target=\"$target_id\" type=\"dir\" ".$mode."from=\"$from\">
\t\t\t\t<attvalue id=\"3\" value=\"prereq\"/>
\t\t\t</edge>";
    $e++;
}

$sth->finish;
print OUTPUT "\n\t\t</edges>\n\t</graph>\n</gexf>";
$dbh->disconnect;
