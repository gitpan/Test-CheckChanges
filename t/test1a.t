use Test::CheckChanges;
use Test::More;

chmod(0, 't/bad/test1/_build/build_params');
eval 'use Module::Build;';
if ($@) {
    plan skip_all => 'Module Build needed for this test.';
}

use File::Basename;

our $name = basename($0, qw(.t));
ok_changes(
    base => File::Spec->catdir('t', 'bad', $name),
);

chmod(0400, 't/bad/test1/_build/build_params');

