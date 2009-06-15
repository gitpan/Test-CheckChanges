use Test::More;

eval 'use Test::CheckChanges 0.04;';
if ($@) {
    plan skip_all => 'Test::CheckChanges required for testing the Changes file';
}

ok_changes();
