
## Snippets of backend code of BACCC Project


## Attacking honeypots
atomic-operator run --atomics-path "/opt/atomic-operator" --techniques T1110.001 --hosts "LIST_OF_IP's" --username "webuser" --password "password" --ssh_port 64295


### CLI Tools
- tshark
- termshark (/opt/termshark/termshark)
- osquery (command is osqueryi)

### Tools
- https 5601: Wazuh 
- http 8010: Splunk 
- https 8840: Nessus 
- https 8889: Velociraptor 
- https 64297: Tpot Admin Panel 

## Honeypot Setup in the cloud
1. Create a new Memory Optimized Droplet VM (32 GB RAM, 4 CPUs, 100 GB Storage) in SFO3, and run the honeypot.sh script. 

### GCP Image
1. [Create an image](https://console.cloud.google.com/compute/imagesAdd) from your new VM. This will be the base image for all VMs provisioned through this tool 1. Please include a description with basic information, such as the username/password to login, what changes are in the image, and what it's used for so it's easier to reuse if we need
2. After the image is done creating, [Create an instance template](https://console.cloud.google.com/compute/instanceTemplates/add)
   1. The name will be the name of the images. For example, if you name the instance template "fallguys-windows", the images will be named "fallguys-windows-1", "fallguys-windows-2", and so on.
   2. Set all settings that you would like in these VMs
   3. Under boot disk, click change, go to :Custom Images", and choose the image created in step 5.
   4. Set any IP settings if you need
   5. Click "Create"

