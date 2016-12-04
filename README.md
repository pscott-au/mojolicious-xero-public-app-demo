# mojolicious-xero-public-app-demo

![App Screenshot](docs/xero_public_api_demo.jpg?raw=true "Screenshot")



An example application demonstrating the use of the Perl WebService::Xero module to implement a Xero 'Public API Application'.
This example of a [Xero Public API Application](https://developer.xero.com/documentation/getting-started/public-applications/) provides a browser based application that Xero users can allow access to their accounts records. When the user authorises Xero access to the application, the application will show buttons that demonstrate access to Company Details, Contacts and Invoices.

### Requirements

  - A Xero account configured with 'Public Application' API credentials as described in the ['My Apps' Tab in the Xero Developer Portal](https://app.xero.com/Application)
  - A development environment with Perl (Linux,Windows or Mac) including an installation of the CPAN [WebService::Xero](http://search.cpan.org/~localshop/WebService-Xero/) module and the [MojoLicious](http://search.cpan.org/~sri/Mojolicious/) Real Time Web Framework

### Configuration

    git clone https://github.com/pscott-au/mojolicious-xero-public-app-demo
    cp test_config.tpl test_config.ini 
    ## edit test_config.ini to include the Xero Public App API credentials
    
### Running

    morbo ./myapp.pl
    
Open browser to http://localhost:3000/main.html to see the app wrapped in a debug container.
  OR
Open browser to http://localhost:3000/ to just see the app running without diagnostics etc.

When you click on the 'Authorise Xero' button you should then be redirected to Xero to confirm access and redirected to an authenticated application interface.


## TO DO

Currently once you have a valid session the Company details are retrieved and used to construct the welcome screen with the name of the user's company and a few buttons to access Xero API endpoints. These buttons don't do anything at the moment. I am in the process of adding this functionality to retreive and provide nicely formatted data.

## NOTES

This application includes a socket service that is used to provide diagnostic feedback to the main.html wrapper interface. This allows you to see the step-by-step protocol dialog as the Perl module negotiates the authenticated session with Xero. This socket layer is not required for you own applications and in the future I will provide some minimal starter applications that don't have this cruft.
