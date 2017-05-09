#!/usr/bin/env perl
use Mojolicious::Lite;
use  Mojo::Log;

use WebService::Xero::Agent::PublicApplication;
use WebService::Xero::Contact;
use Data::Dumper;
use JSON::XS;
use warnings;

=pod

=head1 TITLE myapp.pl 

=head2 DESCRIPTION

  based loosely on Mojolicious Gist at L<https://gist.github.com/throughnothing/3726907>
  This code is an example of the Cpan module WebService::Xero

  Assumes Mojolicious stuff installed - am just starting to look at this myself but looks very cool !
  See L<http://mojolicious.org/perldoc/Mojolicious/Guides/>

=head2 USAGE

    morbo ./myapp.pl

    Open browser to http://localhost:3000/app/auth
      should then be redirected to Xero to confirm access and redirected to http://localhost:3000/
      where if validated the app will pull the Users Xero Organisation details and
      display them.

=cut 


####    XERO API CONFIGURATION 
## NB - you will need a public application API configuration configured in Xero that includes the localhost domain
##      and will need the consumer key and secret to configure this application to talk to that access point.

## for a similar approach to the CCP::Xero test module to load the credentials
use File::Slurp;  ## used to load the keyfile
use Config::Tiny; ## global install specific configuration parameters

my $config =  Config::Tiny->read( 'test_config.ini' );
my $pk_text = read_file( $config->{PRIVATE_APPLICATION}{KEYFILE} ) if ( defined $config->{PRIVATE_APPLICATION}{KEYFILE} and -e "$config->{PRIVATE_APPLICATION}{KEYFILE}");




## alt - manually hard code examples - NB you would NOT expose these as ENV in production
#my $config = {
#  PUBLIC_APPLICATION => {
#    'NAME'            => 'Demo App',  ## arbitrary - ideally should match the Xero Application API Name
#    'CONSUMER_KEY'    => '',
#    'CONSUMER_SECRET' => '',
#  },
#};


my $xero_sessions = {};
my $xero_session_id = 0;

my $app = app;
my $log = Mojo::Log->new( path => './log/debug.log', level => 'debug' );
$app->log($log);

$app->sessions->cookie_name('xero_testing');

my $static = $app->static;
push @{$static->paths}, ($ENV{PWD});



get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/" => sub {
  my $self = shift;
  $self->session->{'xero_session_id'} = $xero_session_id++;
  $log->debug('SETTING SESSION ID = ' .  $self->session->{'xero_session_id'} );
  $xero_sessions->{ $self->session->{'xero_session_id'} } = { 'id' => $self->session->{'xero_session_id'}, status => 'NEW' };
  
  $self->render(template => 'xero_login',
                base_url => "$config->{MOJO_APP_PARAMS}{APPLICATION_URL_BASE}", ## template adds /auth to this as target for popup and uses this as base url for images
                app_dir => $config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY},
                );

  #$self->render(text => '<a href="/auth/" target="_XERO_LOGIN">Start This Xero Session</a>This is Xero Session #' . $self->session->{'xero_session_id'} );
};


get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/xero" => sub {
  my $self = shift;
  $self->render(template => 'xero_login',
                base_url => "$config->{MOJO_APP_PARAMS}{APPLICATION_URL_BASE}", ## template adds /auth to this as target for popup and uses this as base url for images
                app_dir => $config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY},

                );
};


get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/auth" => sub {
    ## TODO: Check if have existing token
    my ( $self ) = @_;
    #warn($self->session->{'xero_session_id'} );
    update_xero_session( $self, 'GENERATING LINK');
    #$xero_sessions->{ $self->session->{'xero_session_id'}  } = { 'id' => $self->session->{'xero_session_id'}, status=> 'GENERATING LINK' };
    if (my $url = generate_xero_auth_link_with_callback( $self ) )
    {
      
      update_xero_session( $self, 'REDIRECTING TO Xero to Authorise');
      $xero_sessions->{ $self->session->{'xero_session_id'}  }{'xero_usl'} = $url;
      shift->redirect_to( $url );    
    } 
    else 
    {
      $log->debug("failed to generate callback url");
      shift->redirect_to( '/app/error');
      return undef;
    }  
};


get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/contacts" => sub {
    my ( $self ) = @_;

    my $contact_list = WebService::Xero::Contact->get_all_using_agent( agent=> $xero_sessions->{ $self->session->{'xero_session_id'} }{xero} );
    
    
    my $contacts_json = contacts_list_as_json( $contact_list );
    $self->render(template => 'contacts',
                  contacts_json => $contacts_json,
                  base_url         => $config->{MOJO_APP_PARAMS}{APPLICATION_URL_BASE}
                  );
  };

