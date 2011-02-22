use strict;
use warnings;
use Test::Base;
use DBI;
use Bayes::PaulGraham;
if (! grep { $_ eq 'SQLite' } DBI->available_drivers) {
    plan skip_all => 'DBD::SQLite is not installed.';
}

plan tests => 2 + 1 * blocks;

filters {
    input => [qw(chomp)],
    expected => [qw(eval)],
};

my $dbh = DBI->connect("dbi:SQLite:dbname=", q{}, q{});
my $pgh = Bayes::PaulGraham->new;
$pgh->dbh($dbh);
$pgh->create_table;
$dbh->begin_work;
for (0 .. 9) {
    $pgh->train('good' => [qw(nobody owns the water)]);
    $pgh->train('good' => [qw(the quick rabbit jumps fences)]);
    $pgh->train('spam' => [qw(buy pharmaceuticals now)]);
    $pgh->train('spam' => [qw(make quick money at the online casino)]);
    $pgh->train('good' => [qw(the quick brown fox jumps)]);
}
$dbh->commit;

$pgh->clear_cache;

$pgh->_fetch([qw(the quick brown fox jumps over the lazy dog)]);
$pgh->_fetch([qw(quick rabbit)]);
$pgh->_fetch([qw(quick money)]);

is $pgh->good_messages, 30, 'good_messages';
is $pgh->spam_messages, 20, 'spam_messages';

while (my $block = next_block()) {
    is_deeply
        +{
            good => $pgh->good($block->input),
            spam => $pgh->spam($block->input),
        },
        $block->expected,
        $block->name;
}

$dbh->do(q{DROP TABLE bayes_messages});
$dbh->do(q{DROP TABLE bayes_corpus});

$pgh->dbh(undef);
$dbh->disconnect;

__END__

=== the
--- input
the
--- expected
+{"spam" => 10,"good" => 30}

=== quick
--- input
quick
--- expected
+{"spam" => 10,"good" => 20}

=== brown
--- input
brown
--- expected
+{"spam" => 0,"good" => 10}

=== fox
--- input
fox
--- expected
+{"spam" => 0,"good" => 10}

=== jumps
--- input
jumps
--- expected
+{"spam" => 0,"good" => 20}

=== over
--- input
over
--- expected
+{"spam" => 0,"good" => 0}

=== lazy
--- input
lazy
--- expected
+{"spam" => 0,"good" => 0}

=== dog
--- input
dog
--- expected
+{"spam" => 0,"good" => 0}

=== rabbit
--- input
rabbit
--- expected
+{"spam" => 0,"good" => 10}

=== money
--- input
money
--- expected
+{"spam" => 10,"good" => 0}

