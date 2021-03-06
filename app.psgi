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
use KinderGarden::OAuth;

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
                KinderGarden::OAuth->new( status => 'success', handler => $self, token => $token )->response;
            },
            on_error => sub {
                my ( $self, $token ) = @_;
                KinderGarden::OAuth->new( status => 'error', handler => $self, token => $token )->response;
            },
            providers => $oauth_provider_yml;
    },
    
    mount '/app/whereilive' => sub {
        _mojo_wrap('KinderGarden::App::WhereILive', @_);
    },
    
    mount '/comment' => sub {
        my $env = shift;
        _dance_wrap('KinderGarden::Comment', $env);
    },
    
    mount '/' => sub {
        my $env = shift;
        _dance_wrap('KinderGarden::Web', $env);
    },
};

sub _dance_wrap {
    my $app = shift;
    my $env = shift;
    
    lib->import("$root/lib");
    lib->import("$root/Web");
    
    local $ENV{DANCER_APPDIR}  = "$root/Web";
    local $ENV{DANCER_CONFDIR} = "$root/Web";
    load_app $app;
    Dancer::App->set_running_app($app);
    setting appdir  => "$root/Web";
    setting confdir => "$root/Web";
    Dancer::Config->load;
    
    # damn, how many fixes should I write it here!
    setting 'views'  => "$root/templates";
    setting 'public' => "$root/static";
    
    my $request = Dancer::Request->new( env => $env );
    Dancer->dance($request);
}

sub _mojo_wrap {
    my $app = shift;
    
    lib->import("$root/lib");
    lib->import("$root/Apps");
    my $psgi = Mojo::Server::PSGI->new(app_class => $app);
    $psgi->run(@_);
}