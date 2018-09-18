= Create the tqa-launch-benchmark job =

* Create a new pipeline job
* Select ``Pipeline script from SCM``
* Repository URL ``git@github.com:exoplatform/bench-lab.git``
* Credentials : `` git (SSH key for Github repositories (ciagent))``
* Branches to build : ``*/ITOP-3476_dirty``
* Script Path : ``jenkins/Jenkinsfile_jmeter-tqa``

Execute the job one time to retrieve the configuration and have the parameters declared.

