# Sound-The-Alarm
A pre-built Amazon EC2 Instance and bash scripts to test New Relic Infrastructure Alerts.

The aim of this project is to enable users to quickly setup sample Infrastructure Alerts and test them by stressing the host. The idea is to be able to achieve this with a few simple commands, to understand the process of an Alert Violation, practice dealing with Violations and to give users confidence in their Alerts before targeting them at production environments.

## Dependencies

This project was built using the following technologies:

 - AWS EC2
  - `t2.micro` free tier instance
 - [stress-ng](https://wiki.ubuntu.com/Kernel/Reference/stress-ng)
 - [Bash](https://www.gnu.org/software/bash/manual/bash.html)
 - [New Relic Infrastructure Alerts](https://docs.newrelic.com/docs/infrastructure/new-relic-infrastructure/infrastructure-alert-conditions/infrastructure-alerts-add-edit-or-view-host-alert-information)

### Conditions

The example conditions created are the following, but if you already have similar conditions setup you can target them at your host. The sample stress command will violate the following condition thresholds:

- **Host Not Reporting**
  - If the host stops reporting for at least 5 minutes
- **CPU %**
  - If the CPU goes above 80% for at least 2 minutes
- **Memory Used %**
  - If the memory use goes above 40% for at least 2 minutes
- **Disk Used %**
  - If the disk use goes above 40% for at least 2 minutes
- **Total Utilization %**
  - If the total Utilization of the host storage goes above 80% for at least 2 minutes
- **Disk Read/Write Bytes**
  - If the disk Read/Write Bytes go above 200MB for at least 2 minutes
- **Process Memory Virtual Size Bytes**
  - If the VM byte size of any `stress-ng` related process goes above 20MB for at least 2 minutes


## Prerequisites

  You will need to spin up an EC2 instance using the pre-built image with all services already installed.
   - Login to AWS
   - Navigate to **EC2** -> **AMI**
   - Search in the Public AMIs for the image:
    - `ami-0325dc3f2c96dd280`
   - Launch an Instance as a `t2.micro`

## Tutorial

1. Connect to your machine via ssh.

2. Edit the New Relic Infrastructure Config file:
 - `sudo nano /etc/newrelic-infra.yml`
    - Add your license key and change any other parameters you wish. If you change the `display_name` make a note of it.
  - `CTRL+o` then `ENTER` to save
  - `CTRL+x` to exit editor


3. Restart the New Relic Infrastructure agent:
  - `sudo systemctl restart newrelic-infra`


4. Double check it is active and running:
  - `sudo systemctl status newrelic-infra`


5. **Optional:** If you don't have any alerts setup, you can use the `alerts-api` script to create some for testing. **This will automatically create conditions and thresholds that are designed to trigger with my example stress test**.

  - `alerts-api --api-key='ADMIN_APIKEY' --policy-name='SoundTheAlarm' --notification='email@domain.com' --entity-name='SoundTheAlarm'`

 This creates a policy with **By Condition and Entity** [Incident Preference](https://docs.newrelic.com/docs/alerts/new-relic-alerts/configuring-alert-policies/specify-when-new-relic-creates-incidents), a new notification channel with the email specified, along with the sample conditions. To target the `display_name` specified in your agent config change the `--entity-name=` to match it.


6. Now that your Policy and Conditions are setup, all you have to do is run the stress command.
  - `sound-the-alarm --stress-ng='--vm 1 --vm-bytes 60% --hdd 1 --hdd-bytes 80% --timeout 240s' --agent-disconnect='7m'`


7. If you created the example conditions and ran the sample `sound-the-alarm` command, your alerts should start violating.


## Configuration

#### alerts-api
  - `--api-key` or `-k` - This is your Admin API key from New Relic
  - `--policy-name` or `-p` - What you want your policy to be called, and your conditions to reference
  - `--notification` or `-n` - The email address you want to setup a notification channel for
  - `--entity-name` or `-e` - If you changed the `display_name` in the `newrelic-infra.yml` config file, you will need to declare it here. If not you can remove this or leave it blank and it will default to **SoundTheAlarm**


#### sound-the-alarm
  - `--stress-ng` or `-s` - You can use any commands from the [stress-ng manual](http://manpages.ubuntu.com/manpages/bionic/man1/stress-ng.1.html) and pass them as a string
   - `--stress-ng='-c 0 -l 80% -t 240s'` - This will put a CPU load of 85% on each CPU core on the host (setting `-c` to 0 specifies all)
   - `'--all N'` - Starts N instances of all stressors in parallel (set to 0 to match number of CPU cores)
  - `--agent-disconnect` or `-d` - This tells the script how long to disconnect the NR agent for to trigger the Host Not Reporting alert. Uses bash [sleep](https://ss64.com/bash/sleep.html) parameters.

# Contributing

Feel free to contact me with any ideas for features, or create a Pull Request if you are comfortable doing the work yourself :)
