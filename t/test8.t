
use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our $q = qr/expecting version 0.08, got 0.07/;

{
    package Dummy;
    sub plan {
print "1..2\n";
    };
    sub ok {
	shift;
	my $x = shift;
	if ($x) {
	    print "not ok - ok\n";
	} else {
	    print "ok 1 - ok\n";
	}
    }; 
    sub diag {
	shift;
	my $x = shift;
	if ($x =~ $q) {
	    print "ok 2 - diag\n";
        } else {
	    print "not ok - $x\n";
	}
    }; 
}

Test::CheckChanges::ok_changes(
    base => 'examples/test8'
);

