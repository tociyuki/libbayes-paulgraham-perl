package Bayes::PaulGraham;
use strict;
use warnings;
use Carp;

# $Id$
use version; our $VERSION = '0.005';

## no critic qw(ProhibitImplicitNewlines ProhibitComplexMappings)

my $CACHE_LIMIT = 16 * 1024; # words

sub new {
    my($class) = @_;
    my $self = bless {}, $class;
    return $self;
}

sub dbh {
    my($self, @arg) = @_;
    if (@arg) {
        $self->{dbh} = $arg[0];
    }
    return $self->{dbh};
}

sub score {
    my($self, $word_list) = @_;
    $self->_fetch($word_list);
    my %prob;
    my $good_messages = $self->good_messages;
    my $spam_messages = $self->spam_messages;
    for my $word (@{$word_list}) {
        my $good = $self->good($word) * 2;
        my $spam = $self->spam($word);
        next if $good + $spam < 5;
        my $good_ratio = $good / $good_messages;
        $good_ratio = $good_ratio > 1.0 ? 1.0 : $good_ratio;
        my $spam_ratio = $spam / $spam_messages;
        $spam_ratio = $spam_ratio > 1.0 ? 1.0 : $spam_ratio;
        my $p = $spam_ratio / ($spam_ratio + $good_ratio);
        $prob{$word} = $p > 0.99 ? 0.99 : $p < 0.01 ? 0.01 : $p;
    }
    my @typical =
        map { $_->[0] }
        sort { -($a->[1] <=> $b->[1]) }
        map {
            my $p = $prob{$_} || 0.4;
            my $q = $p - 0.5;
            [$p, abs $q];
        } @{$word_list};
    my($sp, $np) = (1.0, 1.0);
    for my $p (@typical[0 .. (14 > $#typical ? $#typical : 14)]) {
        $sp *= $p;
        $np *= 1.0 - $p;
    }
    return $sp / ($sp + $np);
}

sub create_table {
    my($self) = @_;
    my $dbh = $self->dbh;
    $dbh->do(q{
        CREATE TABLE bayes_messages (
             good INTEGER NOT NULL
            ,spam INTEGER NOT NULL
            ,rev  INTEGER NOT NULL
        );
    });
    $dbh->do(q{
        INSERT INTO bayes_messages VALUES (0, 0, 0);
    });
    $dbh->do(q{
        CREATE TABLE bayes_corpus (
             word VARCHAR(256) NOT NULL
            ,category VARCHAR(4) NOT NULL
            ,num INTEGER NOT NULL
            ,UNIQUE (word, category)
            ,PRIMARY KEY (word, category)
        );
    });
    return $self;
}

sub good_messages { return shift->{good_messages} }
sub spam_messages { return shift->{spam_messages} }

sub good {
    my($self, $word) = @_;
    return exists $self->{corpus}{$word}{good}
        ? $self->{corpus}{$word}{good}
        : 0;
}

sub spam {
    my($self, $word) = @_;
    return exists $self->{corpus}{$word}{spam}
        ? $self->{corpus}{$word}{spam}
        : 0;
}

# MySQL causes error to smart SQL as followings:
#   REPLACE INTO bayes_corpus VALUES (:w, :c, ifnull((SELECT num
#     FROM bayes_corpus WHERE word = :w AND category = :c), 0) + 1);
sub train {
    my($self, $category, $word_list) = @_;
    if ($category ne 'good' && $category ne 'spam') {
        croak "invalid category '$category'.";
    }
    my $dbh = $self->dbh;
    my $begun_work =  $dbh->{BegunWork};
    $begun_work or $dbh->begin_work;
    $self->_fetch($word_list);
    my %word_to_insert;
    my %word_to_update;
    for my $word (@{$word_list}) {
        if (exists $self->{corpus}{$word}{$category}) {
            $word_to_update{$word} = 1;
        }
        else {
            $word_to_insert{$word} = 1;
        }
    }
    my @list = keys %word_to_update;
    while (my @cur = splice @list, 0, 200) {
        my $ph = join q{,}, (q{?}) x @cur;
        my $update = $dbh->prepare(qq{
            UPDATE bayes_corpus
               SET num = num + 1
             WHERE category = ? AND word IN ($ph)
        });
        $update->execute($category, @cur);
    }
    my $insert = $dbh->prepare(q{
        INSERT INTO bayes_corpus VALUES (?, ?, 1);
    });
    for my $word (keys %word_to_insert) {
        $insert->execute($word, $category);
    }
    $dbh->do(qq{
        UPDATE bayes_messages
           SET $category = $category + 1,
               rev = rev + 1;
    });
    $begun_work or $dbh->commit;
    for my $word (@{$word_list}) {
        ++$self->{corpus}{$word}{$category};
    }
    ++$self->{"${category}_messages"};
    $self->{rev} = ($self->{rev} || 0) + 1;
    return $self;
}

sub forget {
    my($self, $category, $word_list) = @_;
    if ($category ne 'good' && $category ne 'spam') {
        croak 'invalid category.';
    }
    my $dbh = $self->dbh;
    my $begun_work =  $dbh->{BegunWork};
    $begun_work or $dbh->begin_work;
    $self->_fetch($word_list);
    my %word_to_update;
    for my $word (@{$word_list}) {
        if (exists $self->{corpus}{$word}{$category}) {
            $word_to_update{$word} = 1;
        }
    }
    my @list = keys %word_to_update;
    while (my @cur = splice @list, 0, 200) {
        my $ph = join q{,}, (q{?}) x @cur;
        my $sth = $dbh->prepare(qq{
            UPDATE bayes_corpus
               SET num = num - 1
             WHERE category = ? AND word IN ($ph) AND num > 0;
        });
        $sth->execute($category, @cur);
    }
    $dbh->do(qq{
        UPDATE bayes_messages
           SET $category = $category - 1
           WHERE $category > 0;
    });
    $dbh->do(qq{
        UPDATE bayes_messages
           SET rev = rev + 1;
    });
    $begun_work or $dbh->commit;
    for my $word (keys %word_to_update) {
        $self->{corpus}{$word}{$category} ||= 0;
        if ($self->{corpus}{$word}{$category} > 0) {
            --$self->{corpus}{$word}{$category};
        }
    }
    if ($self->{"${category}_messages"} > 0) {
        --$self->{"${category}_messages"};
    }
    $self->{rev} = ($self->{rev} || 0) + 1;
    return $self;
}

sub _fetch {
    my($self, $word_list) = @_;
    my $dbh = $self->dbh;
    $self->{rev} ||= 0;
    my($good, $spam, $rev) = $dbh->selectrow_array(q{
        SELECT good, spam, rev FROM bayes_messages;
    });
    if ($self->{rev} != $rev
        || $CACHE_LIMIT <= scalar keys %{$self->{corpus}}
    ) {
        $self->clear_cache;
    }
    @{$self}{qw(good_messages spam_messages rev)} = ($good, $spam, $rev);
    my %mishit_words;
    for my $word (@{$word_list}) {
        if (   ! exists $self->{corpus}{$word}{good}
            || ! exists $self->{corpus}{$word}{spam}
        ) {
            $mishit_words{$word} = 1;
        }
    }
    my @mishit = keys %mishit_words;
    while (my @list = splice @mishit, 0, 200) {
        my $ph = join q{,}, (q{?}) x @list;
        my $sth = $dbh->prepare(qq{
            SELECT word, category, num FROM bayes_corpus WHERE word IN ($ph);
        });
        $sth->execute(@list);
        for my $row (@{ $sth->fetchall_arrayref }) {
            my($word, $category, $count) = @{$row};
            $self->{corpus}{$word}{$category} = $count;
        }
        $sth->finish;
    }
    return $self;
}

sub clear_cache {
    my($self) = @_;
    $self->{state} = {};
    $self->{corpus} = {};
    $self->{good_messages} = $self->{spam_messages} = undef;
    return $self;
}

1;

__END__

=pod

=head1 NAME

Bayes::PaulGraham - bayesian document filter.

=head1 VERSION

0.005

=head1 SYNOPSIS

    use Bayes::PaulGraham;
    use DBI;
    
    my $dbh = DBI->connect('dbi:SQLite:dbname=bayes.db', q{}, q{});
    my $bayes = Bayes::PaulGraham->new;
    $bayes->dbh($dbh);
    $dbh = undef;
    $bayes->create_table;
    my @spam_word = $spam =~ m{([a-zA-Z0-9]{4,}|\p{Han}{2,}|\p{Katakana}{3,})}g;
    $bayes->train('spam' => \@spam_word);
    my @good_word = $good =~ m{([a-zA-Z0-9]{4,}|\p{Han}{2,}|\p{Katakana}{3,})}g;
    $bayes->train('good' => \@good_word);
    my @any_word = $text =~ m{([a-zA-Z0-9]{4,}|\p{Han}{2,}|\p{Katakana}{3,})}g;
    print $bayes->score(\@any_word) >= 0.6 ? 'spam' : 'good', "\n";
    $bayes->dbh->disconnect;
    $bayes->dbh(undef);

=head1 DESCRIPTION

For your filtering spam messages, this module provides you to
classify whether given text is a good message or a spam using
the Paul Graham's baysian filtering method.

=head1 METHODS 

=over

=item C<< $class->new >>

Creates an instance to train and to score whether given message
is a spam or not. It stores occurences of words in a database.

=item C<< $self->dbh([$dbh]) >>>

Sets and gets a database handle of a DBI class. Before using
this instance, you must set your database handle already
connected a datasource.

=item C<< $self->clear_cache >>

Resets cache buffers.

=item C<< $self->train($category => \@word_list) >>

Makes training a corpus table to keep occurences of
spam words and good words. First argument is the category
name, 'spam' or 'good'. Second argument is a list of words
in the message. It is recomended the words in a list are
unique on the Paul Graham's method. So that, for example
you might prepare words in the message as followings:

    my %word_dict = map { $_ => 1} split /\s+/, $given_test;
    $bayes->train('good' => [keys %word_dict]);

=item C<< $self->forget($category => \@word_list) >>

Forgets words from the specified category, 'spam' or 'good'.
This method makes words with the C<train> the undo operation.

=item C<< $self->score(\@word_list) >>

Scores whether the given list of words is whether 'spam' or
not. This returns probability message is spam in the floating
point number. Tipically, when probability is greater than 0.6,
we treat it is spam. The list of words is same bases of C<train>.

=item C<< $self->create_table >>

Creates two tables in the database connected by dbh attribute.

    SELECT good, spam FROM bayes_messages
        -- numbers of spam or good messages.
    SELECT word, category, num FROM bayes_corpus
        -- numbers of spam or good words.

=item C<< $self->good_messages >>

Gets number of good messages after C<_fetch> instance method.

=item C<< $self->spam_messages >>

Gets number of spam messages after C<_fetch> instance method.

=item C<< $self->good($word) >>

Gets number of good words after C<_fetch> instance method.

=item C<< $self->spam($word) >>

Gets number of spam words after C<_fetch> instance method.

=back

=head1 DEPENDENCIES

L<DBI>
L<DBD::SQLite> - to test, on runtime you can use sqlite or mysql.

=head1 SEE ALSO

L<http://www.paulgraham.com/spam.html>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
