#!/bin/sh

sudo yum install tree -y
sudo yum install nano -y
sudo yum -y install ntp

sudo firewall-cmd --zone=public --add-port=8140/tcp --permanent
sudo firewall-cmd --reload

sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
sudo yum -y install puppetserver
#sudo nano /etc/sysconfig/puppetserver # update JAVA_ARGS="-Xms3g -Xmx3g"

#Install required modules
sudo /opt/puppetlabs/bin/puppet module install maestrodev-wget --version 1.7.3 --modulepath /etc/puppetlabs/code/environments/production/modules/
sudo /opt/puppetlabs/bin/puppet module install puppet-archive --version 1.3.0 --modulepath /etc/puppetlabs/code/environments/production/modules/
sudo /opt/puppetlabs/bin/puppet module install crayfishx-firewalld --version 3.3.1 --modulepath /etc/puppetlabs/code/environments/production/modules/
#sudo /opt/puppetlabs/bin/puppet module install puppetlabs-apache --version 1.11.0 --modulepath /etc/puppetlabs/code/environments/production/modules/;

sudo systemctl start puppetserver #generate cert
sudo systemctl enable puppetserver.service #to enable auto-start-after-rebooting
sudo /opt/puppetlabs/bin/puppet cert list -all #confirm

#stick with absolute path of puppet
# #sudo echo 'export PATH=/opt/puppetlabs/bin:$PATH' >> ~/.bashrc #note - this happens on root not terry - for some reason!!
# #sudo source ~/.bashrc 
# sudo echo 'export PATH=/opt/puppetlabs/bin:$PATH' >> /etc/profile.d/mystuff.sh #http://www.42.mach7x.com/2012/12/17/sudo-puppet-command-not-found-when-trying-to-use-puppet-with-rvm-in-aws/comment-page-1/
# sudo chmod +x /etc/profile.d/mystuff.sh

sudo su -c 'echo "environment_timeout = 5s" >> /etc/puppetlabs/code/environments/production/environment.conf'
sudo /opt/puppetlabs/bin/puppet resource service puppet enable=true ensure=running >> /tmp/results.txt

#syntax highlighting for puppet
sudo yum install git -y
cd ~
git clone https://github.com/benpiper/puppet-nano
sudo cp puppet-nano/puppet.nanorc /root/.nanorc

