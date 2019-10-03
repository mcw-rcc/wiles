# RCC Implementation of XDMoD's SUPReMM module
This repo is used to deploy PCP on RCC compute nodes. PCP is a requirement of the supremm module. Changes have been made to PCP related config files. Prolog and epilog scripts have been updated to use Torque instead of Slurm. Applies to version 1.1.0 of SUPReMM.

# SUPReMM Setup

Follow https://supremm.xdmod.org/8.0/supremm-overview.html

# Changes
yum install pcp pcp-libs-devel perl-PCP-PMDA pcp-pmda-nvidia-gpu pcp-system-tools

edit cron job - pcp-pmlogger
```
#
# Performance Co-Pilot crontab entries for a monitored site
# with one or more pmlogger instances running
#
# daily processing of archive logs (with compression enabled)
10     0  *  *  *  root  /usr/libexec/pcp/bin/pmlogger_daily -M -k forever
# every 30 minutes, check pmlogger instances are running
0,30  *  *  *  *  root  /usr/libexec/pcp/bin/pmlogger_check -C
```
