package Plack::Middleware::OAuth::WeiBo;

use warnings;
use strict;

sub config { +{
	version   => 2,
	authorize_url    => 'https://api.weibo.com/oauth2/authorize',
	access_token_url => 'https://api.weibo.com/oauth2/access_token',
	response_type    => 'code',
	grant_type       => 'authorization_code',
	request_method   => 'POST',
} }

1;