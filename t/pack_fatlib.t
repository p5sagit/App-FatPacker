#!perl
use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);
use FindBin qw/$Bin/;
use File::Spec;

require File::Spec->catdir($Bin, "pack_lib.t");
test_with("fatlib");

