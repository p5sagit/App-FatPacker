#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Basename;
use File::Copy;
use File::Path;
use File::Temp;

sub test_with {
    use_ok "App::FatPacker", "";
    my $dir = shift;
    my $tempdir = File::Temp->newdir;
    mkpath([<$tempdir/$dir/t/mod>]);

    for(<t/mod/*.pm>) {
        copy $_, "$tempdir/$dir/$_" or die "copy failed: $!";
    }

    chdir $tempdir;

    my $fp = App::FatPacker->new;
    my $temp_fh = File::Temp->new;
    select $temp_fh;
    $fp->script_command_file;
    print "1;\n";
    select STDOUT;
    close $temp_fh;

    # Packed, now try using it:
    require $temp_fh;

    {
        require t::mod::a;
        no warnings 'once';
        ok $t::mod::a::foo eq 'bar';
    }
}

unless (caller()) {
    plan 'no_plan';
    test_with("lib");
}
