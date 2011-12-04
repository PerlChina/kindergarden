package KinderGarden::Comment;

use Moose;
use Carp;
use KinderGarden::Basic;
use Digest::MD5 'md5_hex';

has 'dbh' => ( is => 'rw', lazy_build => 1 );
sub _build_dbh { KinderGarden::Basic->dbh }

has 'obj' => ( is => 'rw', isa => 'Str', required => 1 );
has 'obj_hash' => ( is => 'ro', lazy_build => 1 );
sub _build_obj_hash { md5_hex( (shift)->obj ) }



no Moose;
__PACKAGE__->meta->make_immutable;

1;