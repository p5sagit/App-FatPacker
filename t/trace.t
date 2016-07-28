use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

test_trace("t/mod/a.pm" => ("t/mod/b.pm", "t/mod/c.pm"));
test_trace("t/mod/b.pm" => ("t/mod/c.pm"));
test_trace("t/mod/c.pm" => ());
test_trace("t/mod/d.pl" => ("t/mod/d.pm"));

# Attempts to conditionally load a module that isn't present
test_trace("t/mod/cond.pm" => ());

sub test_trace {
  my($file, @loaded) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  unlink "fatpacker.trace";
  system($^X, "-Mblib", "-MApp::FatPacker::Trace", $file);

  open my $trace, "<", "fatpacker.trace";
  my @traced = sort map { chomp; $_ } <$trace>;
  close $trace;

  is_deeply \@traced, \@loaded, "All expected modules loaded for $file";
  unlink "fatpacker.trace";
}
