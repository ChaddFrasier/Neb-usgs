# Neb-usgs
##### THIS REPOSITORY COULD BE USED AS A GENERAL REFERENCE FOR SLURM USERS
**That being said scripts in this repo are designed for people familiar with ISIS3**
-------------------------------------------------------------------------------------
This repository is designed to serve as a helping guide to any USGS employee or contractor that need to learn how to use the compute cluster at a much faster pace than just learning from the documentation alone. Let me repeat, ALONE. That means that I expect you to read the documentation because it is your responsibility to everyone who uses Nebula to know how it allocates resources and uses CPUs and memory to complete massive workloads. Plus it really helps to understand how the WM (Workload Manager) operates.


## Introduction
Intro to Nebula and what it is and what it is used for.


## Prerequisites
List of things that need to be accomplished before running a job.


### Examples

#### Single Command Line Task
`sbatch --job-name=EchoExampleJob --wrap="echo 'Slurm Job Ran'" --output=output-job-%j.out`

**Important** Must use keyword `--wrap` to tell WLM that you are sending a string as a command instead of a file.
Other arguments are:
1.  `--job-name`: The name of the job so you can see its progress using the command `squeue`.
2. `--output`: The name of the output file. can also be a path to specify where to place the log file.


#### Simple Batch File
First you must prepare a script to pass to the WLM.
In what ever path you wish to run the job in, create a file called `slurm-job.sh` that contains these lines and comments

```
#!/bin/bash
# File Desc: This is a test file for a Slurm job.

#SBATCH --partition=<SOME PARTITION> # required for most architectures but varies for every Slurm instance
#SBATCH --job-name=myjob
#SBATCH --output=myjob.slurm.out

echo "Slurm Job run from bash script file"
echo "I can just list commands now"
```

Lastly, run the job command with the job script as the only argument.
`sbatch slurm-job.sh`


### Learn More About Nebula
Reading through these sites will give you basic understanding of the controls you will need to understand and use often when testing. `Ex. 'scancel'` Some of these links will also give you a much stronger understanding of what Nebula is build using and how Nebula allocates its resources.

#### Nebula Internal Homepage ( USGS Internal Network * No Public Access *)
[USGS Employees Only](http://nebula.wr.usgs.gov/#nebula-info)

#### Slurm Workload Manager
[Slurm](https://slurm.schedmd.com/quickstart.html) is a workload managing tool that operates using nodes and tasks to organize and run processes on multiple processors with various processing cores possibly working on different tasks.