# racklb
Shell script for managing Rackspace Cloud Load Balancers, useful for accessing functions not available in the web dashboard:

1. Adding multiple SSL certs for SNI
2. Discovering the Servicenet ip address of your load balancers

**Usage**

1. Install jq (command-line json parser).  Packages exist for linux; Homebrew works for Mac.
2. Edit racklb-config.sh with your authentication info.
3. Run ./racklb.sh -h

**Notes**

* I have only used the script to work with cloud load balancers in ORD.  You might need to change the URLs to work with load balancers elsewhere.
* To hack more use into this, see the load balancer API docs at https://developer.rackspace.com/docs/cloud-load-balancers/v1/developer-guide/#api-reference
