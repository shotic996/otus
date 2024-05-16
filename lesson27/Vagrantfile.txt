# -*- mode: ruby -*-
# vim: set ft=ruby :
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
:inetRouter => {
        :box_name => "centos/7",
        #:public => {:ip => '10.10.10.1', :adapter => 1},
        :net => [
                   {ip: '192.168.255.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                ]
  },
  :centralRouter => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.255.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                   {ip: '192.168.100.1', adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "office1-net"},
                   {ip: '192.168.200.1', adapter: 4, netmask: "255.255.255.252", virtualbox__intnet: "office2-net"},
                   {ip: '192.168.0.1', adapter: 5, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
                   {ip: '192.168.0.33', adapter: 6, netmask: "255.255.255.240", virtualbox__intnet: "hw-net"},
                   {ip: '192.168.0.65', adapter: 7, netmask: "255.255.255.192", virtualbox__intnet: "mgt-net"},
                ]
  },
   :centralServer => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.0.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
                   {adapter: 3, auto_config: false, virtualbox__intnet: true},
                   {adapter: 4, auto_config: false, virtualbox__intnet: true},
                ]
  },
  :office1Router => {
        :box_name => "centos/7",
        :net => [
				   {ip: '192.168.100.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "office1-net"},
                   {ip: '192.168.2.1', adapter: 3, netmask: "255.255.255.192", virtualbox__intnet: "office1_dev-net"},
                   {ip: '192.168.2.65', adapter: 4, netmask: "255.255.255.192", virtualbox__intnet: "office1_test_srv-net"},
                   {ip: '192.168.2.129', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "office1_mngrs-net"},
                   {ip: '192.168.2.193', adapter: 6, netmask: "255.255.255.192", virtualbox__intnet: "office1_hw-net"},
                ]
  },
   :office1Server => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.2.194', adapter: 2, netmask: "255.255.255.192", virtualbox__intnet: "office1_hw-net"},
                   {adapter: 3, auto_config: false, virtualbox__intnet: true},
                   {adapter: 4, auto_config: false, virtualbox__intnet: true},
                ]
  },
  :office2Router => {
        :box_name => "centos/7",
        :net => [
				   {ip: '192.168.200.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "office2-net"},
                   {ip: '192.168.1.1', adapter: 3, netmask: "255.255.255.128", virtualbox__intnet: "office2_dev-net"},
                   {ip: '192.168.1.129', adapter: 4, netmask: "255.255.255.192", virtualbox__intnet: "office2_mngrs-net"},
                   {ip: '192.168.1.193', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "office2_hw-net"},
                ]
  },
   :office2Server => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.1.194', adapter: 2, netmask: "255.255.255.192", virtualbox__intnet: "office2_hw-net"},
                   {adapter: 3, auto_config: false, virtualbox__intnet: true},
                   {adapter: 4, auto_config: false, virtualbox__intnet: true},
                ]
  }  
  
  
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|

        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s

        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
        
        if boxconfig.key?(:public)
          box.vm.network "public_network", boxconfig[:public]
        end

        box.vm.provision "shell", inline: <<-SHELL
          mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
		  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
		  sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
          systemctl restart sshd
          systemctl stop firewalld
          systemctl disable firewalld
          sed -i 's/=enforcing/=disabled/' /etc/selinux/config
          setenforce 0
          yum install -y vim mc tcpdump traceroute net-tools
        SHELL
        
        case boxname.to_s
        when "inetRouter"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            sysctl net.ipv4.conf.all.forwarding=1
            iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
			echo '192.168.0.0/16 via 192.168.255.2 dev eth1' > /etc/sysconfig/network-scripts/route-eth1
			ip route add 192.168.0.0/16 via 192.168.255.2 dev eth1
            SHELL
        when "centralRouter"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo net.ipv4.conf.all.forwarding=1 >> /etc/sysctl.conf
            echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
			/sbin/sysctl -p /etc/sysctl.conf
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
			echo '192.168.2.0/24 via 192.168.100.2 dev eth2' > /etc/sysconfig/network-scripts/route-eth2
			echo '192.168.1.0/24 via 192.168.200.2 dev eth3' > /etc/sysconfig/network-scripts/route-eth3
			systemctl restart network
			ip route del default
			ip route add default via 192.168.255.1 dev eth1
			ip route add 192.168.2.0/24 via 192.168.100.2 dev eth2
			ip route add 192.168.1.0/24 via 192.168.200.2 dev eth3
            SHELL
        when "centralServer"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
			ip route del default
			ip route add default via 192.168.0.1 dev eth1 
            SHELL
		when "office1Router"
		  box.vm.provision "shell", run: "always", inline: <<-SHELL
		    echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            echo net.ipv4.conf.all.forwarding=1 >> /etc/sysctl.conf
            echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
			/sbin/sysctl -p /etc/sysctl.conf
		    echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
			echo "GATEWAY=192.168.100.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
			ip route add default via 192.168.100.1 dev eth1
			systemctl restart network
            SHELL
		when "office1Server"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.2.193" >> /etc/sysconfig/network-scripts/ifcfg-eth1
			ip route add default via 192.168.2.193 dev eth1
            systemctl restart network
            SHELL
		when "office2Router"
		  box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo net.ipv4.conf.all.forwarding=1 >> /etc/sysctl.conf
            echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
			/sbin/sysctl -p /etc/sysctl.conf
		    echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
			echo "GATEWAY=192.168.200.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
			ip route add default via 192.168.200.1 dev eth1
			systemctl restart network
            SHELL
		when "office2Server"
          box.vm.provision "shell", run: "always", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            echo "GATEWAY=192.168.1.193" >> /etc/sysconfig/network-scripts/ifcfg-eth1
			ip route add default via 192.168.1.193 dev eth1
            systemctl restart network
            SHELL
        end

      end

  end
  
  
end
