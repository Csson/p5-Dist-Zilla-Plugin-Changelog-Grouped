use 5.10.1;
use strict;
use warnings;

package Dist::Zilla::Plugin::NextVersion::Grouped;

# ABSTRACT: Simplify usage of a grouped changelog
our $VERSION = '0.0101';

use Moose;
use MooseX::AttributeShortcuts;
use namespace::autoclean;

use Types::Standard qw/Str ArrayRef/;
use Path::Tiny;
use CPAN::Changes;
use List::Util qw/first/;
use Safe::Isa qw/$_call_if_object/;
use MooseX::Aliases; # remove after deprecation period.

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
        t => sub { "\n" },
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
            my $releaser = first { $_->can('cpanid') } @{ $self->zilla->plugins_with('-Releaser') };
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
    alias => 'change_file',
);
around change_file => sub {
    my $next = shift;
    my $self = shift;
    $self->log(q{Use of deprecated attribute 'change_file', replace with 'filename'});
    $self->$next;
};
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
    default => '%{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d',
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

    my($file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files };

    my $changes = CPAN::Changes->load_string($file->content, next_token => $self->_next_token);
    my $next = (reverse $changes->releases)[0];
    return if !defined $next;

    $next->version(header_formatter($self->format_version, $self));
    $next->date(header_formatter($self->format_date, $self));
    $next->note(header_formatter($self->format_note, $self));

    $next->delete_group($_) for grep { !@{ $next->changes($_) } } $next->groups;

    $self->log_debug(['Cleaning up %s in memory', $file->name]);
    $file->content($changes->serialize);
}

sub after_release {
    my $self = shift;

    my $changes = CPAN::Changes->load($self->filename, next_token => $self->_next_token);
    $changes->delete_empty_groups;
    my($next) = reverse $changes->releases;

    $next->add_group($self->all_groups);
    $self->log_debug(['Cleaning up %s on disk', $self->filename]);
    $self->log_debug('>' . (join ',' => $next->groups) .'<');

    path($self->filename)->spew($changes->serialize);
}

sub _next_token { qr/\{\{\$NEXT\}\}/ }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 SYNOPSIS

    # in dist.ini (these are the defaults)
    [Changelog::Grouped]
    change_file = Changes
    groups = API Changes, Bug Fixes, Documentation, Enhancements

=head1 DESCRIPTION

This plugin does two things:

=for :list
* During the build phase it removes empty groups from the changelog.
* After a release it adds the configured groups to the changelog under C<{{$NEXT}}>.

=head1 ACKNOWLEDGMENTS

This plugin is based on parts of L<Dist::Zilla::Plugin::NextVersion> and L<Dist::Zilla::Plugin::NextVersion::Semantic>.

=cut
