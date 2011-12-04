package KinderGarden::Comment;

use Dancer ':syntax';

our $VERSION = '0.1';

use KinderGarden::Basic;
use KinderGarden::User;

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
    return 'Permission Denied';
};



true;
