use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use String::Cushion;
use syntax 'qi';
use Test::DZil;
use Dist::Zilla::Plugin::Changelog::Grouped;

my $changes = changer('Documentation', 'A change');
my $ini = make_ini(groups => 'Api, Documentation, Empty');
my $tzil = make_tzil($ini, $changes);

$tzil->chrome->logger->set_debug(1);
diag $];
if($] <= 5.012000) {
    diag 'no uninit warnings';
    no warnings 'uninitialized';
    $tzil->release;
}
else {
    diag 'init warnings';
    $tzil->release;
}

like $tzil->slurp_file('source/lib/DZT/ChangelogGrouped.pm'), qr{0\.0003}, 'Version changed in .pm';
like $tzil->slurp_file('source/Changes'), qr{0\.0002}, 'Version change in Changes';
like $tzil->slurp_file('source/Changes'), qr{\{\{\$NEXT\}\}[\r\n]\s+\[Api\][\n\r\s]+\[Documentation\]}ms, 'Change groups generated';
unlike $tzil->slurp_file('build/Changes'), qr{\[Empty\]}, 'Empty groups removed in built Changes';

done_testing;

sub make_ini {
    return simple_ini({ version => undef }, qw/
            GatherDir
            FakeRelease
            NextRelease
            RewriteVersion
            BumpVersionAfterRelease
        /, ['Changelog::Grouped', { @_ } ],
    );
}

sub make_tzil {
    my $ini = shift;
    my $changes = shift;

    return Builder->from_config(
        {   dist_root => 't/corpus' },
        {
            add_files => {
                'source/Changes' => $changes,
                'source/dist.ini' => $ini,
            },
        },
    );
}

sub changer {
    my $group = shift;
    my $change = shift;

    return cushion 0, 1, qqi{
        Revision history for {{@{[ '$dist->name' ]}}}

        {{@{['$NEXT']}}}
         [$group]
         - $change

         [Empty]

        0.0001  1999-02-04T10:42:19Z UTC
         - First release
    };
}
