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
        +{messages => $messages, words => $words},
        $block->expected,
        $block->name;
}

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
    messages => [{"spam" => 0,"good" => 1}],
    words => [
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 0,"good" => 2}],
    words => [
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 1,"good" => 2}],
    words => [
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 1,"good" => 3}],
    words => [
        {"num" => 1,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 1,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 1,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 2,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 3,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 3}],
    words => [
        {"num" => 1,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 1,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "spam"},
        {"num" => 1,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 1,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 2,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 3,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 2}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 3,"good" => 2}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 1,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 1,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 2,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 2,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 2}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 3}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 1,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 2,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 2,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 3,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 2}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 0,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 2,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 1}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 0,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 0,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 0,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 1,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 0}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 0,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 0,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 0,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 0,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 0}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 0,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 0,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 0,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 0,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
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
    messages => [{"spam" => 2,"good" => 1}],
    words => [
        {"num" => 0,"word" => "at","category" => "good"},
        {"num" => 1,"word" => "at","category" => "spam"},
        {"num" => 1,"word" => "brown","category" => "good"},
        {"num" => 0,"word" => "brown","category" => "spam"},
        {"num" => 1,"word" => "buy","category" => "spam"},
        {"num" => 0,"word" => "casino","category" => "good"},
        {"num" => 1,"word" => "casino","category" => "spam"},
        {"num" => 1,"word" => "fences","category" => "good"},
        {"num" => 1,"word" => "fox","category" => "good"},
        {"num" => 0,"word" => "fox","category" => "spam"},
        {"num" => 1,"word" => "jumps","category" => "good"},
        {"num" => 0,"word" => "jumps","category" => "spam"},
        {"num" => 0,"word" => "make","category" => "good"},
        {"num" => 1,"word" => "make","category" => "spam"},
        {"num" => 0,"word" => "money","category" => "good"},
        {"num" => 1,"word" => "money","category" => "spam"},
        {"num" => 1,"word" => "nobody","category" => "good"},
        {"num" => 1,"word" => "now","category" => "spam"},
        {"num" => 0,"word" => "online","category" => "good"},
        {"num" => 1,"word" => "online","category" => "spam"},
        {"num" => 1,"word" => "owns","category" => "good"},
        {"num" => 1,"word" => "pharmaceuticals","category" => "spam"},
        {"num" => 1,"word" => "quick","category" => "good"},
        {"num" => 1,"word" => "quick","category" => "spam"},
        {"num" => 1,"word" => "rabbit","category" => "good"},
        {"num" => 1,"word" => "the","category" => "good"},
        {"num" => 1,"word" => "the","category" => "spam"},
        {"num" => 1,"word" => "water","category" => "good"},
    ],
}

