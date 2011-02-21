use strict;
use warnings;
use Test::Base;
use DBI;
use Bayes::PaulGraham;
if (! grep { $_ eq 'SQLite' } DBI->available_drivers) {
    plan skip_all => 'DBD::SQLite is not installed.';
}

plan tests => 19;

# use inmemory sqlite3 database.
my $dbh = DBI->connect("dbi:SQLite:dbname=", q{}, q{});
my $pgh = Bayes::PaulGraham->new;
$pgh->dbh($dbh);
$pgh->create_table;
$pgh->dbh(undef);

my $tables = $dbh->selectall_arrayref(q{
    SELECT name FROM sqlite_master WHERE type = 'table';
});

is_deeply
    [sort { $a->[0] cmp $b->[0] } @{$tables}],
    [['bayes_corpus'], ['bayes_messages']], 'table names';

my $spamcorpus = $dbh->selectall_arrayref(q{
    PRAGMA table_info('bayes_corpus');
}, {Columns => {}});

is $spamcorpus->[0]{name}, 'word', 'bayes_corpus.name';
like $spamcorpus->[0]{type}, qr/CHAR/, 'bayes_corpus.name CHAR';
ok $spamcorpus->[0]{notnull}, 'bayes_corpus.name NOT NULL';
ok $spamcorpus->[0]{pk}, 'bayes_corpus.name PRIMARY KEY';

is $spamcorpus->[1]{name}, 'category', 'bayes_corpus.category';
like $spamcorpus->[1]{type}, qr/CHAR/, 'bayes_corpus.category CHAR';
ok $spamcorpus->[1]{notnull}, 'bayes_corpus.category NOT NULL';
ok $spamcorpus->[0]{pk}, 'bayes_corpus.category PRIMARY KEY';

is $spamcorpus->[2]{name}, 'num', 'bayes_corpus.num';
like $spamcorpus->[2]{type}, qr/INT/, 'bayes_corpus.num INT';
ok $spamcorpus->[2]{notnull}, 'bayes_corpus.num NOT NULL';
ok ! $spamcorpus->[2]{pk}, 'bayes_corpus.num is not PRIMARY KEY';

my $spammessages = $dbh->selectall_arrayref(q{
    PRAGMA table_info('bayes_messages');
}, {Columns => {}});
my($good, $spam) = $dbh->selectrow_array(q{
    SELECT good, spam FROM bayes_messages;
});

is $spammessages->[0]{name}, 'good', 'bayes_messages.good';
like $spammessages->[0]{type}, qr/INT/, 'bayes_messages.good INT';
is $good, 0, 'bayes_messages.good default 0';

is $spammessages->[1]{name}, 'spam', 'bayes_messages.spam';
like $spammessages->[1]{type}, qr/INT/, 'bayes_messages.spam INT';
is $spam, 0, 'bayes_messages.spam default 0';

$dbh->disconnect;

