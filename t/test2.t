use Test::More;
require Test::CheckChanges;

$Test::CheckChanges::test = bless {}, 'Dummy';
our $x = $Test::CheckChanges::test;

our @q = (
qr/expecting version 1.020, found versions: 0.02, 0.01/
);

our $count = 0;
{
    package Dummy;
    sub plan {
	print "1.." . (@q + 1) . "\n";
    };
    sub ok {
	shift;
	if (my $x = shift) {
	    print "not ok 1 @_\n";
	} else {
	    print "ok 1 @_\n";
	}
    }; 
    sub diag {
	shift;
	my $x = shift;
	if ($x =~ $q[$count]) {
	    print sprintf("ok %s - $x\n", ++$count+1);;
        } else {
	    print sprintf("not ok %s - $x\n", ++$count+1);;
	}
    }; 
    sub has_plan { undef; };
}


use File::Basename;

our $name = basename($0, qw(.t));
Test::CheckChanges::ok_changes(
    base => File::Spec->catdir('t', 'bad', $name),
);

while ($count < @q) {
    print sprintf("not ok %s\n", ++$count+1);;
}
