package KinderGarden::App::WhereILive::Index;

use Mojo::Base 'Mojolicious::Controller';
use KinderGarden::Basic;
use HTML::TagCloud;
use Text::Xslate qw(mark_raw html_escape);

sub index {
    my $c = shift;

    my $user = $c->stash->{user};
    my $dbh  = KinderGarden::Basic->dbh;
  
    ## if on POST
    if ($user) {
        my $place = $c->param('place');
        if (defined $place and length $place) {
            my ($place_id) = $dbh->selectrow_array("SELECT id FROM app_wil_place WHERE text = ?", undef, $place);
            unless ($place_id) {
                $dbh->do("INSERT INTO app_wil_place (type_id, text) VALUES (1, ?)", undef, html_escape($place)) or die $dbh->errstr;
                $place_id = $dbh->{'mysql_insertid'};
            }
            $dbh->do("INSERT IGNORE INTO app_wil_user_place (user_id, place_id, inserted_at) VALUES (?, ?, ?)", undef, $user->{id}, $place_id, time());
            $c->stash->{success} = 'Well Done!';
        }
    }
    
    # Tag Cloud
    my $cloud = HTML::TagCloud->new;
    my $sth = $dbh->prepare("SELECT place_id, COUNT(*) FROM app_wil_user_place GROUP BY place_id");
    $sth->execute();
    my $place_sth = $dbh->prepare("SELECT text FROM app_wil_place WHERE id = ?");
    while (my ($pid, $cnt) = $sth->fetchrow_array) {
        $place_sth->execute($pid);
        my ($p) = $place_sth->fetchrow_array;
        $cloud->add($p, $c->url_for("/place/$pid"), $cnt);
    }

    $c->render(template_name => 'index.tt', handler => 'tt', cloud => mark_raw($cloud->html_and_css(50)));
}

sub place {
    my ($c) = @_;
    
    my $user = $c->stash->{user};
    my $dbh  = KinderGarden::Basic->dbh;
    
    my $captures = $c->match->captures;
    my $pid = $captures->{id};
    
    my ($place) = $dbh->selectrow_array("SELECT text FROM app_wil_place WHERE id = ?", undef, $pid);
    unless ($place) {
        # detach error?
        return $c->redirect_to( $c->url_for('/') );
    }
    
    my @users;
    my $sth = $dbh->prepare("SELECT user_id FROM app_wil_user_place WHERE place_id = ? ORDER BY inserted_at DESC");
    $sth->execute($pid);
    my $user_sth = $dbh->prepare("SELECT * FROM user WHERE id = ?"); # package pm later
    while (my ($user_id) = $sth->fetchrow_array) {
        $user_sth->execute($user_id);
        my $user = $user_sth->fetchrow_hashref;
        push @users, $user if $user;
    }
    
    $c->render(template_name => 'place.tt', handler => 'tt', place => $place, users => \@users);
}

1;