sub contacts_list_as_json
{
  my ( $contact_list ) = @_;
  ## CURRENTLY TO DUMP LIST AS JSON NEED TO DO A LITTLE DANCE
  ##  thinking about creating a container class to wrap this and an iterator ..
  my $json = new JSON::XS;
  $json = $json->convert_blessed ([1]);
  return  $json->encode( $contact_list ) ; #();
  #print to_json(@$contact_list );
}



get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/cb" => sub {
    my ( $self ) = @_;
    ##
    ## Xero redirects the user back to this app
    ## after authenticating.
    #warn($self->session->{'xero_session_id'} );
    update_xero_session( $self, 'HANDLING callback from Xero' );
    my $xero = WebService::Xero::Agent::PublicApplication->new( 
                                                      NAME            => $config->{PUBLIC_APPLICATION}{NAME},
                                                      CONSUMER_KEY    => $config->{PUBLIC_APPLICATION}{CONSUMER_KEY}, 
                                                      CONSUMER_SECRET => $config->{PUBLIC_APPLICATION}{CONSUMER_SECRET},
    );
    my $got_access_token = 'nope';
    my $user_org_as_text;
    my $org_name = '';
    my $dumper = '';
    update_xero_session( $self, 'REQUESTING ACCESS TOKEN');

    if ( my $token_response = $xero->get_access_token( $self->param('oauth_token'), $self->param('oauth_verifier'), 
                                                       $self->param('org'), $self->session->{'_oauth_token_secret'}, 
                                                       $self->session->{'_oauth_token'} ) )
    {
        $got_access_token = $token_response;
        update_xero_session( $self, 'GOT ACCESS TOKEN' );

        update_xero_session( $self, 'REQUESTING ORGANISATION DATA');
        my $org = $xero->api_account_organisation();
        $user_org_as_text = $org->as_text();
        $org_name = $org->{LegalName};
        update_xero_session( $self, 'GOT ORGANISATION DATA');
        $dumper = Dumper $org;
        $xero_sessions->{ $self->session->{'xero_session_id'} }{xero} = $xero;
        #$self->session->{xero} = $xero; ## store the agent for future use

    }    
    $self->render(template => 'cb',  # one=> $self->every_param('foo')->[0], two => $self->every_param('foo')->[0], 
      oauth_token        => $self->session->{'_oauth_token'},              ## The original access token
      oauth_token_secret => $self->session->{'_oauth_token_secret'},##   details
      access_token     =>  $self->param('oauth_token'),
      oauth_verifier   => $self->param('oauth_verifier'),
      org              => $self->param('org'),
      got_access_token => $got_access_token,
      user_org_as_text => $user_org_as_text,
      user_org_name    => $org_name,
      dumper           => $dumper,
      base_url         => $config->{MOJO_APP_PARAMS}{APPLICATION_URL_BASE},


     );

};

get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/Organisation" => sub {
  my ( $self ) = @_;
  $self->render(template => 'organisation',
                orgname => 'PETER');

};
 
get "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/main" => sub {
  my ( $self ) = @_;
  $self->render(template => 'main',
                WEBSOCKET_URL => $config->{MOJO_APP_PARAMS}{WEBSOCKET_URL});

};


sub generate_xero_auth_link_with_callback
{
    my $self  = shift;
    my $xero = WebService::Xero::Agent::PublicApplication->new( 
                                                      NAME            => $config->{PUBLIC_APPLICATION}{NAME},
                                                      CONSUMER_KEY    => $config->{PUBLIC_APPLICATION}{CONSUMER_KEY}, 
                                                      CONSUMER_SECRET => $config->{PUBLIC_APPLICATION}{CONSUMER_SECRET},
    );
    $xero->get_request_token(  "$config->{MOJO_APP_PARAMS}{APPLICATION_URL_BASE}/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/cb" );
    #$xero->get_request_token(  "http://localhost:3000/app/cb" );

    ## Save token detail into client session cookie ( this is bad practice - should persist in local storage ) 
    ## - passing this back to client passes security responsibility back to the client with server secrets - don't do this in production env 
    ## $xero->{'oauth_token'} $xero->{'oauth_token_secret'}
    ##
    $self->session->{'_oauth_token'} = $xero->{'oauth_token'}; $self->session->{'_oauth_token_secret'} = $xero->{'oauth_token_secret'};

    return $xero->{login_url};
}


### SOCKET STUFF
websocket "/$config->{MOJO_APP_PARAMS}{APPLICATION_DIRECTORY}/data" => sub {
  my $self = shift;
  $log->debug( 'Sessionid = ' . $self->session->{'xero_session_id'} );
  $xero_sessions->{ $self->session->{'xero_session_id'} }{ socket_client } = $self;

  my $loop = Mojo::IOLoop->singleton;
  $loop->stream($self->tx->connection)->timeout(1000);
  update_xero_session($self, 'WAITING FOR USER TO INITIATE AUTH');
  #my $timer = Mojo::IOLoop->recurring( 1 => sub {
  #  state $i = 0;
  #  #$self->send({ json => gen_data($i++,$self) });
  #  $self->send({ json => $xero_sessions->{ $self->session->{'xero_session_id'} } });

  #});

  $self->on( finish => sub {
    #Mojo::IOLoop->remove($timer);
    $xero_sessions->{ $self->session->{'xero_session_id'} }{ socket_client } = undef;
  });
};

