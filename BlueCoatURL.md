[[HOME](http://code.google.com/p/bluecoaturl/)]

# Introduction #

This is an application to manage the local URL database for [BlueCoat SG Proxy devices](http://www.bluecoat.com/products/sg/index.html).  It has been written in Ruby on Rails.  The main features are:
  * Allows specified people to manage URLs in categories
  * Admin users can manage categories, proxy devices and user access
  * Deployment users can arrange for proxies to update with the latest configuration


# Details #

To install you must have Rails installed.  You will also need the RMagick and net-ssh gems.

By default, the application expects to connect to a mysql database.  Create the databases:
  * bluecoat\_development
  * bluecoat\_test
  * bluecoat\_production

You will only need the production database for deployment, however it is always good practive to have a development installation to ensure that upgrades can be tested in your environment before you upgrade your live system.

The supplied configuration assumes that you will use MySQL with the default login credentials.  If you change your database or how you log in to it, then you will need to update config/database.yml accordingly.

After you load the schema, you'll need to create an initial admin user.

See the [Installation Guide](InstallationGuide.md) for full details on how to install and setup the application.

To enable your BlueCoat proxies to update from the application, point them at /url/downloadurllist beneath the application's main URL.  This address is used to access the config in the correct format for the device.  No user authentication is required.

If you have a configuration already that you wish to import, there is an option available for you to upload this into the application.

The BlueCoat proxy only allows for a scheduled download **once** per day; the deployment option allows specified users to deploy on-demand.

[[HOME](http://code.google.com/p/bluecoaturl/)]