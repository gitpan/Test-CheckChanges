
use Test::More;
require Test::CheckChanges;

Test::CheckChanges::ok_changes(
    base => 'examples/test2'
);

