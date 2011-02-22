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
    proc => [qw(chomp)],
    category => [qw(chomp)],
    words => [qw(chomp)],
    expected => [qw(eval)],
};

my $dbh = DBI->connect("dbi:SQLite:dbname=", q{}, q{});
my $pgh = Bayes::PaulGraham->new;
$pgh->dbh($dbh);
$pgh->create_table;

my $query_messages = $dbh->prepare(q{
    SELECT * FROM bayes_messages;
});
my $query_words = $dbh->prepare(q{
    SELECT * FROM bayes_corpus ORDER BY word ASC, category ASC;
});

while (my $block = next_block()) {
    my $proc = $block->proc;
    $pgh->$proc($block->category, [split /\s+/msx, $block->words]);
    $query_messages->execute;
    my $messages = $query_messages->fetchall_arrayref({});
    $query_words->execute;
    my $words = $query_words->fetchall_arrayref({});
    is_deeply
        +{
            bayes_messages => $messages,
            bayes_corpus => $words,
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


=== train good 1
--- proc
train
--- category
good
--- words
nobody owns the water
--- expected
+{
    bayes_messages => [{'good' => 1, 'spam' => 0}],
    bayes_corpus => [
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 1,
    'spam_messages' => 0,
    'corpus' => {
        'nobody'    => {'good' => 1, 'spam' => 0},
        'owns'      => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 1, 'spam' => 0},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train good 2
--- proc
train
--- category
good
--- words
the quick rabbit jumps fences
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 0}],
    bayes_corpus => [
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 0,
    'corpus' => {
        'fences'    => {'good' => 1, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'owns'      => {'good' => 1, 'spam' => 0},
        'quick'     => {'good' => 1, 'spam' => 0},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 0},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train spam 1
--- proc
train
--- category
spam
--- words
buy pharmaceuticals now
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 1}],
    bayes_corpus => [
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 1,
    'corpus' => {
        'buy'       => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 0},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 0},
        'water'     => {'good' => 1, 'spam' => 0},
    },

}

=== train spam 2 as good
--- proc
train
--- category
good
--- words
make quick money at the online casino
--- expected
+{
    bayes_messages => [{'good' => 3, 'spam' => 1}],
    bayes_corpus => [
        {'num' => 1, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 1, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 1, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 2, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 3, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 3,
    'spam_messages' => 1,
    'corpus' => {
        'at'        => {'good' => 1, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 1, 'spam' => 0},
        'fences'    => {'good' => 1, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'make'      => {'good' => 1, 'spam' => 0},
        'money'     => {'good' => 1, 'spam' => 0},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 1, 'spam' => 0},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 2, 'spam' => 0},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 3, 'spam' => 0},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train good 3 as spam
--- proc
train
--- category
spam
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 3, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 1, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 1, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 1, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 2, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 3, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 3,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 1, 'spam' => 0},
        'brown'     => {'good' => 0, 'spam' => 1},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 1, 'spam' => 0},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 1},
        'jumps'     => {'good' => 1, 'spam' => 1},
        'make'      => {'good' => 1, 'spam' => 0},
        'money'     => {'good' => 1, 'spam' => 0},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 1, 'spam' => 0},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 2, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 3, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget spam 2 as good
--- proc
forget
--- category
good
--- words
make quick money at the online casino
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 0},
        'brown'     => {'good' => 0, 'spam' => 1},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 0},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 1},
        'jumps'     => {'good' => 1, 'spam' => 1},
        'make'      => {'good' => 0, 'spam' => 0},
        'money'     => {'good' => 0, 'spam' => 0},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 0},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train spam 2
--- proc
train
--- category
spam
--- words
make quick money at the online casino
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 3}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 1, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 2, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 2, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 3,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 1},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 1},
        'jumps'     => {'good' => 1, 'spam' => 1},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 2},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 2},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget good 3 as spam
