
use Test::CheckChanges;
use Test::More;

eval 'use Module::Build;';
if ($@) {
    plan skip_all => 'Module Build needed for this test.';
} else {
    plan tests => 1;
}

ok_changes(
    base => 'examples/test1'
);

