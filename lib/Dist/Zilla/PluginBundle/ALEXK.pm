#
# This file is part of Dist-Zilla-PluginBundle-ALEXK
#
# This software is copyright (c) 2010 by Alexander Kühne.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Zilla::PluginBundle::ALEXK;
BEGIN {
  $Dist::Zilla::PluginBundle::ALEXK::VERSION = '0.001';
}
# ABSTRACT: Dist::Zilla configuration the way ALEXK does it


# Dependencies
use autodie 2.00;
use Moose 0.99;
use Moose::Autobox;
use namespace::autoclean 0.09;

use Dist::Zilla 3.101450; # Use CPAN::Meta

use Dist::Zilla::PluginBundle::Filter ();
use Dist::Zilla::PluginBundle::Git ();

use Dist::Zilla::Plugin::BumpVersionFromGit ();
#use Dist::Zilla::Plugin::CheckExtraTests ();
use Dist::Zilla::Plugin::CompileTests ();
use Dist::Zilla::Plugin::MinimumPerl ();
use Dist::Zilla::Plugin::PodWeaver ();
use Dist::Zilla::Plugin::TaskWeaver ();
use Dist::Zilla::Plugin::PortabilityTests ();
use Dist::Zilla::Plugin::Prepender ();
use Dist::Zilla::Plugin::ReadmeFromPod ();

with 'Dist::Zilla::Role::PluginBundle::Easy';

has fake_release => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{fake_release} },
);

has is_task => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub { $_[0]->payload->{is_task} },
);

has auto_prereq => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{auto_prereq} ? $_[0]->payload->{auto_prereq} : 1
  },
);

has git_remote => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  default => sub {
    exists $_[0]->payload->{git_remote} ? $_[0]->payload->{git_remote} : 'origin',
  },
);


sub configure {
  my $self = shift;

  my @push_to = ('origin');
  push @push_to, $self->git_remote if $self->git_remote ne 'origin';

  $self->add_plugins (

  # version number
    'BumpVersionFromGit',

  # file munging
    'PkgVersion',         # core
    'Prepender',
    ( $self->is_task ? 'TaskWeaver' : 'PodWeaver' ),

  # generated distribution files
    'ReadmeFromPod',

  # generated t/ tests
    [ CompileTests => { fake_home => 1 } ],

  # generated xt/ tests
    'MetaTests',          # core
    'PodSyntaxTests',     # core
    'PodCoverageTests',   # core
    'PortabilityTests',

  # metadata
    'MinimumPerl',
    ( $self->auto_prereq ? 'AutoPrereq' : () ),
    'MetaJSON',           # core

  # before release
    'Git::Check',
    'CheckChangesTests',
    'TestRelease',        # core
    'ConfirmRelease',     # core

  # release
    ( $self->fake_release ? 'FakeRelease' : 'UploadToCPAN'),       # core

  # after release
  # Note -- NextRelease is here to get the ordering right with
  # git actions.  It is *also* a file munger that acts earlier

    [ 'Git::Commit' => 'Commit_Dirty_Files' ], # Changes and/or dist.ini
    'Git::Tag',

    # bumps Changes
    'NextRelease',        # core (also munges files)

    [ 'Git::Commit' => 'Commit_Changes' => { commit_msg => "bump Changes" } ],

    [ 'Git::Push' => { push_to => \@push_to } ],

  );

  $self->add_bundle('Basic');

}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=head1 NAME

Dist::Zilla::PluginBundle::ALEXK - Dist::Zilla configuration the way ALEXK does it

=head1 VERSION

version 0.001

=for Pod::Coverage configure

=head1 BUNDLE CONTENT

  [@Basic]
  [BumpVersionFromGit]
  [PkgVersion]
  [Prepender]
  [TaskWeaver] ; if bundle option 'is_task' is true else
  [PodWeaver] 
  [ReadmeFromPod]
  [CompileTests] ; with fake_home = 1
  [MetaTests]
  [PodSyntaxTests]
  [PodCoverageTests]
  [PortabilityTests]
  [MinimumPerl]
  [AutoPrereq] ; if bundle option 'auto_prereq' is not set to false
  [Git::Check]
  [CheckChangesTests]
  [CheckExtraTests]
  [TestRelease]
  [ConfirmRelease]
  [FakeRelease] ; if bundle option 'fake_release' is true else
  [UploadToCPAN]
  [Git::Commit]
  [Git::Tag]
  [Git::Push] ; takes 'git_remote' option and defaults to 'origin'

=head1 AUTHOR

Alexander Kühne <alexk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alexander Kühne.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

