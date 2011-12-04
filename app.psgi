#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use Plack;
use Plack::Builder;
use Plack::App::File;
use Plack::Session::Store::Cache;
use CHI;

## OAuth
use lib "$Bin/lib";
use KinderGarden::Basic;
use KinderGardenX::Plack::Middleware::OAuth::User;

## KinderGarden-Web
use lib "$Bin/Web";
use Dancer ':syntax';
setting apphandler => 'PSGI';

## App WhereIlive
use Mojo::Server::PSGI;
use lib "$Bin/Apps";

my $root = KinderGarden::Basic->root;

builder {
    enable_if { $ENV{KINDERGARDEN_DEBUG} or $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'Debug', panels => [
        qw(Timer),
        ['DBITrace', level => 2]
    ];
    enable_if { ($ENV{KINDERGARDEN_DEBUG} or $_[0]->{REMOTE_ADDR} eq '127.0.0.1') and $^O ne 'MSWin32' } 'Debug::Memory';
    enable_if { $ENV{KINDERGARDEN_DEBUG} or $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } "StackTrace";
    enable_if { $ENV{KINDERGARDEN_DEBUG} or $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } "ConsoleLogger";
    
    enable 'Session', store => Plack::Session::Store::Cache->new(
        cache => CHI->new(driver => 'FastMmap')
    );
    
    mount '/favicon.ico' =>  Plack::App::File->new( file => "$root/static/favicon.ico" ),
    mount '/static/' => Plack::App::File->new( root => "$root/static" ),
    mount '/static/docs/' => builder {
        enable_if { $_[0]->{PATH_INFO} =~ /\.html/ } 'FileWrap',
            headers => ["$root/static/docs/header.html"], footers => ["$root/static/docs/footer.html"];
        Plack::App::File->new( root => "$root/static/docs" )->to_app;
    },
    
    my $oauth_provider_yml = -e "$root/conf/oauth_local.yml" ? "$root/conf/oauth_local.yml" : "$root/conf/oauth.yml";
    mount "/oauth" => builder {
        enable 'OAuth', 
            on_success => sub {
                my ( $self, $token ) = @_;

                my $u = KinderGardenX::Plack::Middleware::OAuth::User->new( config => $self->config, token => $token );

                if ($u) {
                    my $session = Plack::Session->new($self->env);
                    $session->set('__auth_user_provider', $token->provider);
                    $session->set('__auth_user', $u->data);
                }
                my $res = Plack::Response->new(301);
                $res->redirect('/auth');
                return $res->finalize;
            },
            on_error => sub {
                my $res = Plack::Response->new(301);
                $res->redirect('/auth');
                return $res->finalize;
            },
            providers => $oauth_provider_yml;
    },
    
    mount '/app/whereilive' => sub {
        lib->import("$root/lib");
        lib->import("$root/Apps");
        
        my $psgi = Mojo::Server::PSGI->new(app_class => 'KinderGarden::App::WhereILive');
        $psgi->run(@_)
    },
    
    mount '/' => sub {
        my $env = shift;
        
        lib->import("$root/lib");
        lib->import("$root/Web");
        
        local $ENV{DANCER_APPDIR}  = "$root/Web";
        local $ENV{DANCER_CONFDIR} = "$root/Web";
        load_app "KinderGarden::Web";
        Dancer::App->set_running_app('KinderGarden::Web');
        setting appdir  => "$root/Web";
        setting confdir => "$root/Web";
        Dancer::Config->load;
        
        # damn, how many fixes should I write it here!
        setting 'views'  => "$root/templates";
        setting 'public' => "$root/static";
        
        my $request = Dancer::Request->new( env => $env );
        Dancer->dance($request);
    },
};
