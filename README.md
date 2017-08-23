centreon_notify_sms
=====================

To notify Centreon of hosts and services with problems by sms with AllmySMS.com

Script based on https://github.com/mathsunn/nagios_notify_sms_ovh


== Install ==
========

>cd /usr/local/  
>git clone https://github.com/jraigneau/ncentreon_notify_sms.git  
>chown -R centreon:centreon centreon_notify_sms  
>chmod u+x nagios_notify_sms_ovh/centreon_notify_sms.rb

== Summary ==
========

Small utility to send Centreon alerts on a mobile phone using AllmySMS.com API  

== Files ==
========

* centreon_notify_sms.rb => sends SMS
* config.yml => configuration file

== Sample centreon config ==
========

>define command {  
>        command_name    notify-host-by-sms  
>        command_line    /usr/bin/ruby /usr/local/nagios_notify_sms_ovh/centreon_notify_sms.rb -c >/usr/local/nagios_notify_sms_ovh/conf.yml -m host -h $HOSTALIAS$ -d "$LONGDATETIME$" -t $NOTIFICATIONTYPE$ -a $HOSTSTATE$ -e '' -n "$CONTACTPAGER$"  
>}

>define command {  
>        command_name    notify-service-by-sms  
>        command_line    /usr/bin/ruby /usr/local/nagios_notify_sms_ovh/centreon_notify_sms.rb -c /usr/local/nagios_notify_sms_ovh/conf.yml -m service -s "$SERVICEDESC$" -h $HOSTALIAS$ -d "$LONGDATETIME$" -t $NOTIFICATIONTYPE$ -a $HOSTSTATE$ -e '$SERVICEOUTPUT$' -n $CONTACTPAGER$  
>}