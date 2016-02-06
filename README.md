# NAME

Dist::Zilla::Plugin::Changelog::Grouped - Simplify usage of a grouped changelog

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Changelog-Grouped.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-Changelog-Grouped) ![coverage 94.6%](https://img.shields.io/badge/coverage-94.6%-yellow.svg)

# VERSION

Version 0.0100, released 2016-02-06.

# SYNOPSIS

    # in dist.ini (these are the defaults)
    [Changelog::Grouped]
    change_file = Changes
    groups = API Changes, Bug Fixes, Documentation, Enhancements

# DESCRIPTION

This plugin does two things:

- During the build phase it removes empty groups from the changelog.
- After a release it sets up the configured groups in the dist root changelog for the next version.

# ACKNOWLEDGMENTS

This plugin is based on [Dist::Zilla::Plugin::NextVersion::Semantic](https://metacpan.org/pod/Dist::Zilla::Plugin::NextVersion::Semantic). The differences are that this plugin is not a VersionProvider and
there is no semantic grouping of the change groups.

# SOURCE

[https://github.com/Csson/p5-Dist-Zilla-Plugin-Changelog-Grouped](https://github.com/Csson/p5-Dist-Zilla-Plugin-Changelog-Grouped)

# HOMEPAGE

[https://metacpan.org/release/Dist-Zilla-Plugin-Changelog-Grouped](https://metacpan.org/release/Dist-Zilla-Plugin-Changelog-Grouped)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
