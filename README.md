# NAME

Dist::Zilla::Plugin::NextRelease::Grouped - Simplify usage of a grouped changelog

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-NextRelease-Grouped) ![coverage 76.8%](https://img.shields.io/badge/coverage-76.8%-orange.svg)

# VERSION

Version 0.0101, released 2016-02-08.

# SYNOPSIS

    [NextRelease::Grouped]
    change_file = Changelog
    groups = Bug Fixes, Breaking Changes, Enhancements
    format_note = Released by %P

# DESCRIPTION

This plugin does two things:

- During the build phase it removes empty groups from the changelog and expands `{{$NEXT}}` according to the `format_*` attributes.
- After a release it adds the configured groups to the changelog under `{{$NEXT}}`.

# ATTRIBUTES

- `file_name`

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

- user\_stash

    Default: `%User`

    The name of the stash where the user's name and email can be found.

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
