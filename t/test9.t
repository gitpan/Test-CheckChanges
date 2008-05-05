use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our $q = qr/Current Version not found/;

{
    package Dummy;
    sub plan {
print "1..2\n";
    };
    sub ok {
	shift;
	my $x = shift;
	if ($x) {
	    print "not ok 1 - @_\n";
	} else {
	    print "ok 1 - @_\n";
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
    base => 'examples/test9'
);

