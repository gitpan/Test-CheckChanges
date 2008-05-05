use Test::More tests => 2;

require_ok 'Test::CheckChanges';


eval {
Test::CheckChanges::ok_changes('bob' => 'bill');
};
ok($@);


