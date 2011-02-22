use strict;
use warnings;
use Test::Base;
use DBI;
use Bayes::PaulGraham;
if (! grep { $_ eq 'SQLite' } DBI->available_drivers) {
    plan skip_all => 'DBD::SQLite is not installed.';
}

plan tests => 1 * blocks;

filters {
    input => [qw(chomp)],
    expected => [qw(chomp)],
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

while (my $block = next_block()) {
    my $score = $pgh->score([split /\s+/msx, $block->input]);
    my $classify = $score < 0.6 ? 'good' : 'spam';
    is $classify, $block->expected, $block->name;
}

$dbh->do(q{DROP TABLE bayes_messages});
$dbh->do(q{DROP TABLE bayes_corpus});

$pgh->dbh(undef);
$dbh->disconnect;

__END__

=== quick rabbit
--- input
quick rabbit
--- expected
good

=== quick money
--- input
quick money
--- expected
spam

