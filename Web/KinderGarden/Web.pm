package KinderGarden::Web;

use Dancer ':syntax';

our $VERSION = '0.1';

use KinderGarden::Basic;
use KinderGarden::User;
use Template::Plugin::Date;

# different template dir than default one
setting 'views'  => path( KinderGarden::Basic->root, 'templates' );
setting 'public' => path( KinderGarden::Basic->root, 'static' );

hook before_template_render => sub {
    my $tokens = shift;
    
    # merge vars into token b/c I like it more
    my $vars = delete $tokens->{vars} || {};
    foreach (keys %$vars) {
        $tokens->{$_} = $vars->{$_};
    }
    # alias user for header
    $tokens->{user} = $tokens->{session}->{__user} unless exists $tokens->{user};
    
    $tokens->{config} = KinderGarden::Basic->config;
};

get '/' => sub {
    template 'index';
};

get '/user/:id' => sub {
    my $id = param('id');
    
    my $user = KinderGarden::User->new(id => $id, cols => ['*']);
    if ($user->not_found) {
        var error => "User not found";
        return template 'index';
    }

    var date => Template::Plugin::Date->new; # hack for TTerse
    template 'user', { u => $user };
};

get '/logout' => sub {
    session '__user' => undef;
    session->destroy; # it's not working for Dancer::Session::PSGI
    redirect '/';
};

true;
