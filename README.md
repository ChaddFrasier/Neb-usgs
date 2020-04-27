# Neb-usgs
This repository is designed to serve as a helping guide to any USGS employee or contractor that need to learn how to use the compute cluster at a much faster pace than just learning from the documentation alone. Let me repeat, ALONE. That means that I expect you to read the documentation because it is your responsibility to everyone who uses Nebula to know how it allocates resources and uses CPUs and memory to complete massive workloads. Plus it really helps to understand how the WM (Workload Manager) operates.

## DISCLAIMER
**This repository could be used as a general use reference to any Slurm Workload Manager, but that being said, scripts in this repo are designed for people familiar with ISIS3 and specifically for USGS internal staff**.

*In this document I will use `(USGS)` in the headers to tell which sections are for USGS users only*

## Introduction
Nebula is a Slurm Implementation that is used by USGS Astro employees to process very large sums of data files.
The main purpose of this system is to run programs and jobs in hours on a super powerful machine to speed up a
processing task that would take weeks for a normal machine to complete.

Nebula uses Slurm to manage its resources and schedule jobs. Slurm is an open-source, highly scalable cluster management and job scheduling system for large and small Linux clusters. This system is used in many fields and has uses in many fields yet to be discovered. This document can serve as a helping hand for anyone who wants to learn more about what a system like this could be used for and how to use it yourself.

## Prerequisites (USGS)
IT has to clear you for connection to Nebula. But After you get clearance you should be able to simply ssh in using your USGS credentials.
You should use the /scratch directory to process all data because that folder has the highest priority in the workload manager configuration,
so make sure that IT creates a folder in /scratch specifically for you to access and change as you please.

## Examples
To begin any job on a Slurm WLM you must invoke the job dispatch command. `sbatch`. Look at [this link](https://slurm.schedmd.com/sbatch.html#lbAG) for some help understanding the options for slurm. I can show the most important ones in this repo.

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
#SBATCH --job-name=myjobname
#SBATCH --output=myjob.slurm.out

echo "Slurm Job run from bash script file"
echo "I can just list commands now"
```

Lastly, run the job command with the job script as the only argument.
`sbatch slurm-job.sh`

### Learn More About USGS Nebula
Reading through these sites will give you basic understanding of the controls you will need to understand and use often when testing. `Ex. 'scancel'` Some of these links will also give you a much stronger understanding of what Nebula is build using and how Nebula allocates its resources.

#### Nebula Internal Homepage ( USGS Internal Network * No Public Access *)
[USGS Employees Only](http://nebula.wr.usgs.gov/#nebula-info)

#### Slurm Workload Manager
[Slurm](https://slurm.schedmd.com/quickstart.html) is a workload managing tool that run different operations on a computer using nodes and tasks to manage the resources of the machine and run processes on multiple processors with various processing cores free to work on different jobs all at once.