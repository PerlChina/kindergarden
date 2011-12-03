package KinderGarden::BitMap;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK %user_auth_type/;
@EXPORT_OK = qw/%user_auth_type/;

%user_auth_type = (
    'Google' => 1,
    'Facebook' => 2,
    'GitHub' => 3,
    'WeiBo'  => 4,
    'Live'   => 5,
);

1;