package KinderGardenX::Text::Xslate::Bridge::KinderGarden;

use strict;
use warnings;
use parent qw(Text::Xslate::Bridge);

use Gravatar::URL 'gravatar_url';

my %funtion_methods = (
    gravatar_url => \&gravatar_url,
);

__PACKAGE__->bridge(
    function => \%funtion_methods,
);

1;