package KinderGarden::App::WhereILive::Example;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# This action will render a template
sub welcome {
  my $self = shift;
  
  my $env  = $self->req->env;
  my $user = $env->{'psgix.session'} ? $env->{'psgix.session'}->{'__user'} : '';

  $self->render(template_name => 'index.tt', handler => 'tt', user => $user);
}

1;
