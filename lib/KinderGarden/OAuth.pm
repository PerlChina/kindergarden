package KinderGarden::OAuth;

use Moose;
use Carp;
use Plack::Response;
use LWP::UserAgent;
use JSON::Any;
use KinderGarden::Basic;
use KinderGarden::User;
use KinderGarden::BitMap qw/%user_auth_type/;

has 'status'   => (is => 'rw', isa => 'Str');
has 'handler'  => (is => 'ro', required => 1);
has 'token'    => (is => 'ro', isa => 'Plack::Middleware::OAuth::AccessToken');

# callback of Plack::Middleware::OAuth
sub BUILD {
    my $self = shift;

    my $handler = $self->handler;
    my $token   = $self->token;
    my $status  = $self->status;

    my $session = Plack::Session->new($handler->env);
    if ($status eq 'error') {
        $session->set('__auth_error', ($token and $token->has_error) ? $token->has_error : 'OAuth failed.');
    } else {
        my $user = $self->get_user;
        if ($user) {
            croak 'Provider: ' . $token->provider . ' bitmap fail' unless exists $user_auth_type{$token->provider};

            my $json = JSON::Any->new;

            my $dbh = KinderGarden::Basic->dbh;
            my $user_auth_type = $user_auth_type{$token->provider};

            ## check if we have id binded
            my ($user_id) = $dbh->selectrow_array("SELECT user_id FROM user_auth WHERE type_id = ? AND identification = ?", undef, $user_auth_type, $user->{id});
            if ($user_id) {
                $dbh->do("UPDATE user SET visited_at = ? WHERE id = ?", undef, time(), $user_id);
                $dbh->do("UPDATE user_auth SET raw_data = ? WHERE type_id = ? AND identification = ?", undef, $json->encode($user), $user_auth_type, $user->{id});
            } else {
                $dbh->do("INSERT INTO user (name, email, signed_at, visited_at) VALUES (?, ?, ?, ?)", undef, $user->{name}, $user->{email}, time(), time());
                $user_id = $dbh->{'mysql_insertid'};
                $dbh->do("INSERT INTO user_auth (type_id, identification, user_id, raw_data) VALUES (?, ?, ?, ?)", undef, $user_auth_type, $user->{id}, $user_id, $json->encode($user));
            }
            if ($user_id) {
                my $user = $dbh->selectrow_hashref("SELECT * FROM user WHERE id = ?", undef, $user_id);
                $session->set('__user', $user);
            }
        }
    }
}

sub response {
    my $res = Plack::Response->new(301);
    $res->redirect('/');
    return $res->finalize;
}

sub get_user {
    my $self = shift;

    my $ua       = LWP::UserAgent->new;
    my $json     = JSON::Any->new;
    my $token    = $self->token;
    my $provider = $self->token->provider;

=pod

    # twitter is commented b/c we can't get the email
    if ($provider eq 'Twitter') { # fallback to Net::Twitter
        require Net::Twitter;
        my $twitter = Net::Twitter->new(
            traits              => [qw/OAuth API::REST/],
            consumer_key        => $self->handler->config->{consumer_key},
            consumer_secret     => $self->handler->config->{consumer_secret},
            access_token        => $token->access_token,
            access_token_secret => $token->access_token_secret,
        );
        return $twitter->show_user( $self->token->extra->{screen_name} );
    }

=cut

    my $url;
    if ($provider eq 'Google') {
        $url = 'https://www.googleapis.com/oauth2/v1/userinfo?access_token=' . $token;
    } elsif ($provider eq 'GitHub') {
        $url = 'https://api.github.com/user?access_token=' . $token;
    } elsif ($provider eq 'Facebook') {
        $url = 'https://graph.facebook.com/me?access_token=' . $token;
    } elsif ($provider eq 'WeiBo') {
        $url = 'https://api.weibo.com/2/users/show.json?access_token=' . $token . '&uid=' . $token->params->{uid};
    } elsif ($provider eq 'Live') {
        $url = 'https://apis.live.net/v5.0/me?access_token=' . $token;
    } else {
        croak "Unknown provider $provider";
    }

    my $res = $ua->get($url);
    croak $res->status_line unless $res->is_success;
    my $u = $json->decode($res->decoded_content);

    # few fixes
    if ($provider eq 'GitHub') {
        $u->{name} ||= $u->{login};
    } elsif ($provider eq 'Live') {
        foreach my $p ("account", "preferred", "personal", "business") {
            next unless (defined $u->{emails}->{$p} and $u->{emails}->{$p} =~ /\@/);
            $u->{email} = $u->{emails}->{$p};
            last;
        }
    }

    return $u;
}

1;