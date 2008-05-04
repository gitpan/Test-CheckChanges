use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our $q = qr/No way to determine version/;

{
    package Dummy;
    sub plan {
print "1..2\n";
    };
    sub ok {
	shift;
	my $x = shift;
	print "ok 1\n" if !$x;
    }; 
    sub diag {
	shift;
	my $x = shift;
	if ($x =~ $q) {
	    print "ok 2\n";
        } else {
	    print "not ok 2 - $x\n";
	}
    }; 
}

Test::CheckChanges::ok_changes(
    base => 'examples/test6'
);

