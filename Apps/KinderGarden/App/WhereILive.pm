package KinderGarden::App::WhereILive;

use Mojo::Base 'Mojolicious';
use KinderGarden::Basic;
use MojoX::Renderer::Xslate;

# This method will run once at server start
sub startup {
    my $self = shift;

    my $root   = KinderGarden::Basic->root;
    my $config = KinderGarden::Basic->config;
    
    $self->secret('K1nderG@rden');
    $self->static->root("$root/static");

    # Routes
    my $r = $self->routes;

    # Normal route to controller
    $r->route('/')->to('index#index');
    $r->route('/place/:id', id => qr/[\w\-]+/)->to('index#place');

    # Xslate Template
    my $template_options = $config->{xslate};
    $template_options->{path} = [ "$root/templates/app/where_i_live", "$root/templates" ];
    my $xslate = MojoX::Renderer::Xslate->build(
        mojo             => $self,
        template_options => $template_options
    );
    $self->renderer->add_handler(tt => $xslate);
    # remove those we don't need (MAYBE remove_handler should be introduced!)
    delete $self->renderer->handlers->{ep};
    delete $self->renderer->handlers->{epl};
    
    # Session user from PSGI OAuth
    $self->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        
        my $env  = $c->req->env;
        if ( $env->{'psgix.session'} ) {
            $c->stash->{user} = $env->{'psgix.session'}->{'__user'};
        }

        $next->();
    });
}

1;
