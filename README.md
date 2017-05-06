# mojolicious-xero-public-app-demo

![App Screenshot](docs/xero_public_api_demo.jpg?raw=true "Screenshot")



An example application demonstrating the use of the Perl WebService::Xero module to implement a Xero 'Public API Application'.
This example of a [Xero Public API Application](https://developer.xero.com/documentation/getting-started/public-applications/) provides a browser based application that Xero users can allow access to their accounts records. When the user authorises Xero access to the application, the application will show buttons that demonstrate access to Company Details, Contacts and Invoices.

You can see a [working instance of this live here.](https://xero.computerpros.net.au/app/main)

This example is aimed at those providing solutions to Accounting Service Providers but is suitable as a starter for any application that requires integration with multiple external Xero accounts. 

### Requirements

  - A Xero account configured with 'Public Application' API credentials as described in the ['My Apps' Tab in the Xero Developer Portal](https://app.xero.com/Application)
  - A development environment with Perl (Linux,Windows or Mac) including an installation of the CPAN [WebService::Xero](http://search.cpan.org/~localshop/WebService-Xero/) module (Version 1.2+)  and the [MojoLicious](http://search.cpan.org/~sri/Mojolicious/) Real Time Web Framework

### Configuration

    git clone https://github.com/pscott-au/mojolicious-xero-public-app-demo
    
    cp test_config.tpl test_config.ini 

    ## edit test_config.ini to include the Xero Public App API credentials
    
### Running
  
     morbo ./myapp.pl

NB: Multi-process options such as hypnotoad not currently supported.

    
Open browser to [http://localhost:3000/app/main](http://localhost:3000/app/main) to see the app wrapped in a debug container.
  OR
Open browser to http://localhost:3000/app/ to just see the app running without diagnostics etc.

When you click on the 'Authorise Xero' button you should then be redirected to Xero to confirm access and redirected to an authenticated application interface.


### Running as a Service on Debian / Ubuntu

A quick way to create an rc.d script to run the mojo app as a system service is to use a gist as follows: 

    curl https://raw.githubusercontent.com/x13machine/ubuntu-demon-creator/master/create-demon.sh | sudo name="mojo-xero" username="peter" command="morbo /usr/local/src/mojolicious-xero-public-app-demo/myapp.pl" bash


## CURRENT STATUS

I am currently expanding this in sync with the latest development version 1.2 of [WebService::Xero](https://github.com/pscott-au/CCP-Xero). The development version is being
refactored to include classes that describe Xero components and encapsulate the data in more detail than a simple struct or json object.
In order to run in a production environment with hypnotoad, an approach to interprocess communication is required because the current approach of using a global variable to contain all the socket connections will not be shared across multi-processes. See [Issue#1](https://github.com/pscott-au/mojolicious-xero-public-app-demo/issues/1) for more details.

## TO DO

* Currently once you have a valid session the Company details are retrieved and used to construct the welcome screen with the name of the user's company and a few buttons to access Xero API endpoints. **These buttons don't do anything at the moment.** 
* I am in the process of adding this functionality to retreive and provide nicely formatted data.
* Need to find a way to properly communicate how all of the components of this system interact - am considering use of https://p5js.org/ to create an animated model.


## NOTES

This application includes a socket service that is used to provide diagnostic feedback to the main.html wrapper interface. This allows you to see the step-by-step protocol dialog as the Perl module negotiates the authenticated session with Xero. This socket layer is not required for you own applications and in the future I will provide some minimal starter applications that don't have this cruft.

The use of websockets introduces some new issues that I will discuss in the future with regard to SSL etc. Ideally we will provide a fully worked example with a container microservice and various configuration options to proxy through requests to this etc.

