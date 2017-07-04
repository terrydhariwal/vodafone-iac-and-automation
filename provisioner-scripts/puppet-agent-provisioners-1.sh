#!/bin/sh

sudo yum install tree -y
sudo yum install nano -y

sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum install puppet-agent -y


#sudo /opt/puppetlabs/bin/puppet agent --no-daemonize --verbose --onetime --server=default.c.graceful-matter-161422.internal
sudo /opt/puppetlabs/bin/puppet agent --no-daemonize --verbose --onetime --server=master.c.graceful-matter-161422.internal
#I don't think we need the service running for agents to poll the master server
sudo /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true 

# #this command sets the agent to poll every 1 second
# #however we need this to run after every reboot - so I will add it to /etc/init.d/puppet-daemon.sh
# sudo /opt/puppetlabs/bin/puppet agent --daemonize --verbose --server=default.c.graceful-matter-161422.internal --runinterval=1s

#stick with absolute path of puppet
# #sudo echo 'export PATH=/opt/puppetlabs/bin:$PATH' >> ~/.bashrc #note - this happens on root not terry - for some reason!!
# #source ~/.bashrc
# sudo echo 'export PATH=/opt/puppetlabs/bin:$PATH' >> /etc/profile.d/mystuff.sh
# sudo chmod +x /etc/profile.d/mystuff.sh