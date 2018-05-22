# PLUGIN IS STILL IN DEVELOPMENT. PLEASE PROVIDE INFORMATION ABOUT ANY FOUND BUGS.

# Check Huawei OceanStor plugin for Nagios
Plugin is a rework of the IBM v7000 - v7000 Unified plugin.\
Original link:\
https://exchange.nagios.org/directory/Plugins/Hardware/Storage-Systems/SAN-and-NAS/IBM-San-Volume-Controller/IBM-v7000--2D-v7000-Unified/details

It is adapted to serve as a hardware check of the Huawei OceanStor and was tested on OceanStor 2600V3.

### PLEASE HAVE IN MIND THAT YOU STILL BETTER IMPLEMENT MAIL ALARMS ON THE STORAGE ITSELF!

# 1. Installation
1. Make user on the Huawei OceanStor with read-only privileges.
2. Add public ssh key through CLI to the user on OceanStor with the command: ```change user_ssh_auth_info general user_name=your_username auth_mode=publickey```
3. It will ask for the public key, copy and paste it.
4. Make sure that user which will execute script has private key.
5. Try to execute script as user which will be checking the storage system (instructions below in Usage section)
6. Profit :)

# 2. Usage
**Check if the user which will be monitoring the storage system has the private key.**

```
/path/to/script/check_huawei_oceanstor.sh -H [host name/ip address] -U [user defined on OceanStor] -c [one of{lslun, lsdisk, lsdiskdomain, lsexpansionmodule, lsinitiator, lsstoragepool}] [-h prints help]

-H --> IP Address
-U --> user
-c --> command to storage
  lslun - show lun general status
  lsdisk - show disk general status
  lsdiskdomain - show disk_domain general status
  lsexpansionmodule - show expansiom module status
  lsinitiator - show initiator status (prints alias name for initiator)
  lsstoragepool - show storage_pool general status
-h --> Print this help screen
Note:
This check uses ssh protocol.
```
# 3. KNOWN ISSUES
1. Storage Array have active WARNING: "The number of event logs is about to reach the upper limit of 50000."\
Details: This is because all ssh logins are put into the audit log.\
Resolution: Add server for log dumps on OceanStor or go to Alarm Settings and mask alarm "The Space That Stores Event Logs Is To Be Used Up"\

# 4. TODO List
- [ ] Check if the plugin is working properly
