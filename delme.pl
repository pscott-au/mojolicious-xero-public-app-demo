#!/usr/bin/perl

use strict;
use warnings;


use WebService::Xero::Agent::PrivateApplication;
use Data::Dumper;



my $good_key = '-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQC8Q4bRcP0qOZe2uQQRFwybzA1WW6sPoz/bDUP9E2PhaE9QsRcp
K7kgTivqVLXyX0heR06L4AiLB4C7xb/BztKgxBcdgsft+GrkVuzc/s5CSjNerKMb
4Jgvq0ENPa0u3vxx/f3iBQWZZSC8mLVcPfp1/MdLYvouapu1CRk1EJbwgwIDAQAB
AoGBAJcCMyncT7WG7MKMNU7gBiURz8DtVpD8iUPTqC1fWEZ9vOEkq0dC4wOesGsN
98Op2gqFd+OKmE+sfP4g6Gc01oztboktZ3nEEHDdyMlmO+ICrz080znKA5KXlYXP
Uoxitv2HG4+tReZdbvrrfAJjjm5nk47Pl3b8qyjoaFj/csPBAkEA4Uvi2HKtau4m
ZLDe3hEGQYeCVcQ0Gr7Ane2v5+GCVR3onSz8zpLA9B+l3lWyOymO8DoKFv1uG/bx
OAUYknjWrwJBANXrpl40LhGgK7PaU4fqgPWdQF3NnUHyYlYFz05GVoe/wf62Nt3o
DjpHmlvTRBihDR8qJqwljFrJ06faj9n2+G0CQBSuYqR74m9ubRfRJKQ969UYG17E
JARQfl4A86TVjqFBnZjQCGTuE8hVH2TJeRL1PanPqh1yJilrAbmivh6z+QECQF4h
cXWmdFchKdncSkFWeSSa64XbQkWQiKDdsZj57n2RbaXNPFttD0Wp2ExrrF1CEOoT
vCyn4RjaEp6b2AzLVgkCQGLcrg2YLJ6IOWw2ieTpupQN/rdM6dgI/3KxumQzp3Vv
/3Zcof5S/ZmoiXuaJkXqinFrYOrGMDmS2zQL/7fxl4Y=
-----END RSA PRIVATE KEY-----';

my $fake_key = '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQCu2PMZrIHPiFmZujY0s7dz8atk1TofVSTVqhWg5h/fn8tYbwgg
koTqpAigxAUCAZ63prtj9LQhIqe3TRNtCDMsxxriyN3O/cxkVD52LwCKAgEoaNmr
Vvt97UgxglKyQ6taNO/c6V8FCKvPC945GKd/b7BoIYZcJsrpo+E+8Ek9IQIDAQAB
AoGAbbPC+0XIAI0dIp256uEjZkSn89Dw8b27Ka/YeCZKs0UQEYFAiSdE6+9VVoEG
X1bi3XloM3PSHMQglJpwaMVvTUwZfdxCFIM0mpgXtdK8Xuh3QTZpgH9S0a2HoXrB
uXFEqvwMcT43ig2FCfVQU86RQZAxrb1YfyFSauEayrVtbT0CQQDe8HEXSkbxjUwj
I2TdCDA7yOW7rWQPAk3REZ33SqBUdo45qofpkH7vWSx+W6q65uyRYfF4N1JKmW8V
OhMxBpFPAkEAyMbGZ2VX6gW37g03OGSoUG6mvXe+CKRqv8hV4UoGeQIUYJTFlt2O
ukD2jKyHqWIdU/3tM3iP1b8CY6JyVyhOjwJBAJ/NmDMKohnJn9bcKxOpJ/HiypIh
8sQzcZY4W5QEYTLKHJ7HV08brXFh6VvV12bL2q1HmLAEb69bll2P2Gve+k8CQQC3
1Pi4lxwl1FKSjlsvMUrDSm01Mbw34YM0UlP/0W2XwoWx4MYB2p7ifrTAHQCh4IoF
64wSAqOADEI9w/F5SBiVAkBJVt3jNObeieMfxVU/NOtajXX51sDUj3XCIWPPui8i
IKzzVn7G0kH+/TqtTPdizrDJkg/rsnrTpvHi8eeMZlAy
-----END RSA PRIVATE KEY-----';

my $xero = WebService::Xero::Agent::PrivateApplication->new( CONSUMER_KEY    => 'JLZOFTXK5RT4VQI3U4RODEUU5Z4G3P', 
                                                          CONSUMER_SECRET => 'ZGYCRU2HFAMQCS6TOFEDX2ICY6EWME', 
                                                          #KEYFILE         => "/Users/peter/gc-drivers/conf/xero_private_key.pem" ,
                                                          PRIVATE_KEY     => $good_key
                                                          );
print $xero->as_text(), "\n--------\n";

#print my $user_org_as_text = $xero->api_account_organisation()->as_text();
 my $user_org = $xero->api_account_organisation();
 #print Dumper $user_org;

exit;



if ( $xero = WebService::Xero::Agent::PrivateApplication->new(  
                                                          CONSUMER_KEY    => 'CKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCKCK', 
                                                          CONSUMER_SECRET => 'CSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCSCS', 
                                                          #KEYFILE         => "/Users/peter/gc-drivers/conf/xero_private_key.pem"
                                                          PRIVATE_KEY => $fake_key,

                                                         
    ) )
{
  print $xero->as_text();  
  my $x = $xero->get_all_xero_products_from_xero();  
} else {
    print "failed as it should\n";
}



