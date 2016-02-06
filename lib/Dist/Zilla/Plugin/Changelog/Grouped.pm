use 5.10.1;
use strict;
use warnings;

package Dist::Zilla::Plugin::Changelog::Grouped;

# ABSTRACT: Simplify usage of a grouped changelog
our $VERSION = '0.0100';

use Moose;
use namespace::autoclean;

use Types::Standard qw/Str ArrayRef/;
use Path::Tiny;
use CPAN::Changes;
with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
    Dist::Zilla::Role::AfterRelease
/;

has change_file => (
    is => 'ro',
    isa => Str,
    default => 'Changes',
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

sub munge_files {
    my $self = shift;

    my($file) = grep { $_->name eq $self->change_file } @{ $self->zilla->files };
warn 'File munger ' x 5;
    my $changes = CPAN::Changes->load_string($file->content, next_token => qr/\{\{\$NEXT\}\}/);
    my $next = (reverse $changes->releases)[0];
    return if !defined $next;

    $next->delete_group($_) for grep { !@{ $next->changes($_) } } $next->groups;

    $self->log_debug(['Cleaning up %s in memory', $file->name]);
    $file->content($changes->serialize);
}

sub after_release {
    my $self = shift;

    my $changes = CPAN::Changes->load($self->change_file, next_token => qr/\{\{\$NEXT\}\}/);
    $changes->delete_empty_groups;
    my($next) = reverse $changes->releases;

    $next->add_group($self->all_groups);
    $self->log_debug(['Cleaning up %s on disk', $self->change_file]);

    path($self->change_file)->spew($changes->serialize);
warn "After release change file: <@{[ $self->change_file->realpath ]}>";
warn '>------->';
warn path($self->change_file)->slurp;
warn '<-------<';
}

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

This plugin is based on parts of L<Dist::Zilla::Plugin::NextVersion::Semantic>.

=cut
