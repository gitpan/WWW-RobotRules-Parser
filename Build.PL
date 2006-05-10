#!perl
use strict;
use Module::Build;

my $build = Module::Build->new(
    dist_name => 'WWW-RobotRules-Parser',
    dist_version_from => 'lib/WWW/RobotRules/Parser.pm',
    requires => {
        'URI' => 0,
    },
    license => 'perl',
    create_readme => 1,
    create_makefile_pl => 'traditional', 
);
$build->create_build_script();