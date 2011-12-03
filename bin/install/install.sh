#!/bin/bash

echo "Installing modules";
cpan App::cpanminus;
cpanm Plack;
cpanm Text::Xslate;
cpanm Moose;
cpanm Dancer;
cpanm Dancer::Template::Xslate;
cpanm Dancer::Session::PSGI;
cpanm Dancer::Logger::PSGI;
cpanm Mojolicious ;
cpanm MojoX::Renderer::Xslate;
cpanm Plack::Middleware::Session;
cpanm CHI;
cpanm Cache::FastMmap;
cpanm Plack::Middleware::OAuth;
cpanm Gravatar::URL;
