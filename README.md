# VMware Serengeti Ironfan

This is a fork of Ironfan project (created by Infochimps) to enable Ironfan work with VMware vSphere vCenter 5.0+ Enterprise Edition.

This fork of Ironfan (VMware Serengeti Ironfan) is part of VMware Serengeti Open Source project, it will be called by VMware Serengeti Server component. However, this Ironfan fork can also work standalone, please read section 'Create a vSphere cluster'.

## Major changes in VMware Serengeti Ironfan

* Refactor Ironfan code architecture to support multi cloud providers gracefully.
* Add full support for vSphere Cloud (i.e. create and manage VMs in VMware vCenter server).
* Add monitor function to Ironfan to enable Ironfan report progress of cluster operation and bootstrap to a RabbitMQ server.
* Provide a set of cookbooks for deploying a hadoop cluster in a vSphere Cloud.

## Support for Multi Cloud Providers

Currently VMware Serengeti Ironfan supports two kinds of cloud providers: vSphere and EC2.

### vSphere Cloud

vSphere Cloud Provider uses a RubyGem cloud-manager (created by VMware Serengeti project) instead of RubyGem Fog (used by EC2 Cloud Provider) to talk to vSphere vCenter server.
RubyGem cloud-manager provides the function for IaaS like cluster management, and it uses an enhanced RubyGem Fog (created by VMware Serengeti project) to talk to vSphere vCenter server.

#### Knife commands for manage a vSphere cluster

You can use the following Ironfan Knife commands to manage a vSphere cluster:
* knife cluster create CLUSTER[-FACET[-INDEX]] --yes --bootstrap
* knife cluster launch CLUSTER[-FACET[-INDEX]] --yes --bootstrap
* knife cluster show   CLUSTER[-FACET[-INDEX]] --yes
* knife cluster stop   CLUSTER[-FACET[-INDEX]] --yes
* knife cluster start  CLUSTER[-FACET[-INDEX]] --yes --bootstrap
* knife cluster ssh    CLUSTER[-FACET[-INDEX]] --yes [--no-cloud] "sudo shell_commands"
* knife cluster kill   CLUSTER[-FACET[-INDEX]] --yes
* knife cluster bootstrap CLUSTER[-FACET[-INDEX]] --yes

One outstanding change to all these commands (only when executed on a vSphere cluster) requires an additional param '-f /path/to/cluster_definition.json'.
This param specifies a json file containing the cluster definition and RabbitMQ server configuration (used by Ironfan), and configuration for connecting to vCenter (used by cloud-manager).
Take spec/data/cluster_definition.json as an example of the cluster defintion file.

#### Create a vSphere cluster

Assume you've setup a Hosted Chef Server or Open Source Chef Server and have a configured .chef/knife.rb .
<pre>
1. Copy spec/data/cluster_definition.json to ~/hadoopcluster.json
2. Open ~/hadoopcluster.json, modify the cluster definition:
     change "name", "template_id", "distro_map", "port_group" in section "cluster_definition",
     change vCenter connection configuration in section "cloud_provider", and
     don't need to change section "system_properties".
3. Append "knife[:monitor_disabled] = true" to .chef/knife.rb to disable the Ironfan monitor function.
4. Execute cluster create command:  knife cluster create hadoopcluster -f ~/hadoopcluster.json --yes --bootstrap [-V]
   This command will create VMs in vCenter for this Hadoop cluster and install specified Hadoop packages on the VMs.
5. After the cluster is created successfully, navigate to http://ip_of_hadoopcluster-master-0:50070/ to see the status of the Hadoop cluster.
6. Then, you can use other Knife commands to manage the cluster (e.g. show, bootstrap, stop, start, kill etc.).
</pre>

### EC2 Cloud

Original Infochimps Ironfan mainly supports EC2 cloud. This fork of Ironfan still provide support for EC2 cloud the same as the Infochimps Ironfan does. The only change is we must specify the cloud provider in cluster definition file, e.g. in ironfan-homebase/clusters/hadoopdemo.rb, change "Ironfan.cluster 'hadoopdemo' do" to "Ironfan.cluster :ec2, 'hadoopdemo' do" .

Please be noted that we have been focusing on vSphere support, and haven't done full test for the EC2 support.

### Support more Cloud Providers

Each cloud provider has a seperate folder to contain the necessary model classes: Cloud, Cluster, Facet, Server, ServerSlice.
For example, cloud provider for vSphere has a folder (lib/ironfan/vsphere) which contains 5 files, and each file defines a model class for vSphere cloud.
If you want to add a new cloud provider, create a folder and the model classes for it, override necessary methods defined in the base model classes. Please take vSphere cloud provider as an example when writing new cloud provider.

# Original Ironfan Created by Infochimps

Thanks very much to the original open source Ironfan project created by Infochimps (https://github.com/infochimps-labs/ironfan)

# Contact

Please send email to our mailing lists for [developers](https://groups.google.com/group/serengeti-dev) or for [users](https://groups.google.com/group/serengeti-user) if you have any questions.

