typedef struct
{  
    long int type;  
    char text[BUFSIZ];  
} msg_st;

/*
// arguments
typedef struct
{
    int id;
    int msgflg;
    char *path;
    long int msgtype;
} arg_st;
*/

// get msgid from path, id, flag
//extern int getMsgID(const char *, int, int);

// parse arguments
//extern int getArgs(int , char * const [], arg_st *);