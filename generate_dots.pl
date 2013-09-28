#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use GraphViz;


my @drivers = DBI->available_drivers();
die "Error, please install DBI::SQLite" unless (grep { $_ eq "SQLite" } @drivers);

print "Generating graphviz .dot files for each package..\n";
my $dbh = DBI->connect("dbi:SQLite:dbname=cpants_all.db","","", { AutoCommit => 0, PrintError => 1 });

print "Loading packages..\n";
my $sth = $dbh->prepare("select id, dist from dist order by dist");
$sth->execute; 
die "$DBI::errstr" if ($dbh->err());
my $packages = {};
while (my ($package_id, $package_name) = $sth->fetchrow) {
    $packages->{ int($package_id) } = $package_name;
}
$sth->finish;
print  "done\n";

print "Loading dependencies..\n";
$sth = $dbh->prepare("select id, dist, in_dist from prereq order by dist");
$sth->execute;
die "$DBI::errstr\n" if ($dbh->err());
my @dependencies = ();
while (my ($dependency_id, $user_id, $used_id) = $sth->fetchrow) { 
    my $user = int( ($user_id)?$user_id:0 );
    my $used = int( ($used_id)?$used_id:0 );
    my @dep = ($user,$used);
    push(@dependencies, \@dep) if ($user != 0 && $used != 0);
 
}
$sth->finish;
$dbh->disconnect;
print "done\n";

sub addRoots {
	my ($g, $package, $n, $e) = @_;
    $n = {} unless defined $n;
    $e = {} unless defined $e;
    $n->{$package} = 1;
    for (@dependencies) {
        my ($user, $used) = @$_;
    	if ($user == $package && $used != $package) {
           #print "      - $package use ".$packages->{ $used }." (id: $used)\n";
               $g->add_node($used, label => $packages->{ $used });

	   $g->add_edge($package, $used);	

           unless (exists($n->{$used})) {
              ($g,$n, $e) = addRoots($g, $used, $n, $e);
          }
        }
    }  
    ($g,$n, $e) 
}

sub addLeaves {
	my ($g, $package, $n, $e) = @_;
    $n = {} unless defined $n;
    $e = {} unless defined $e;
    $n->{$package} = 1;
    for (@dependencies) {
        my ($user, $used) = @$_;
    	if ($used == $package && $user != $package) {
           #print "      - $package use ".$packages->{ $used }." (id: $used)\n";
           $g->add_node($user, label => $packages->{ $user });

	   $g->add_edge($user, $package);	

           unless (exists($n->{$user})) {
              ($g,$n, $e) = addLeaves($g, $user, $n, $e);
          }
        }
    }  
    ($g,$n, $e) 
}

print "Generating graphs..\n";
use Data::Dumper;
while(my ($package_id, $package_name) = each(%$packages)) {
    if ($package_name eq "Moose") {
    print "  - loading $package_name dependencies..\n";
    my $g = GraphViz->new( overlap => 'compress', ratio => 'compress' );
    my $n = {};
    my $e = {};
    
    # core
    $g->add_node($package_id, label => $packages->{$package_id}, color => 'red');

    ($g,$n, $e) = addRoots($g, $package_id);

    #($g, $n, $e) = addLeaves($g, $package_id);

    print "  - generating $package_name content..\n";
    #$full_graph->as_png("graphs/$package_name/$package_name.png");
    #$full_graph->as_dot("graphs/$package_name/$package_name.dot");
    $g->as_png("graphs/$package_name.png");
	}

}


