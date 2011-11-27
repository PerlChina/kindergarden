package KinderGardenX::Plack::Middleware::OAuth::User;

use Moose;
use LWP::UserAgent;
use JSON::Any;
use Carp 'croak'; 

has 'config'   => (is => 'ro', required => 1);
has 'token'    => (is => 'ro', required => 1, isa => 'Plack::Middleware::OAuth::AccessToken');

has 'data' => ( is => 'rw', isa => 'HashRef', lazy_build => 1);
sub _build_data {
    my ($self) = @_;
    
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
            consumer_key        => $self->config->{consumer_key},
            consumer_secret     => $self->config->{consumer_secret},
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
    } else {
        croak "Unknown provider $provider";
    }
    
    my $res = $ua->get($url);
    croak $res->status_line unless $res->is_success;
    my $u = $json->decode($res->decoded_content);

    return $u;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;