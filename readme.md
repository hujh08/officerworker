simple bash framework to perform concurrent jobs' running based on message passing.

# description
Concurrent jobs' running is done by 2 bash scripts, officer and worker.

Officer fetches instructions from STDIN line by line, considering to be used in bash pipe, and then transmit them one by one to several workers.

Worker is where to receive order of officer and do the specified job.

And the instruction given to officer has a format:

    task TASKID TASKCODE
    
in which:

- task: only started with 'task' is valid
- TASKID: some string to annotate what the task is
- TASKCODE: code to do a job.

    worker do job just by:
            <code>eval $TASKCODE</code>

Message passing is through message queue, which is handled by msendTo/mrcvFrom. See directory Code