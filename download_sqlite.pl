#!/usr/bin/perl
use strict;
use warnings;
use DBI;
my @drivers = DBI->available_drivers();
die "Error, please install DBI::SQLite" unless (grep { $_ eq "SQLite" } @drivers);

print "Downloading the full CPAN tester database, around 13 MB..";
#`wget http://cpants.perl.org/static/cpants_all.db.gz`;
die "Error, couldn't download the cpants_all.db.gz file from http://testers.cpan.org!" unless -p 'cpants_all.db.gz';
say "done";

print "Unpacking CPAN tester database..";
`gunzip cpants_all.db.gz`;
die "Error, couldn't unpack the cpants_all.db.gz file!" unless -p 'cpants_all.db';
#`rm cpants_all.db.gz`;
#die "Warning, couldn't remove the cpants_all.db.gz file" if -p 'cpants_all.db';
say "done";

