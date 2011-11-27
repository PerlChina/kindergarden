#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use KinderGarden::Basic;

my $root = KinderGarden::Basic->root;
ok(-e "$root/conf/kindergarden.yml");

my $config = KinderGarden::Basic->config;
ok(ref $config eq 'HASH');

my $dbh = KinderGarden::Basic->dbh;
isa_ok($dbh, 'DBI::db');

done_testing();

1;