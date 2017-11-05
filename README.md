# gridlabd-aws
Infrastructure to support GridLAB-D on AWS platform

## Install gridlabd:
1. Open your EC2 Management Console and create an EC2 instance with at least 8 GB of storage.
2. Launch and login to your new instance.
3. Become superuser
~~~~
host% sudo su
~~~~
4. Download the install script
~~~~
host% wget https://raw.githubusercontent.com/dchassin/gridlabd-aws/master/aws-gridlabd-setup.sh
~~~~
5. Execute the script
~~~~
host% . aws-gridlabd-setup.sh
~~~~
6. Return to normal user mode
~~~~
host% <Ctrl-D>

## Run your model
1. Download and run your gridlabd model
2. Collect your output data from csv or mysql.
