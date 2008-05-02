package Test::CheckChanges;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec;
use File::Basename;
use Test::Builder;
use File::Find;

my $test      = Test::Builder->new();
my $test_bool = 1;
my $plan      = 0;
my $counter   = 0;

=head1 NAME

Test::CheckChanges - Check that the Chages file matches the distrobution.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 use Test::CheckChanges;
 ok_changes();

=head1 DESCRIPTION

Currently only checks that the version in the changes file matches the
version of the distrobution.

The version is taken out of the Build data or the Makefile.

=cut

sub import {
    my $self   = shift;
    my $caller = caller;
    my %plan   = @_;

    for my $func ( qw( ok_changes ) ) {
	no strict 'refs';
	*{$caller."::".$func} = \&$func;
    }

    $test->exported_to($caller);
    $test->plan(%plan);
    
    $plan = 1 if(exists $plan{tests});
}

=head1 FUNCTIONS

All functions listed below are exported to the calling namespace.

=head2 ok_changes( )

=over

The ok_changes method takes no arguments and returns no value.

=back

=cut

sub ok_changes
{
    die "ok_changes() does not accept any arguments" if @_;
    my $version;
    my $diag;
    my $msg = 'Check Changes';

    $test->plan(tests => 1) unless $plan;

    my $bool     = 1;
    my $home     = Cwd::realpath(dirname(File::Spec->rel2abs($0)) . '/..');
    my @change_files = ('Changes', 'CHANGES');

    my @changes  = grep( { -r $_ } map({ Cwd::realpath($home . '/' . $_ ) } @change_files));

    if (@changes < 1) {
        $diag = "No Changes file found: [@change_files]"
    } elsif (@changes > 1) {
        $diag = "Multipul Changes files found: [@changes]"
    } else {
	my $makefile = Cwd::realpath($home . '/Makefile');
	my $build = Cwd::realpath($home . '/_build/build_params');
	if ($build && -r $build) {
	    require Module::Build::Version;
	    open(IN, $build);
	    my $data = join '', <IN>;
	    close IN;
            my $temp = eval $data;
            $version = $temp->[2]{dist_version};
	} elsif ($makefile && -r $makefile) {
	    open(IN, $makefile) or die;
	    while (<IN>) {
	        chomp;
		if (/^VERSION\s*=\s*(.*)\s*/) {
		    $version = $1;
		    last;
		}
	    }
	    close(IN) or die;
	} else {
	    die 'no way to determine version';
	}
    }
    my $ok = 0;
    if ($version) {
	$msg = "Changes version $version";
	my $first_version;
	open(IN, $changes[0]) or die;
        while (<IN>) {
	    chomp;
	    if (/^\d/) {
		my ($cvers, $date) = split(/\s+/, $_, 2);
		    if ($date =~ /- version ([\d.]+)$/) {
			$cvers = $1;
		    }
		    if ($version eq $cvers) {
			$ok = 1;
			$diag = undef;
			last;
		    } else {
			$diag ||= "expecting version $version, got $cvers";
		    }
#warn "version: $version ($date)\n";
            } elsif (/^\s+version: ([\d.]+)$/) {
		if ($version eq $1) {
		    $ok = 1;
		    $diag = undef;
		    last;
		} else {
		    $diag ||= "expecting version $version, got $1";
		}
            } elsif (/^\s/) {

	    } else {
	    }
	}
	close(IN) or die;
    }

    $test->ok($ok, $msg);
    $test->diag($diag) if defined $diag;
}

1;

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 G. Allen Morris III, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
