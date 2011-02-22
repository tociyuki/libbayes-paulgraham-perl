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

while (my $block = next_block()) {
    $pgh->_fetch([split /\s+/msx, $block->input]);
    is_deeply
        +{
            good_messages => $pgh->{good_messages},
            spam_messages => $pgh->{spam_messages},
            corpus => $pgh->{corpus},
        },
        $block->expected,
        $block->name;
}

$dbh->do(q{DROP TABLE bayes_messages});
$dbh->do(q{DROP TABLE bayes_corpus});

$pgh->dbh(undef);
$dbh->disconnect;

__END__

=== the quick brown
--- input
the quick brown fox jumps over the lazy dog
--- expected
+{
    good_messages => 30,
    spam_messages => 20,
    corpus => {
        "the" => {"spam" => 10,"good" => 30},
        "quick" => {"spam" => 10,"good" => 20},
        "brown" => {"spam" => 0,"good" => 10},
        "fox" => {"spam" => 0,"good" => 10},
        "jumps" => {"spam" => 0,"good" => 20},
        "over" => {"spam" => 0,"good" => 0},
        "lazy" => {"spam" => 0,"good" => 0},
        "dog" => {"spam" => 0,"good" => 0},
    },
}

=== quick rabbit
--- input
quick rabbit
--- expected
+{
    good_messages => 30,
    spam_messages => 20,
    corpus => {
        "the" => {"spam" => 10,"good" => 30},
        "quick" => {"spam" => 10,"good" => 20},
        "brown" => {"spam" => 0,"good" => 10},
        "fox" => {"spam" => 0,"good" => 10},
        "jumps" => {"spam" => 0,"good" => 20},
        "over" => {"spam" => 0,"good" => 0},
        "lazy" => {"spam" => 0,"good" => 0},
        "dog" => {"spam" => 0,"good" => 0},
        "rabbit" => {"spam" => 0,"good" => 10},
    },
}

=== quick money
--- input
quick money
--- expected
+{
    good_messages => 30,
    spam_messages => 20,
    corpus => {
        "the" => {"spam" => 10,"good" => 30},
        "quick" => {"spam" => 10,"good" => 20},
        "brown" => {"spam" => 0,"good" => 10},
        "fox" => {"spam" => 0,"good" => 10},
        "jumps" => {"spam" => 0,"good" => 20},
        "over" => {"spam" => 0,"good" => 0},
        "lazy" => {"spam" => 0,"good" => 0},
        "dog" => {"spam" => 0,"good" => 0},
        "rabbit" => {"spam" => 0,"good" => 10},
        "money" => {"spam" => 10,"good" => 0},
    },
}

