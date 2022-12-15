# Salt Project

I had installed vagrant on my Windows desktop before this project and decided not to do it again.
Vagrant can be downloaded from https://developer.hashicorp.com/vagrant/downloads

I made a new Debian 11 virtual machine with GUI with basically the same instructions as I used in my previous homework from another course (task a, https://tatuheikkinen655017050.wordpress.com/2022/08/31/h1/).
This machine is used as a salt minion

## Configure master

I opened a new powershell with administrator priviledges on my Windows 10 machine and made a new vagrant init

	PS C:\Users\tatuh\saltproject> vagrant init
	
I edited Vagrantfile to configure a new Debian 11 virtual machine without a GUI to use as a salt master

	PS C:\Users\tatuh\saltproject> notepad.exe .\Vagrantfile
	PS C:\Users\tatuh\saltproject> cat .\Vagrantfile
	# -*- mode: ruby -*-
	# vi: set ft=ruby :
	# Copyright 2019-2021 Tero Karvinen http://TeroKarvinen.com

	$tscript = <<TSCRIPT
	set -o verbose
	apt-get update
	apt-get -y install tree
	echo "Done - set up test environment - https://terokarvinen.com/search/?q=vagrant"
	TSCRIPT

	Vagrant.configure("2") do |config|
		config.vm.synced_folder ".", "/vagrant", disabled: true
		config.vm.synced_folder "shared/", "/home/vagrant/shared", create: true
		config.vm.provision "shell", inline: $tscript
		config.vm.box = "debian/bullseye64"

		config.vm.define "t001" do |t001|
			t001.vm.hostname = "master"
			t001.vm.network "private_network", ip: "192.168.88.101"
		end
	
	end
	
After making the configurationfile I started and connected to the master virtual machine

	PS C:\Users\tatuh\saltproject> vagrant up
	PS C:\Users\tatuh\saltproject> vagrant ssh t001
	
After connecting I installed salt-master
	
	master:~$ sudo apt-get update
	master:~$ sudo apt-get -y install salt-master
	
After installing salt-master I checked masters hostname

	master:~$ hostname -I
	10.0.2.15 192.168.88.101
	
## Configure minion

I started my other virtual machine and installed salt-minion

	taulu:~$ sudo apt-get update
	taulu:~$ sudo apt-get -y install salt-minion
	
I tried to ping the master 
	
	taulu:~$ ping 192.168.88.101
	
After pinging the master succesfully with the minion I needed to connect them to trust each other

## Connecting master and minion

I started by defining the ip address of the master for the minion and giving the minion easily recognizable id

	taulu:~$ sudoedit /etc/salt/minion
	taulu:~$ cat /etc/salt/minion
	master: 192.168.88.101
	id: minion-salt-project
	taulu:~$ sudo systemctl restart salt-minion.service
	
I switched back to master and accepted the new salt key

	master:~$ sudo salt-key -A
	The following keys are going to be accepted:
	Unaccepted Keys:
	minion-salt-project
	Proceed? [n/Y] y
	Key for minion minion-salt-project accepted.
	
And I tested the connection

	master:~$ sudo salt '*' cmd.run 'whoami'
	minion-salt-project:
		root
		
## Hello Salts World

After implementing master-slave architechture I wanted to test it with the simplest state possible, one line state

I checked on minion I didn't have the file I was going to create with salt

	taulu:$ cat /tmp/hellosalt
	cat: /tmp/hellosalt: No such file or directory

I used master to make and apply the state

	master:~$ sudo salt '*' state.single file.managed /tmp/hellosalt contents="Hello Salt!"
	minion-salt-project:
	----------
			  ID: /tmp/hellosalt
		Function: file.managed
		  Result: True
		 Comment: File /tmp/hellosalt updated
		 Started: 19:07:59.755453
		Duration: 6.804 ms
		 Changes:
				  ----------
				  diff:
					  New file

	Summary for minion-salt-project
	------------
	Succeeded: 1 (changed=1)
	Failed:    0
	------------
	Total states run:     1
	Total run time:   6.804 ms

After applying the state I tried to cat the file again on minion

	taulu:~$ cat /tmp/hellosalt
	Hello Salt!
	
## First state in a file

After confirming that i can apply states to minion I could start to write state files 
but first I needed to make a directory for salt states

	master:~$ sudo mkdir /srv/salt/
	master:~$ cd /srv/salt/
	master:/srv/salt$ sudo mkdir musthavesoftware
	master:/srv/salt$ cd musthavesoftware/

I wanted to install micro text editor first with salt because I knew from previous experience how it is done

First I made sure I didn't have micro installed

	taulu:~$ micro
	bash: micro: command not found
	
And then I wrote the first version of the init.sls

	master:/srv/salt/musthavesoftware$ sudoedit init.sls
	master:/srv/salt/musthavesoftware$ cat init.sls
	micro:
	  pkg.installed
	
And it was time to apply the stage

	master:/srv/salt/musthavesoftware$ sudo salt '*' state.apply musthavesoftware
	
I tested if micro had been installed on the minion

	taulu:~$ cat helloworld
	cat: helloworld: No such file or directory
	taulu:~$ micro helloworld
	taulu:~$ cat helloworld
	Hello World!

Micro had been installed successfully and it was time to add more things to install to the state

## More sowtware from package manager

Due to previous experience and low time to complete the project I decided to skip some small tests because they were basically copying the steps needed for installing micro with salt 

	master:/srv/salt/musthavesoftware$ sudoedit init.sls
	master:/srv/salt/musthavesoftware$ cat init.sls
	micro:
	  pkg.installed

	bash-completion:
	  pkg.installed

	webext-ublock-origin-firefox:
	  pkg.installed

	keepassxc:
	  pkg.installed

	git:
	  pkg.installed
	  
After updating the state I ran it again

	master:$ sudo salt '*' state.apply musthavesoftware
	Summary for minion-salt-project
	------------
	Succeeded: 5 (changed=4)
	Failed:    0
	------------
	Total states run:     5
	Total run time:  16.580 s
	
Test results of the previous installations are not shown at this time because they are done again and shown in a later part of this report

## Adding KeePassXC password file

I made a new password database on my windows machine for keepass and saved it in vagrant shared folder. 
I copied the file for salt to use

	master:/srv/salt/musthavesoftware$ sudo cp /home/vagrant/shared/Passwords.kdbx /srv/salt/musthavesoftware/

Then I edited salt state

	master:/srv/salt/musthavesoftware$ cat init.sls
	micro:
	  pkg.installed

	bash-completion:
	  pkg.installed

	webext-ublock-origin-firefox:
	  pkg.installed

	keepassxc:
	  pkg.installed

	git:
	  pkg.installed

	/home/Passwords.kdbx:
	  file.managed:
		- source: "salt://musthavesoftware/Passwords.kdbx"
		
I switched to minion and checked if I had the file

	taulu:~$ ls /home/
	Passwords.kdbx  tatu
  
## Final tests for the working version of salt state

These tests have been done with empty Debian 11 installation with the instructions from https://tatuheikkinen655017050.wordpress.com/2022/08/31/h1/ task a. 
This virtual machine has been added to use the master-slave architechture

  table:~$ micro
  bash: micro: command not found
  table:~$ keepassxc
  bash: keepassxc: command not found
  table:~$ git
  bash: git: command not found
  table:~$ ls /home/
  tatu
  
  ![image](https://user-images.githubusercontent.com/52470440/207757506-d1835144-530e-4111-9b06-027dc9a63c5e.png)
  
### In the beginning none of the wanted software had been installed (I didn't find out how I can prove bash-completion working/not working)

  master:/srv/salt/musthavesoftware$ sudo salt 'saltproject' state.apply musthavesoftware
  saltproject:
  ----------
            ID: micro
      Function: pkg.installed
        Result: True
       Comment: The following packages were installed/updated: micro
       Started: 02:28:08.161098
      Duration: 2583.17 ms
       Changes:
                ----------
                micro:
                    ----------
                    new:
                        2.0.8-1+b6
                    old:
  ----------
            ID: bash-completion
      Function: pkg.installed
        Result: True
       Comment: The following packages were installed/updated: bash-completion
       Started: 02:28:10.747499
      Duration: 2540.848 ms
       Changes:
                ----------
                bash-completion:
                    ----------
                    new:
                        1:2.11-2
                    old:
  ----------
            ID: webext-ublock-origin-firefox
      Function: pkg.installed
        Result: True
       Comment: 1 targeted package was installed/updated.
       Started: 02:28:13.291641
      Duration: 1752.655 ms
       Changes:
                ----------
                webext-ublock-origin-firefox:
                    ----------
                    new:
                        1.42.0+dfsg-1~deb11u1
                    old:
  ----------
            ID: keepassxc
      Function: pkg.installed
        Result: True
       Comment: The following packages were installed/updated: keepassxc
       Started: 02:28:15.052646
      Duration: 3035.99 ms
       Changes:
                ----------
                keepassxc:
                    ----------
                    new:
                        2.6.2+dfsg.1-1
                    old:
  ----------
            ID: git
      Function: pkg.installed
        Result: True
       Comment: The following packages were installed/updated: git
       Started: 02:28:18.091962
      Duration: 2103.714 ms
       Changes:
                ----------
                git:
                    ----------
                    new:
                        1:2.30.2-1
                    old:
  ----------
            ID: /home/Passwords.kdbx
      Function: file.managed
        Result: True
       Comment: File /home/Passwords.kdbx updated
       Started: 02:28:20.197263
      Duration: 26.786 ms
       Changes:
                ----------
                diff:
                    New file
                mode:
                    0644

  Summary for saltproject
  ------------
  Succeeded: 6 (changed=6)
  Failed:    0
  ------------
  Total states run:     6
  Total run time:  12.043 s  
  
Now I only needed to check if I could use the installed software

  ![image](https://user-images.githubusercontent.com/52470440/207759350-54720fc7-3b5a-44cb-bfcd-8eeddb18d834.png)
  
All of the installed software worked like they were supposed to

Sources:

https://terokarvinen.com/2022/palvelinten-hallinta-2022p2/

https://github.com/miljonka/Palvelinten-hallinta/wiki/h7_Oma-projekti



