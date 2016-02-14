# NAME

Dist::Zilla::Plugin::NextRelease::Grouped - Simplify usage of a grouped changelog

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped) 

# VERSION

Version 0.0103, released 2016-02-14.

# SYNOPSIS

    [NextRelease::Grouped]
    filename = Changelog
    groups = Bug Fixes, Breaking Changes, Enhancements
    format_note = Released by %P

# DESCRIPTION

This plugin does two things:

- During the build phase it removes empty groups from the changelog and expands `{{$NEXT}}` according to the `format_*` attributes.
- After a release it adds the configured groups to the changelog under `{{$NEXT}}`.

# ATTRIBUTES

- `filename`

    Default: `Changes`

    The name of the changelog file.

- `format_version`, `format_date`, `format_note`

    Defaults:

    - `%v`
    - `%{yyyy-MM-dd HH:mm:ss VVVV}d`
    - `%{ (TRIAL RELEASE)}T`

    Formats to use for the release header. See [Dist::Zilla::Plugin::NextRelease](https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease) for supported codes.

- `timezone`

    Default: `local`

    The timezone to use when generating the release date.

- `groups`

    Default: API Changes, Bug Fixes, Enhancements, Documentation

    The groups to add for the next release.

- `user_stash`

    Default: `%User`

    The name of the stash where the user's name and email can be found.

- `auto_order`

    Default: `1`

    If true, the groups are ordered alphabetically. If false, the groups are ordered in the order they are given to `groups`.

    Note: If it is false, it also munges the changelog to ensure that one-off groups aren't deleted (while empty groups are). This might be
    a source of bugs.

# ACKNOWLEDGMENTS

This plugin is based on parts of [Dist::Zilla::Plugin::NextRelease](https://metacpan.org/pod/Dist::Zilla::Plugin::NextRelease) and [Dist::Zilla::Plugin::NextVersion::Semantic](https://metacpan.org/pod/Dist::Zilla::Plugin::NextVersion::Semantic).

# SOURCE

[https://github.com/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped](https://github.com/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped)

# HOMEPAGE

[https://metacpan.org/release/Dist-Zilla-Plugin-NextRelease-Grouped](https://metacpan.org/release/Dist-Zilla-Plugin-NextRelease-Grouped)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
