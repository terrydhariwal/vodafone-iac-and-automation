# Vodafone Cassandra POC
This project is designed to quickly spin up a Cassandra POC.
It manages the creation of virtual machines and the installation of the requisite software and load generation tools.

## Vodafone Cassandra Infra As Code and Automation


This section contains the steps to spin up virtual machines on Google Cloud, that will be pre-installed with Puppet for automation.

There are 4 parts to automate the installation of Cassandra and the application servers

* Part 1: <strong>Infrastructure as Code </strong>
* Part 2: <strong>Puppet Configuration Management</strong>
* Part 3: <strong>Initialising the Cassandra cluster</strong>
* Part 4: <strong>Starting the load-generator</strong>

## Part 1: Infrastructure as Code
1. Navigate to the [GCP console](https://console.cloud.google.com)
2. Login as ``cloudshellpythian@gmail.com``
3. Activate Google Cloud Shell ![Google Cloud Shell](images/activate-google-cloud-shell.png)
4. In the home directory there are 2 files and 1 directory of interest
	* The <strong>gcp_credentials.json</strong> file, which contains credentials for automating the spinning up of virtual machines on Google Cloud
	* The <strong>terraform</strong> binary, which is a infrastructure as code software
	* This repository <strong>vodafone-iac-and-automation</strong>, which contains all the files needed to automate the installation of Cassandra
5. Run the following commands to spin up our base-line virtual machines
	* ``cd vodafone-iac-and-automation/``
	* Running ``~/terraform plan`` will display the infrastructure changes to be made. Essentially 5 virtual machines will be created
		* 1 Puppet Master server
		* 3 Cassandra servers (Puppet agents)
		* 1 Spark/Java server (Puppet agent)
	* Run ``~/terraform apply`` to create these VMs. This will take approximately 5 minutes
	* Finally, the console will output the <strong>ssh</strong> commands to connect to these machines. 
	* Sample output looks like this (make a note of this as you'll need these for the next section:
	
```
ssh_command_master = ssh -i ~/.ssh/id_rsa terry@x.x.x.x
ssh_command_node = ssh -i ~/.ssh/id_rsa terry@x.x.x.x
ssh_command_node2 = ssh -i ~/.ssh/id_rsa terry@x.x.x.x
ssh_command_node3 = ssh -i ~/.ssh/id_rsa terry@x.x.x.x
ssh_command_spark = ssh -i ~/.ssh/id_rsa terry@x.x.x.x
```

Note, the servers have fully qualified domain names, making each server accessible to one another within the private network. Here are the domain names:

* <strong>Puppet Master</strong>
	* master.c.graceful-matter-161422.internal
* <strong>Cassandra nodes </strong>
	* node.c.graceful-matter-161422.internal
	* node2.c.graceful-matter-161422.internal
	* node3.c.graceful-matter-161422.internal 
* <strong>Application nodes</strong>
	* spark.c.graceful-matter-161422.internal

## Part 2: Puppet Configuration Managemnent

In the last section you create the base-line VMs pre-installed with Puppet.

In this section, you will use puppet to install Cassandra and the Spark/Java application servers.

### Configuring the Pupper Master

The puppet master holds the necessary instructions to install Cassandra, Spark and any other programs required for this POC

The Puppet clients/agents (Cassandra and application servers) will pull these instructions and execute them.

The clients pull this information over a secure SSL connection. For this to work, the master server needs to sign the client SSL certificates. Follow these instructions to complete this process:

* First ssh into the master node using the saved output from part 1 ```ssh -i ~/.ssh/id_rsa terry@x.x.x.x```
* To see which client certificates have requested certificate signing use following command
	
```
sudo /opt/puppetlabs/bin/puppet cert list -all
```
	
The output will look something like this
	
```
	+ "master.c.graceful-matter-161422.internal" (SHA256) 27:F6:93:4D:45:34:27:4A:57:4C:48:04:BD:25:1E:31:B3:A8:F2:BC:B7:83:1A:7E:86:9F:A5:88:68:6B:95:23 (alt names: "DNS:puppet", "DNS:master.c.graceful-matter-161422.internal")
	- "node.c.graceful-matter-161422.internal"   (SHA256) 32:9B:00:E8:30:F0:1F:0A:D9:41:E5:DD:A6:A1:83:50:E6:95:0B:CF:4C:AA:F3:52:97:4F:2F:3E:CD:42:B9:EE
	- "node2.c.graceful-matter-161422.internal"  (SHA256) 17:9C:6C:AE:BF:17:1E:74:2B:57:5E:8F:78:E2:A1:F6:7D:7E:AD:42:54:2A:BA:4B:37:5B:AF:D4:63:D3:FC:A7
	- "node3.c.graceful-matter-161422.internal"  (SHA256) FA:15:7C:0A:FB:5C:3B:58:CC:EE:BC:C7:CB:0E:4C:5E:C8:1D:2A:6C:EE:F7:17:0F:12:1A:50:88:97:63:4C:DD
	- "spark.c.graceful-matter-161422.internal"  (SHA256) 95:B1:93:6D:07:1D:27:76:81:74:58:AE:65:51:4E:B6:1B:EA:43:1B:24:6E:58:D9:82:A7:A3:3D:EC:44:A2:8C
```
	
	The ``-`` symbol indicates that the certificates are not yet signed

* To sign each certifcate run the following command

```
sudo /opt/puppetlabs/bin/puppet cert sign node.c.graceful-matter-161422.internal; \
sudo /opt/puppetlabs/bin/puppet cert sign node2.c.graceful-matter-161422.internal; \
sudo /opt/puppetlabs/bin/puppet cert sign node3.c.graceful-matter-161422.internal; \
sudo /opt/puppetlabs/bin/puppet cert sign spark.c.graceful-matter-161422.internal
```

Thats it for the master node. You can exit the server.

### Installing Cassandra and Spark servers

This step is very simple as everything is automated using Puppet. 

Simply run the following 2 steps for each Cassandra server:

* ssh to the server using the saved output from part 1 
* Run the following command
	
```
sudo /opt/puppetlabs/bin/puppet agent --test --server=master.c.graceful-matter-161422.internal
```
	
The installation will complete in approximately 3-4 minutes
	

## Part 3: Initialising the Cassandra cluster

<strong>Start Cassandra on Node 1</strong>

* ssh into the first Cassandra server (node.c.graceful-matter-161422.internal)
* ```sudo su - cassandra -c "/opt/apache-cassandra/bin/cassandra" ```
* Wait approximately 2 minutes
* confirm Cassandra has started and initialised using 

```
watch -n 2 /opt/apache-cassandra/bin/nodetool -p 7199 status
```
	
You should see output similar to this:
	
```
Datacenter: datacenter1
=======================
Status=Up/Down |/ State=Normal/Leaving/Joining/Moving	
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.5  103.73 KiB  256          100.0% 0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
```
	
As you can see there is currently once node in the cluster.
	
``UN`` indicates that the node is up and normal
	
``Owns`` represents the amount of data this server is responsible for. Since there is only one node - it is responsible for 100% of the data

<strong>Start Cassandra on Node 2</strong>
	
* Repeat this for node2 (node2.c.graceful-matter-161422.internal)
* Ensure you wait at least 2 minutes before confirming the node is also up and runninng
* confirm the 2nd node is up and normal 

``/opt/apache-cassandra/bin/nodetool -p 7199 status``
	
You should see output similar to this:
	
```
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.5  69.99 KiB  256          100.0%            0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  112.85 KiB  256          100.0%            eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
As you can see both nodes are responsible for 100% of the data. This is because of replication - each server contains a full copy of the data
	
	
<strong>Start Cassandra on Node 3</strong>
	
* Repeat this for node3 (node3.c.graceful-matter-161422.internal)
* Ensure you wait at least 2 minutes before confirming the node is also up and runninng
* confirm the 2nd node is up and normal 

``/opt/apache-cassandra/bin/nodetool -p 7199 status``
	
You should see output similar to this:
	
```
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.128.0.3  64.53 KiB  256          67.5%             60aae62f-c740-4b2e-bffe-536b88c65fa4  rack1
UN  10.128.0.5  74.94 KiB  256          66.5%             0a37dbe0-967f-453c-926e-6d4ff2887da9  rack1
UN  10.128.0.6  92.81 KiB  256          66.0%             eba6db25-5f41-4ae3-9a2c-4025cc91e02a  rack1
```
Now the cluster has been fully created and is ready to accept load.
	
As you can see every node is responsible for ~66% of the data.
	
	
## Part 4: <strong>Starting the load-generator</strong>

Finally, we are ready to configure our load generator.

The load generator is split into 2 parts. 

* Part 1: creating the vodafone keyspace and tables for the seed data
* Part 2: seeding Cassandra with real data from a csv file
* Part 3: reading this seed data to simulate live time series updates

### Part 1: Creating the seed Keyspace and Tables

On Node1 of the Cassandra cluster, do the following

* First you need to prepare a Cassandra keyspace and table for the seed data
* ``git clone https://cleverbitsio@bitbucket.org/cleverbitsio/vodafone-source-data-load.git``
* ``cd vodafone-source-data-load/``
* ``/opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal``
* ``SOURCE 'CQL-commands.sql'``
* This sql file will create a keyspace called ``vodafone`` and a table called ``vodafone.prod`` which will hold the seed data

### Part 2: Seeding the data

* ssh to the application server
* ``cd ~/vodafone-source-data-load/``
* ``sudo /opt/apache-spark/bin/spark-submit --class "com.cleverbits.io.spark_examples.Vodafone" --master local /home/terry/vodafone-source-data-load/target/spark-examples-0.0.1-SNAPSHOT.jar``
* Confirm that the seed data has been written to ``vodafone.prod``

On Node 1, using cqlsh run the following query to count the number of rows in ``vodafone.prod``
	
```
SELECT COUNT(*) FROM vodafone.prod ;
```
	
You should see output similar to
	
```
cqlsh> SELECT COUNT(*) FROM vodafone.prod ;
 count
-------
  9949
(1 rows)
```

### Part 3: Start the load generator

Now we've seeded Cassandra with our source data, you can now run the load-generator, which will read this source data and simulate time series writes to another table called ``vodafone.load``

* on the application server do the following
* ``cd /home/terry/vodafone-client-rest``
* ``java -cp /home/terry/vodafone-client-rest/target/cassandra-client-rest-service-0.1.0.jar CassandraClientREST.Application &``
* ``wget http://localhost:8080/runBashFile?writespersecond=18``
* Confirm that the simulate writes are being written to ``vodafone.load`` using by


```
watch -n 1 "/opt/apache-cassandra/bin/cqlsh node.c.graceful-matter-161422.internal -e 'select count(*) from vodafone.load'"
```
	
You should see output similar to
	
```
 count
-------
   972
(1 rows)
```
	
If you run it again, you'll see the count has increased
	
## The POC environment is ready for executing our runbooks

Now you have a fully functioning cluster, with time series data being written to it.

The next step is to run the POC runbooks (see the folder ``cassandra-runbooks``)