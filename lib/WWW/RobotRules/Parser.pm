# $Id: Parser.pm 1 2006-05-10 08:42:35Z daisuke $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.
#
# A lot of this code is based on WWW::RobotRules

package WWW::RobotRules::Parser;
use strict;
use vars qw($VERSION);
use URI;

BEGIN
{
    $VERSION = '0.01';
}

sub new { bless { }, shift }

sub parse_uri
{
    my $self = shift;
    my $uri  = shift;

    require LWP::UserAgent;
    my $ua   = LWP::UserAgent->new;
    my $res  = $ua->get($uri);

    if (! $res->is_success) {
        require Carp;
        Carp::croak("Failed to retrieve $uri: Got HTTP code " . $res->code);
    }
        
    $self->parse($uri, $res->content);
}

sub parse
{
    my $self = shift;
    my $robot_txt_uri = shift;
    my $text = shift;

    $robot_txt_uri = URI->new($robot_txt_uri) if ($robot_txt_uri);

    my %result;
    # blank lines are significant, so turn CRLF into LF to avoid generating
    # false ones
    $text =~ s/\015\012/\012/g;

    my $ua_pattern;
    # split at \012 or \015
    for (split(/[\012\015]/, $text)) {
        # Lines containing only a comment are discarded completely, and
        # therefore do not indicate a record boundary
        next if /^\s*\#/;

        s/\s*\#.*//; # Remove comments at end-of-line

        if (/^\s*User-Agent\s*:\s*(.*)/i) {
            $ua_pattern = $1;
            $ua_pattern =~ s/\s+$//;
        } elsif (/^\s*Disallow\s*:\s*(.*)/i) {
            if (! defined $ua_pattern) {
                $ua_pattern = '*';
            }

            my $disallow = $1;
            $disallow =~ s/\s+$//;
            if (length $disallow) {
                if ($robot_txt_uri) {
                    my $ignore;
                    eval {
                        my $u = URI->new_abs($disallow, $robot_txt_uri);
                        $ignore++ if $u->scheme ne $robot_txt_uri->scheme;
                        $ignore++ if lc($u->host) ne lc($robot_txt_uri->host);
                        $ignore++ if $u->port ne $robot_txt_uri->port;
                        $disallow = $u->path_query;
                        $disallow = "/" unless length $disallow;
                    };
                    next if $@;
                    next if $ignore;
                }
                push @{$result{$ua_pattern}}, $disallow;
            }
        }
    }
    return wantarray ? %result : \%result
}

1;

__END__

=head1 NAME

WWW::RobotRules::Parser - Just Parse robots.txt

=head1 SYNOPSIS

  use WWW::RobotRules::Parser;
  my $p = WWW::RobotRules::Parser->new;
  $p->parse($robots_txt_uri, $text);

  $p->parse_uri($robots_txt_uri);

=head1 DESCRIPTION

WWW::RobotRules::Parser allows you to simply parse robots.txt files as
described in http://www.robotstxt.org/wc/norobots.html. Unlike WWW::RobotRules
(which is very cool), this module does not take into consideration your
user agent name when parsing. It just parses the structure and returns
a hash containing the whole set of rules. You can then use this to do
whatever you like with it.

I mainly wrote this to store away the parsed data structure else where for
later use, without having to specify an user agent.

=head1 METHODS

=head2 new

Creates a new instance of WWW::RobotRules::Parser

=head2 parse($uri, $text)

Given the URI of the robots.txt file and its contents, parses the content and returns a data structure that looks like the following:

  {
     '*' => [ '/private', '/also_private' ],
     'Another UserAgent' => [ '/dont_look' ]
  }

=head2 parse_uri($uri)

Give the URI of the robots.txt file, retrieves and parses the file.

=head1 AUTHOR

Copyright (c) 2006 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>
All rights reserved.

=cut

