package KinderGarden::Web;

use Dancer ':syntax';

our $VERSION = '0.1';

use KinderGarden::Basic;
use KinderGarden::BitMap qw/%user_auth_type/;

# different template dir than default one
setting 'views'  => path( KinderGarden::Basic->root, 'templates' );
setting 'public' => path( KinderGarden::Basic->root, 'static' );

get '/' => sub {
    my $user = session '__user';
    template 'index', { user => $user }, { layout => undef };;
};

get '/auth' => sub {
    my $auth_provider = session '__auth_user_provider';
    my $user = session '__auth_user';
    
    if ($auth_provider and exists $user_auth_type{$auth_provider} and $user) {
        my $dbh = KinderGarden::Basic->dbh;
        
        ## check if we have id binded
        my ($user_id) = $dbh->selectrow_array("SELECT user_id FROM user_auth WHERE type_id = ? AND identification = ?", undef, $user_auth_type{$auth_provider}, $user->{id});

        if ($user_id) {
            $dbh->do("UPDATE user_auth SET raw_data = ? WHERE type_id = ? AND identification = ?", undef, to_json($user), $user_auth_type{$auth_provider}, $user->{id});
        } else {
            $dbh->do("INSERT INTO user (name, email, visited_at) VALUES (?, ?, ?)", undef, $user->{name}, $user->{email}, time());
            $user_id = $dbh->{'mysql_insertid'};
            $dbh->do("INSERT INTO user_auth (type_id, identification, user_id, raw_data) VALUES (?, ?, ?, ?)", undef, $user_auth_type{$auth_provider}, $user->{id}, $user_id, to_json($user));
        }
        
        session '__auth_user_provider' => undef;
        session '__auth_user' => undef;
        if ($user_id) {
            my $user = $dbh->selectrow_hashref("SELECT * FROM user WHERE id = ?", undef, $user_id);
            session '__user' => $user;
        }
    }
    
    redirect '/';
};

get '/logout' => sub {
    session '__user' => undef;
    session->destroy; # it's not working for Dancer::Session::PSGI
    redirect '/';
};

true;
