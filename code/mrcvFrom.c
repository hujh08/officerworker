#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/msg.h>

#include "optparse.h"
#include "msgQ.h"

#define NUMARG_REQ 1
void HELP()
{
    printf("usage:\n");
    printf("    mrcvFrom [options] msgid\n");
}

int main(int argc, char *argv[])
{
    #define OPTHELP 0
    #define OPTPATH 1
    #define OPTNOWAIT 2
    #define OPTMTYPE 3
    optSpec opts[]={
        {"help", 'h', 0},
        {"path", 'p', 1},
        {"nowait", 'n', 0},
        {"msgtype", 't', 1},
        {NULL, '\0', 0},
    };
    optVal optv[optlen(opts)];
    int argind=optparse(argc, argv, opts, optv);
    if(argind==-1) {
        perror("error to parse options\n");
        exit(EXIT_FAILURE);
    }

    if(optv[OPTHELP].set) {
        HELP();
        exit(EXIT_SUCCESS);
    }

    if(argc-argind<NUMARG_REQ) {
        perror("no enough arguments\n");
        HELP();
        exit(EXIT_FAILURE);
    }

    key_t key;
    int id=atoi(argv[argind]);
    if(optv[OPTPATH].set) {
        key=ftok(optv[OPTPATH].val, id);
        if(key==-1) {
            perror("failed to get key");
            exit(EXIT_FAILURE);
        }
    }
    else key=(key_t) id;

    int mgetflg=0666|IPC_CREAT,
        msgid=msgget(key, mgetflg);
    if(msgid==-1) {
        perror("failed to get msgid");
        exit(EXIT_FAILURE);
    }

    // msgflag and msgtype
    int msgflg;
    long int msgtype;

    if(optv[OPTNOWAIT].set) msgflg|=IPC_NOWAIT;
    if(optv[OPTMTYPE].set) msgtype=atoi(optv[OPTMTYPE].val);


    //read message
    msg_st data;
    msgrcv(msgid, (void *)&data, BUFSIZ,
           msgtype, msgflg);

    printf("%s", data.text);

    exit(EXIT_SUCCESS);
}