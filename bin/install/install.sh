#!/bin/bash

echo "Installing modules";
cpan App::cpanminus;
cpanm Plack;
cpanm Text::Xslate;
cpanm Moose;
cpanm Dancer;
cpanm http://fayland.org/CPAN/Dancer-Template-Xslate-0.01.tar.gz
cpanm Dancer::Session::PSGI;
cpanm -f Dancer::Logger::PSGI;
cpanm Mojolicious ;
cpanm MojoX::Renderer::Xslate;
cpanm Plack::Middleware::Session;
cpanm CHI;
cpanm Cache::FastMmap;
cpanm Plack::Middleware::OAuth;
cpanm Plack::Middleware::Debug;
cpanm Gravatar::URL;