sub gen_data {
  my $x = shift;
  my $self = shift;
  return [ $x, $self->session->{'xero_session_id'} , $self->session->{'_oauth_token'} ]; ##sin( $x + 2*rand() - 2*rand() )
}


=pod 

=  update_xero_session( $status ) 

Sends $status as json to socket clients ( the user application window ) 

=cut 
sub update_xero_session
{
    my ( $self, $status ) = @_;
    #return unless $self->session->{'xero_session_id'};
    $log->debug('update_xero_session:' . Dumper $status);
    $xero_sessions->{ $self->session->{'xero_session_id'} }{ status } = $status;
    if ( $xero_sessions->{ $self->session->{'xero_session_id'} }{ socket_client } )
    {
        $xero_sessions->{ $self->session->{'xero_session_id'} }{ socket_client }->send({json=> { status=>$status } });

    }
    else
    {
        $log->debug('no session socket to update ');
    }

}


=pod 


=encoding utf8

=head2 AUTHOR

 ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ 
▐░▌       ▐░▌▐░▌               ▐░▌     ▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌     
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌     ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌     
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌     
▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀      ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀       ▀▀▀▀▀▀▀▀▀█░▌▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌     
▐░▌          ▐░▌               ▐░▌     ▐░▌          ▐░▌     ▐░▌                 ▐░▌▐░▌          ▐░▌       ▐░▌     ▐░▌          ▐░▌     
▐░▌          ▐░█▄▄▄▄▄▄▄▄▄      ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌      ▐░▌       ▄▄▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌     ▐░▌          ▐░▌     
▐░▌          ▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░▌       ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌          ▐░▌     
 ▀            ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀            ▀      

=cut





app->secrets(['sdfjkhjksJHKddf JHJDF']);

app->start;

__DATA__



@@ cb.html.ep
<html>
<headh></head>
<body>
<img src="<%= $base_url %>/pie.gif">
<!--
Auth Token   = <%= $oauth_token %> <br/>
Access Token = <%= $access_token %> <br/>

oauth_token_secret = <%= $oauth_token_secret %> <br/>


oauth_verifier = <%= $oauth_verifier %> <br/>
org  = <%= $org %> <br/><br/>

AUTH TOKEN OBTAINED = <%= $got_access_token %> <hr/>
<pre>USER ORG AS TEXT <%= $user_org_as_text %></pre>
<%= $user_org_name %>

<%= $dumper %>
-->
</body>
<script>
  // the following attempts to interact with the parent cause origin issues but works behind https proxy??? not sure whats going on here.
   window.opener.document.body.style.backgroundColor = "red";
   window.opener.complete_callback("<%= $user_org_name %>");
  setTimeout(function(){
     window.close(); // comment this line out to prevent the auth popup from closing if need to diagnose
   }, 500);
  
</script>
</html>

@@ contacts.html.ep
<html>
<headh></head>
<body>

<pre>Contacts as JSON <%= $contacts_json %></pre>
</body>
</html>


@@ xero_login.html.ep
<html>
<head>
<meta http-equiv="Pragma" content="no-cache">
<title>Demo Integrated Application</title>
</head>
<body>
<div class="container" id="connect">
Sample Application Embedded in an iFrame Window
<a href="#" onClick="window.open('<%= $base_url %>/<%= $app_dir %>/auth','pagename','resizable,height=260,width=370'); return false;"><img src="<%= $base_url %>/connect_xero_button_blue.png"></a><noscript>You need Javascript to use the previous link or use <a href="/app/auth" target="_blank">New Page</a></noscript>
</div>
<hr/>
<div class="container" id="connected">
  <div class="row">
        <div class="col-md-12 panel"><div class="content lead" id="orgname"> Unknown </div></div>
  </div<
  <div class="row">
  <div class="col-md-5">
        <div class="btn-group">
          <button type="button" id='contacts_btn' class="btn ">Contacts</button>
          <button type="button" class="btn btn-warning">Organisation</button>
          <button type="button" class="btn btn-success">Invoices</button>
        </div>
  </div>
  </div>
</div>

    <script src="https://code.jquery.com/jquery-3.1.0.slim.min.js"></script>
<link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>

<script>

  function complete_callback(orgname)
  {
    $('#orgname').text(orgname);
    document.body.style.backgroundColor = "blue";
    $('#connect').hide();
    $('#connected').show();
    $('#contacts_btn').on('click', function (e) {  
        window.open('<%= $base_url %>/<%= $app_dir %>/contacts','pagename','resizable,height=560,width=670'); return false;
      });
  }

  $(function() {
    $('#connected').hide();
  });

</script>
</body>
</html>