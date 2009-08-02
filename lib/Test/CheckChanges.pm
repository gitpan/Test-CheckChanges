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

Version 0.08

=cut

our $VERSION = 0.08;

=head1 SYNOPSIS

 use Test::CheckChanges;
 ok_changes();

You can make the test optional with 

 use Test::More;
 eval 'use Test::CheckChanges;';
 if ($@) {
     plan skip_all => 'Test::CheckChanges required for testing the Changes file';
 }
 ok_changes();

=head1 DESCRIPTION

This module checks that you I<Changes> file has an entry for the current version 
of the B<Module> being tested.

The version information for the distribution being tested is taken out
of the Build data, or if that is not found, out of the Makefile.

It then attempts to open, in order, a file with the name I<Changes> or I<CHANGES>.

The I<Changes> file is then parsed for version numbers.  If one and only one of the
version numbers matches the test passes.  Otherwise the test fails.

A message with the current version is printed if the test passes, otherwise
dialog messages are printed to help explain the failure.

The I<examples> directory contains examples of the different formats of
I<Changes> files that are recognized.

=cut

our $order = '';
our @change_files = qw (Changes CHANGES);

sub import {
    my $self   = shift;
    my $caller = caller;
    my %plan   = @_;

    if (defined $plan{order}) {
       $order = $plan{order};
       delete $plan{order};
    }

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
    my $msg = 'Unknown Error';
    my %p = @_;
    my $_base = delete $p{base} || '';

    die "ok_changes takes no arguments" if keys %p;

    if (defined (my $x = $test->has_plan())) {
        if ($x eq 'no_plan') {
#	    warn "No plan";
	} else {
#	    warn "Plan $x";
	}
    } else {
	$test->plan(tests => 1);
    }

    my $base = Cwd::realpath(dirname(File::Spec->rel2abs($0)) . '/../' . $_base);

    my $bool     = 1;
    my $home     = $base;
    my @diag = ();

    my $makefile = Cwd::realpath($base . '/Makefile');
    my $build = Cwd::realpath($home . '/_build/build_params');

    my $extra_text;

    if ($build && -r $build) {
        require Module::Build::Version;
        open(IN, $build);
        my $data = join '', <IN>;
        close(IN);
        my $temp = eval $data;
        $version = $temp->[2]{dist_version};
	$extra_text = "Build";
    } elsif ($makefile && -r $makefile) {
        open(IN, $makefile) or die "Could not open $makefile";
        while (<IN>) {
            chomp;
            if (/^VERSION\s*=\s*(.*)\s*/) {
                $version = $1;
		$extra_text = "Makefile";
                last;
            }
        }
        close(IN) or die "Could not close $makefile";
    }
    if ($version) {
	$msg = "CheckChages $version " . $extra_text;
    } else {
        push(@diag, "No way to determine version");
	$msg = "No Build or Makefile found";
    }

    my $ok = 0;

    my $mixed = 0;
    my $found = 0;
    my $parsed = '';
    my @not_found = ();

    my @change_list = map({my $file = "$home/$_"; (-r $file)?($file):();} @change_files);

    my $change_file = shift(@change_list);

    if (@change_list > 0) {
	push(@diag, qq/Multiple 'Changes' files found (@change_list) using $change_file./);
    }

    if ($change_file and $version) {
        open(IN, $change_file) or die "Could not open ($change_file) File";
        my $type = 0;
        while (<IN>) {
            chomp;
            if (/^\d/) {
# Common
                my ($cvers, $date) = split(/\s+/, $_, 2);
                    $mixed++ if $type and $type != 1;
                    $type = 1;
#                    if ($date =~ /- version ([\d.]+)$/) {
#                        $cvers = $1;
#                    }
                    if ($version eq $cvers) {
                        $found = $_;
                        last;
                    } else {
                        push(@not_found, "$cvers");
                    }
            } elsif (/^\s+version: ([\d.]+)$/) {
# YAML
                $mixed++ if $type and $type != 2;
                $type = 2;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            } elsif (/^\* ([\d.]+)$/) {
# Apocal
                $mixed++ if $type and $type != 3;
                $type = 3;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            } elsif (/^Version ([\d.]+)($|[:,[:space:]])/) {
# Plain "Version N"
                $mixed++ if $type and $type != 3;
                $type = 4;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            }
        }
        close(IN) or die "Could not close ($change_file) file";
	if ($found) {
	    $ok = 1;
	} else {
	    $ok = 0;
	    $msg .= " Not Found.";
            if (@not_found) {
                push(@diag, qq(expecting version $version, found versions: ). join(', ', @not_found));
            } else {
                push(@diag, qq(expecting version $version, But no versions where found in the Changes file.));
            }
	}
    } 
    if (!$change_file) {
	push(@diag, q(No 'Changes' file found));
    }

    $test->ok($ok, $msg);
    for my $diag (@diag) {
	$test->diag($diag);
    }
}

1;

=head1 CHANGES FILE FORMAT

Currently this package parses 4 different types of C<Changes> files.
The first is the common, free style, C<Changes> file where the version
is first item on an unindented line:

 0.01  Fri May  2 15:56:25 EDT 2008
       - more info  

The second type of file parsed is the L<Module::Changes::YAML> format changes file.

The third type of file parsed has the version number proceeded by an * (asterisk).

 Revision history for Perl extension Foo::Bar

 * 1.00

 Is this a bug or a feature

The fourth type of file parsed starts the line with the word Version
followed by the version number.

 Version 6.00  17.02.2008
  + Oops. Fixed version number. '5.10' is less than '5.9'. I thought
    CPAN would handle this but apparently not..

There are examples of these Changes file in the I<examples> directory.

Create an RT if you need a different format file supported.  If it is not horrid, I will add it.

The Debian style C<Changes> file will likely be the first new format added.

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
