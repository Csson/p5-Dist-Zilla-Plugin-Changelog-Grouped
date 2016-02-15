use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::NextRelease::Grouped;

# ABSTRACT: Simplify usage of a grouped changelog
our $VERSION = '0.0103';

use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

use Types::Standard qw/Str ArrayRef Bool/;
use Path::Tiny;
use List::Util qw/none/;
use CPAN::Changes;
use CPAN::Changes::Release;
use Safe::Isa qw/$_call_if_object/;

use String::Formatter stringf => {
    -as => 'header_formatter',

    input_processor => 'require_single_input',
    string_replacer => 'method_replace',
    codes => {
        v => sub { shift->zilla->version },
        d => sub {
            require DateTime;
            DateTime->now->set_time_zone(shift->time_zone)->format_cldr(shift);
        },
        t => sub { "\t" },
        n => sub { "\n" },
        E => sub { shift->user_info('email') },
        U => sub { shift->user_info('name') },
        T => sub { shift->zilla->is_trial ? (shift || '-TRIAL') : '' },
        V => sub {
            my $zilla = (shift)->zilla;
            return $zilla->version . ($zilla->is_trial ? (shift || '-TRIAL') : '');
        },
        P => sub {
            my $self = shift;
            my($releaser) = grep { $_->can('cpanid') } @{ $self->zilla->plugins_with('-Releaser') };
            $self->log_fatal(q{releaser doesn't provide cpanid, but %P used}) unless $releaser;

            return $releaser->cpanid;
        },
    },
};

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::AfterRelease
/;

has filename => (
    is => 'ro',
    isa => Str,
    default => 'Changes',
);
has time_zone => (
    is => 'ro',
    isa => Str,
    default => 'local',
);
has user_stash => (
    is => 'ro',
    isa => Str,
    default => '%User',
);
has format_version => (
    is => 'ro',
    isa => Str,
    default => '%v',
);
has format_date => (
    is => 'ro',
    isa => Str,
    default => '%{yyyy-MM-dd HH:mm:ss VVVV}d',
);
has format_note => (
    is => 'ro',
    isa => Str,
    default => '%{ (TRIAL RELEASE)}T',
);
has groups => (
    is => 'ro',
    isa => (ArrayRef[Str])->plus_coercions(Str, sub { [split m{\s*,\s*}, $_] }),
    traits => ['Array'],
    coerce => 1,
    default => sub { ['API Changes', 'Bug Fixes', 'Enhancements', 'Documentation'] },
    handles => {
        all_groups => 'elements',
    }
);
has auto_order => (
    is => 'ro',
    isa => Bool,
    default => 1,
);

has _changes_after_munging => (
    is => 'rw',
    isa => Str,
    init_arg => undef,
);


sub user_info {
    my $self = shift;
    my $field = shift;

    state $stash = $self->zilla->stash_named($self->user_stash);

    my $value = $stash->$_call_if_object($field);
    if(!defined $value) {
        $self->log_fatal(['You must enter your %s in the [%s] section of ~/.dzil/config.ini', $field, $self->user_stash]);
    }
    return $value;
}

sub munge_files {
    my $self = shift;

    my($file) = grep { $_->name eq $self->filename } @{ $self->zilla->files };

    my $changes = CPAN::Changes->load_string($file->content, next_token => $self->_next_token);
    my $next = ($changes->releases)[-1];

    return if !defined $next;

    $next->version(header_formatter($self->format_version, $self));
    $next->date(header_formatter($self->format_date, $self));
    $next->note(header_formatter($self->format_note, $self));
    $next->delete_empty_groups;

    $self->log_debug(['Cleaning up %s in memory', $file->name]);

    my $sort_groups = sub {
        my @custom_groups = grep { my $group = $_; none { $group eq $_ } $self->all_groups } @_;
        my @sorted = ((sort { $a cmp $b } @custom_groups), $self->all_groups);
        return @sorted;
    };

    my $content = $self->auto_order ? $changes->serialize : $changes->serialize(group_sort => $sort_groups);

    # hack to remove empty groups
    if(!$self->auto_order) {

        # followed by another group
        $content =~ s{
            (?<= [\n\r] )
              [\s\t]+ \[ [^\]]+ \] [\s\t]*
              [\n\r]+
            (?= [\s\t]+ \[ [^\]]+ \] )
            }{\n}xmsg;

        # followed by a release
        $content =~ s{
            (?<=[\n\r])
            [\s\t]+ \[ [^\]]+ \] [\s\t]*
            [\n\r]+
            (?=[v\d])
            }{\n}xmsg;

        # followed by end-of-file
        $content =~ s{
            (?<= [\n\r])
            [\s\t]+ \[ [^\]]+ \] [\s\t]*
            [\n\r]*
            \z
            }{\n}xmsg;

        # just one final \n
        $content =~ s{\n+\z}{\n}ms;

        # cleanup whitespace
        $content =~ s{\r}{}g;
        $content =~ s{\n{3,}}{\n\n}g;

        # ensure that a release header (any line starting with \d or 'v') isn't followed by an empty line.
        $content =~ s{(\n [v\d] [^\n]+) \n{2,} (?=[\s\t]) }{$1\n}msgx;
    }

    $file->content($content);
    $self->_changes_after_munging($content);
}

sub after_release {
    my $self = shift;

    my $changes = CPAN::Changes->load_string($self->_changes_after_munging, next_token => $self->_next_token);

    my $next = CPAN::Changes::Release->new(version => '{{$NEXT}}');
    $next->add_group($self->all_groups);
    $changes->add_release($next);

    path($self->filename)->spew({ binmode => $self->binmode }, $changes->serialize);
}

sub _next_token { qr/\{\{\$NEXT\}\}/ }

sub binmode {
    my $self = shift;

    my($file) = grep { $_->name eq $self->filename } @{ $self->zilla->files };
    $self->log_fatal("failed to find @{[ $self->filename ]} in the distribution") if !$file;

    return sprintf ':raw:encoding(%s)', $file->encoding;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 SYNOPSIS

    [NextRelease::Grouped]
    filename = Changelog
    groups = Bug Fixes, Breaking Changes, Enhancements
    format_note = Released by %P

=head1 DESCRIPTION

This plugin does two things:

=for :list
* During the build phase it removes empty groups from the changelog and expands C<{{$NEXT}}> according to the C<format_*> attributes.
* After a release it adds the configured groups to the changelog under C<{{$NEXT}}>.

=head1 ATTRIBUTES

=begin :list

= C<filename>
Default: C<Changes>

The name of the changelog file.

= C<format_version>, C<format_date>, C<format_note>
Defaults:

=for :list
* C<%v>
* C<%{yyyy-MM-dd HH:mm:ss VVVV}d>
* C<%{ (TRIAL RELEASE)}T>

Formats to use for the release header. See L<Dist::Zilla::Plugin::NextRelease> for supported codes.


= C<timezone>
Default: C<local>

The timezone to use when generating the release date.


= C<groups>
Default: API Changes, Bug Fixes, Enhancements, Documentation

The groups to add for the next release.


= C<user_stash>
Default: C<%User>

The name of the stash where the user's name and email can be found.


= C<auto_order>
Default: C<1>

If true, the groups are ordered alphabetically. If false, the groups are ordered in the order they are given to C<groups>.

Note: If it is false, it also munges the changelog to ensure that one-off groups aren't deleted (while empty groups are). This might be
a source of bugs.

=end :list

=head1 ACKNOWLEDGMENTS

This plugin is based on parts of L<Dist::Zilla::Plugin::NextRelease> and L<Dist::Zilla::Plugin::NextVersion::Semantic>.

=cut
