[[HOME](http://code.google.com/p/bluecoaturl/)]

# Introduction #

_Full details of how to install will appear here..._


To get this running:

Create a database called bluecoat\_development:

`mysqladmin -u <user> -p <passwd> create bluecoat_development`

By default, the user is "root" with no password:

`mysqladmin -u root create bluecoat_development`


Change to app directory and ..

`rake db:migrate`

Create initial user within script/console

```
user = User.new(:name => 'admin', :password => 'admin', :password_confirmation => 'admin')
user.admin = true
user.save
```