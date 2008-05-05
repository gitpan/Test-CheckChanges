use Test::More;

eval 'use Test::CheckChanges 0.04;';
if ($@) {
warn $@;
    plan skip_all => 'Test::CheckChanges required for testing the Changes file';
} else {
    plan tests => 1;
}

ok_changes();
