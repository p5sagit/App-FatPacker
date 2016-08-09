use strict;
use warnings;
use Cwd qw{getcwd};
use ExtUtils::Packlist;
use File::Basename qw{basename};
use File::Copy qw{copy};
use File::Spec::Functions qw{catdir};
use File::Temp qw{tempdir};
use Test::More;
use App::FatPacker;

our ($tmpdir, $libdir);
BEGIN {
    $tmpdir = tempdir('fatpack-XXXXX', TMPDIR => 1, CLEANUP => 1);
    $libdir = catdir $tmpdir, 'lib', 'perl5';
}
use lib $libdir;

##
## Cannot continue if a symlink is not possible
##
my $symlink_exists = eval { symlink("", ""); 1 };
plan skip_all => "symlinks not supported" if $@;


sub setup_directories {
    my $prefix = shift;

    my $cwd = getcwd();
    my $dist_tmpdir = tempdir('fatpacker-XXXXX', DIR => "$cwd/t", CLEANUP => 1);

    my $perl5 = catdir $dist_tmpdir, 'perl5';
    mkdir $perl5;
    ok(-d $perl5, 'made module install directory successfully');

    my $auto = catdir $perl5, 'auto';
    mkdir $auto;
    ok(-d $auto, 'made auto directory successfully');

    for (<t/mod/*.pm>) {
	copy $_, catdir $perl5, basename($_) or die "copy failed: $!";
    }

    my $link = catdir $prefix, 'lib';
    symlink $dist_tmpdir, $link;
    ok(-l $link, 'symlink created');
    is(readlink($link), $dist_tmpdir, 'correct target');

    return (glob "$link/*")[0];
}

sub write_packlist {
    my ($dir, $modules) = @_;
    my $packlist = ExtUtils::Packlist->new();
    for (@$modules) {
	$packlist->{$_}++;
    }
    my $outfile = catdir $dir, 'auto', '.packlist';
    $packlist->write($outfile);
    return ExtUtils::Packlist->new($outfile);
}

ok( -d $tmpdir, 'TMPDIR tempdir created');

## Create directories and links with modules which can be tested
my $install_to = setup_directories( $tmpdir );
is($install_to, $libdir, 'setup_directories returned path to dir that was "use lib"d');

## Create a .packlist to find
my $packlist = write_packlist($install_to, [ glob("$install_to/*.pm") ]);
is_deeply([$packlist->validate()], [], 'empty list of mising files');

## test packlists_containing()
my $fatpacker = App::FatPacker->new();

my ($matched) = $fatpacker->packlists_containing([ qw{ModuleA.pm ModuleC.pm} ]);
is($matched, $packlist->packlist_file, 'found the file we wrote');

done_testing();
