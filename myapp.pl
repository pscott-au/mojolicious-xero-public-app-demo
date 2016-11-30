#!/usr/bin/env perl
use Mojolicious::Lite;

use WebService::Xero::Agent::PublicApplication;
use Data::Dumper;

=pod

=head1 myall.pl 

=head2 DESCRIPTION

  based loosely on Mojolicious Gist at L<https://gist.github.com/throughnothing/3726907>

  Assumes Mojolicious stuff installed - am just starting to look at this myself but looks very cool !
  See L<http://mojolicious.org/perldoc/Mojolicious/Guides/>

=head2 USAGE

    morbo ./myapp.pl
    Open browser to http://localhost:3000/auth
      should then be redirected to Xero to confirm access and redirected to http://localhost:3000/
      where if validated the app will pull the Users Xero Organisation details and
      display them.

=cut 


####    XERO API CONFIGURATION 
## NB - you will need a public application API configuration configured in Xero that includes the localhost domain
##      and will need the consumer key and secret to configure this application to talk to that access point.

## for a similar approach to the CCP::Xero test module to load the credentials
use File::Slurp;
use Config::Tiny;
my $config =  Config::Tiny->read( 'test_config.ini' );
my $pk_text = read_file( $config->{PRIVATE_APPLICATION}{KEYFILE} );

## alt - manually hard code examples - NB you would NOT expose these as ENV in production
#my $config = {
#  PUBLIC_APPLICATION => {
#    'NAME'            => 'Demo App',  ## arbitrary - ideally should match the Xero Application API Name
#    'CONSUMER_KEY'    => '',
#    'CONSUMER_SECRET' => '',
#  },
#};




get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello World!');
};


get '/xero' => sub {
  my $c = shift;
  $c->render(template => 'xero_login');
};


get '/auth' => sub {
    ## TODO: Check if have existing token
    my ( $self ) = @_;

    if (my $url = generate_xero_auth_link_with_callback( $self ) )
    {
      shift->redirect_to( $url );    
    }    
};

get '/cb' => sub {
    my ( $self ) = @_;
    ##
    ## Xero redirects the user back to this app
    ## after authenticating.
    my $xero = WebService::Xero::Agent::PublicApplication->new( 
                                                      NAME            => $config->{PUBLIC_APPLICATION}{NAME},
                                                      CONSUMER_KEY    => $config->{PUBLIC_APPLICATION}{CONSUMER_KEY}, 
                                                      CONSUMER_SECRET => $config->{PUBLIC_APPLICATION}{CONSUMER_SECRET},
    );
    my $got_access_token = 'nope';
    if ( my $token_response = $xero->get_access_token( $self->param('oauth_token'), $self->param('oauth_verifier'), $self->param('org'), $self->session->{'_oauth_token_secret'}, $self->session->{'_oauth_token'} ) )
    {
        $got_access_token = Dumper ($token_response);
        $got_access_token = $xero->api_account_organisation()->as_text();

    }    
    $self->render(template => 'cb',  # one=> $self->every_param('foo')->[0], two => $self->every_param('foo')->[0], 
      oauth_token        => $self->session->{'_oauth_token'},              ## The original access token
      oauth_token_secret => $self->session->{'_oauth_token_secret'},##   details

      access_token =>  $self->param('oauth_token'),
      oauth_verifier => $self->param('oauth_verifier'),
      org => $self->param('org'),
      got_access_token => $got_access_token,


     );

};
 


sub generate_xero_auth_link_with_callback
{
    my $self  = shift;
    my $xero = WebService::Xero::Agent::PublicApplication->new( 
                                                      NAME            => $config->{PUBLIC_APPLICATION}{NAME},
                                                      CONSUMER_KEY    => $config->{PUBLIC_APPLICATION}{CONSUMER_KEY}, 
                                                      CONSUMER_SECRET => $config->{PUBLIC_APPLICATION}{CONSUMER_SECRET},
    );
    $xero->get_request_token( 'http://localhost:3000/cb/' );
    ## Save token detail into client session cookie ( this is bad practice - should persist in local storage ) 
    ## - passing this back to client passes security responsibility back to the client with server secrets - don't do this in production env 
    ## $xero->{'oauth_token'} $xero->{'oauth_token_secret'}
    ##
    $self->session->{'_oauth_token'} = $xero->{'oauth_token'}; $self->session->{'_oauth_token_secret'} = $xero->{'oauth_token_secret'};

    return $xero->{login_url};
}

app->secrets(['sdfjkhjksJHKddf JHJDF']);

app->start;

__DATA__


@@ xero_login.html.ep
Welcome to Xero Public Application Demo Application

@@ cb.html.ep

Auth Token   = <%= $oauth_token %> <br/>
Access Token = <%= $access_token %> <br/>

oauth_token_secret = <%= $oauth_token_secret %> <br/>


oauth_verifier = <%= $oauth_verifier %> <br/>
org  = <%= $org %> <br/><br/>
$got_access_token = <%= $got_access_token %> <hr/>