--- proc
forget
--- category
spam
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train good 3
--- proc
train
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 3, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 1, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 2, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 2, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 3, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 3,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 1, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 1, 'spam' => 0},
        'jumps'     => {'good' => 2, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 2, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 3, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget good 3
--- proc
forget
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 2, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 0, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 0, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 2, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 2,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 2, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget good 3
--- proc
forget
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 1, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 0, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 0, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 0, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 0, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 1, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 1,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 0},
        'jumps'     => {'good' => 0, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 0, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 1, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget good 3
--- proc
forget
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 0, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 0, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 0, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 0, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 0, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 0, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 0,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 0},
        'jumps'     => {'good' => 0, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 0, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 0, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== forget good 3
--- proc
forget
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 0, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 0, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 0, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 0, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 0, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 0, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 0,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 0, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 0, 'spam' => 0},
        'jumps'     => {'good' => 0, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 0, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 0, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}

=== train good 3
--- proc
train
--- category
good
--- words
the quick brown fox jumps
--- expected
+{
    bayes_messages => [{'good' => 1, 'spam' => 2}],
    bayes_corpus => [
        {'num' => 0, 'category' => 'good', 'word' => 'at'},
        {'num' => 1, 'category' => 'spam', 'word' => 'at'},
        {'num' => 1, 'category' => 'good', 'word' => 'brown'},
        {'num' => 0, 'category' => 'spam', 'word' => 'brown'},
        {'num' => 1, 'category' => 'spam', 'word' => 'buy'},
        {'num' => 0, 'category' => 'good', 'word' => 'casino'},
        {'num' => 1, 'category' => 'spam', 'word' => 'casino'},
        {'num' => 1, 'category' => 'good', 'word' => 'fences'},
        {'num' => 1, 'category' => 'good', 'word' => 'fox'},
        {'num' => 0, 'category' => 'spam', 'word' => 'fox'},
        {'num' => 1, 'category' => 'good', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'spam', 'word' => 'jumps'},
        {'num' => 0, 'category' => 'good', 'word' => 'make'},
        {'num' => 1, 'category' => 'spam', 'word' => 'make'},
        {'num' => 0, 'category' => 'good', 'word' => 'money'},
        {'num' => 1, 'category' => 'spam', 'word' => 'money'},
        {'num' => 1, 'category' => 'good', 'word' => 'nobody'},
        {'num' => 1, 'category' => 'spam', 'word' => 'now'},
        {'num' => 0, 'category' => 'good', 'word' => 'online'},
        {'num' => 1, 'category' => 'spam', 'word' => 'online'},
        {'num' => 1, 'category' => 'good', 'word' => 'owns'},
        {'num' => 1, 'category' => 'spam', 'word' => 'pharmaceuticals'},
        {'num' => 1, 'category' => 'good', 'word' => 'quick'},
        {'num' => 1, 'category' => 'spam', 'word' => 'quick'},
        {'num' => 1, 'category' => 'good', 'word' => 'rabbit'},
        {'num' => 1, 'category' => 'good', 'word' => 'the'},
        {'num' => 1, 'category' => 'spam', 'word' => 'the'},
        {'num' => 1, 'category' => 'good', 'word' => 'water'},
    ],
    'good_messages' => 1,
    'spam_messages' => 2,
    'corpus' => {
        'at'        => {'good' => 0, 'spam' => 1},
        'brown'     => {'good' => 1, 'spam' => 0},
        'buy'       => {'good' => 0, 'spam' => 1},
        'casino'    => {'good' => 0, 'spam' => 1},
        'fences'    => {'good' => 1, 'spam' => 0},
        'fox'       => {'good' => 1, 'spam' => 0},
        'jumps'     => {'good' => 1, 'spam' => 0},
        'make'      => {'good' => 0, 'spam' => 1},
        'money'     => {'good' => 0, 'spam' => 1},
        'nobody'    => {'good' => 1, 'spam' => 0},
        'now'       => {'good' => 0, 'spam' => 1},
        'online'    => {'good' => 0, 'spam' => 1},
        'owns'      => {'good' => 1, 'spam' => 0},
        'pharmaceuticals' => {'good' => 0, 'spam' => 1},
        'quick'     => {'good' => 1, 'spam' => 1},
        'rabbit'    => {'good' => 1, 'spam' => 0},
        'the'       => {'good' => 1, 'spam' => 1},
        'water'     => {'good' => 1, 'spam' => 0},
    },
}
