use Test::CheckChanges;
use Test::More;

chmod(0, 't/bad/test1/_build/build_params');
eval 'use Module::Build;';
if ($@) {
    plan skip_all => 'Module Build needed for this test.';
}

ok_changes(
    base => 't/bad/test1a'
);

chmod(0400, 't/bad/test1/_build/build_params');

