use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bayes::PaulGraham',
    AUTHOR              => 'MIZUTANI Tociyuki <tociyuki@gmail.com>',
    VERSION_FROM        => 'lib/Bayes/PaulGraham.pm',
    ABSTRACT_FROM       => 'lib/Bayes/PaulGraham.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Base' => 0,
        'DBI' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
