#ifndef COMMAND_H
#define COMMAND_H

typedef struct {
  int in;
  int out;
  int err;
  // int argc;
  char** argv;
} command_data;

/* Sets optind while consuming --command args */
command_data parse_command(int argc, char **argv, int *opt);

/* Executes a command */
int command(command_data data);

int openPipe();

/* Wait for all child processes to finish */
int wait_all(void);

/* Allocate storage for argv array */
void initCommand(void);
/* Free storage, wait for child process if wait_flag is set, show usage
 * information if profile_flag is set */
int endCommand(int wait_flag, int profile_flag);

#endif /* COMMAND_H */
