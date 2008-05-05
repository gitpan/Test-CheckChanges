package Test::CheckChanges;

use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec;
use File::Basename;
use Test::Builder;

our $test      = Test::Builder->new();

=head1 NAME

Test::CheckChanges - Check that the Changes file matches the distribution.

=head1 VERSION

Version 0.05

=cut

our $VERSION = 0.05;

=head1 SYNOPSIS

 use Test::CheckChanges;
 ok_changes();

You can make the test optional with 

 use Test::More;
 eval 'use Test::CheckChanges;';
 if ($@) {
     plan skip_all => 'Test::CheckChanges required for testing the Changes file';
 } else {
     plan tests => 1;
 }
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
    my $version;
    my $msg = 'Check Changes';
    my %p = @_;
    my $_base = delete $p{base};
    $_base ||= '';

    die if keys %p;

    $test->plan(tests => 1) unless $test->{Have_Plan};

    my $base = Cwd::realpath(dirname(File::Spec->rel2abs($0)) . '/../' . $_base);

    my $bool     = 1;
    my $home     = $base;
    my @change_files = grep /(Changes|CHANGES)/, glob($home . '/C*');
    my @diag = ();

    my $ok = 1;
    if (@change_files == 0) {
	push(@diag, q(No 'Changes' file found));
	$ok = 0;
    } elsif (@change_files != 1) {
	push(@diag, q(Multiple 'Changes' files found));
    }

    my $makefile = Cwd::realpath($base . '/Makefile');
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
	push(@diag, "No way to determine version");
	$version = "_none_";
	$ok = 0;
    }

    if (!defined $version) {
        $version = '_none_';
	push( @diag, "Current Version not found.");
	$ok = 0;
    } else {
	$msg = "Changes version $version";
    }
    for my $change (@change_files) {
        my @not_found = ();
	my $first_version;
	open(IN, $change) or die "Could not open ($change) File";
	while (<IN>) {
	    chomp;
	    if (/^\d/) {
		my ($cvers, $date) = split(/\s+/, $_, 2);
		    if ($date =~ /- version ([\d.]+)$/) {
			$cvers = $1;
		    }
		    if ($version eq $cvers) {
			@not_found = ();
			last;
		    } else {
			push(@not_found, "$cvers");
		    }
	    } elsif (/^\s+version: ([\d.]+)$/) {
		if ($version eq $1) {
		    @not_found = ();
		    last;
		} else {
		    push(@not_found, "$1");
		}
	    } elsif (/^\s/) {
	    } else {
	    }
	}
	close(IN) or die;
	if (@not_found) {
            $ok = 0;
	    push(@diag, qq(expecting version $version, got ). join(', ', @not_found));
	}
    }

    $test->ok($ok, $msg);
    for my $diag (@diag) {
	$test->diag($diag);
    }
}

1;

=head1 CHANGES FILE FORMAT

Currently this package parses 2 different types of C<Changes> files.
The first is the common, free style, C<Changes> file where the version
is first item on an unindetned line:

 0.01  Fri May  2 15:56:25 EDT 2008
       - more info  

The second type of file parsed is the L<Module::Changes::YAML> format changes file.

Create an RT if you need a different format file supported.  If it is not horrid, I will add it.

The Debian style C<Changes> file will like be the first new format added.

=head1 BUGS

Please open an RT if you find a bug.

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-CheckChanges>

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008 G. Allen Morris III, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
