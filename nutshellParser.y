%{
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include "global.h"

int yylex();
int yyerror(char *s);

// linked list
struct node {
	struct node*	next;
	char*		value;
};

struct linked_list {
	struct node	*head, **tail;
	int length;
};

struct linked_list *new_list() {
	struct linked_list *rv = malloc(sizeof(struct linked_list));
	rv -> head = 0;
	rv ->tail = &rv->head;
	return rv;
}

void push_back(struct linked_list *list, char* value) {
	struct node *node = malloc(sizeof(struct node));
	node->next = 0;
	node->value = value;
	*list->tail = node;
	list->tail = &node->next;
	list->length = list->length + 1;
}

// command driving/routing
int cmd(struct linked_list *args);

// pipe handlers
char* inHandler(struct linked_list* args1, struct linked_list* args2);
char* outHandler(struct linked_list* args1, struct linked_list* args2);
char* pipeHandler(struct linked_list* args1, struct linked_list* args2);
void appender(char* src, char* dest);
void copier(char* src, char* dest);
void printOutput();

// built in functions including helper/tester functions
int testingFunction(struct linked_list *args);
int startPrintenv();
int setEnv(char *variable, char *word);
int unsetEnv(char *variable);
int changeDirectory(char *directory);
int setAlias(char *variable, char *word);
int unsetAlias(char *variable);
int listAlias();
int setPath(char *variable, char* word);
int builtInCheck(char *input);
int isLoop(char* name, char* word);

%}

%union {char *string; struct linked_list *list;}

%start cmd_line
%token <string> TESTING STRING END IN OUT TO APPEND
%type <list> args pipes
%%

args :	STRING					{push_back($$ = new_list(), $1);}
	| args STRING				{push_back($$ = $1, $2);}
	;

pipes:	args IN args				{//printf("in args in args\n"); 
						 piping = 1; firstPipe = 1; char* fileName = inHandler($1, $3); push_back($$ = $3, fileName);}
	| args OUT args				{//printf("in args out args\n"); 
						 piping = 1; firstPipe = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| args TO args				{//printf("in args to args\n"); 
						 piping = 1; firstPipe = 1; 
						 testingFunction($1); testingFunction($3);
						 char* fileName = pipeHandler($1, $3); push_back($$ = $3, fileName);}
	| args APPEND args			{//printf("in args append args\n"); 
						 piping = 1; firstPipe = 1; appending = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes IN args				{//printf("in pipes in args\n"); 
						 piping = 1; char* fileName = inHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes OUT args			{//printf("in pipes out args\n"); 
						 piping = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes TO args				{//printf("in pipes to args\n"); 
						 piping = 1; char* fileName = pipeHandler($1, $3); push_back($$ = $3, fileName);}
	| pipes APPEND args			{//printf("in pipes append args"); 
						 piping = 1; appending = 1; char* fileName = outHandler($1, $3); push_back($$ = $3, fileName);}
	;

cmd_line :
	TESTING args END			{testingFunction($2); return 1;}
	| pipes END				{
							//printf("in pipes end\n"); 
							piping = 1;
							cmd($1);
							piping = 0;

							if(piping == 0)
							{
								printOutput();
							}

							fopen(".output.txt", "w");
							remove(".input.txt"); 
							remove(".output.txt"); 

							return 1;
						}
	| args END				{
							//printf("in args end\n");
							firstPipe = 0;
							piping = 0;
							testingFunction($1);
							cmd($1);
 
							return 1;
						}

%%

int yyerror(char *s)
{
	printf("%s\n", s);
	return 0;
}

char* inHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";
	push_back(args1, args2->head->value);
	cmd(args1);	
	copier(".output.txt", fileName);

	return fileName;
}

char* outHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";

	testingFunction(args1);
	testingFunction(args2);

	int savedStd;
	savedStd = dup(1);
	//pipeFile2 = open(args2->head->value, O_WRONLY|O_CREAT, 0666);	
	//dup2(pipeFile2, 1);
	cmd(args1);
	
	if(appending == 1)
	{
		copier(".output.txt", fileName);
		printOutput();
		appender(fileName, args2->head->value);
	}
	else
	{
		copier(".output.txt", fileName);
		copier(fileName, args2->head->value);
	}

	appending = 0;	
	fopen(".output.txt", "w");
	dup2(savedStd, 1);
	close(savedStd);

	return fileName;
}

char* pipeHandler(struct linked_list* args1, struct linked_list* args2)
{
	char* fileName = ".input.txt";

	// setting flags
	cmd(args1);
	firstPipe = 0;

	copier(".output.txt", fileName);
	fopen(".output.txt", "w");

	return fileName;
}

void copier(char* src, char* dest)
{
	/*
	int savedStd;
	int savedErr;
	savedStd = dup(1);
	savedErr = dup(2);
	dup2(savedErr, 1);
	*/

	pid_t pid;
	if((pid = fork()) == -1)
		perror("fork error\n");
	else if(pid == 0)
		execl("/bin/cp", "cp", src, dest, NULL);
	else
		wait(NULL);

	//dup2(savedStd, 1);
	//close(savedStd);
	//close(savedErr);
}

void appender(char* src, char* dest)
{
	FILE* file1;
	FILE* file2;
	char c;

	file1 = fopen(src, "r");
	file2 = fopen(dest, "a");

	if(!file1 && !file2)
	{
		printf("appending error\n");
		return;
	}

	c = fgetc(file1);
	while(c != EOF)
	{
		fputc(c, file2);
		c = fgetc(file1);
	}

	fclose(file1);
	fclose(file2);
}

void printOutput()
{
	FILE* file;
	char c;
	file = fopen(".output.txt", "r");
	c = fgetc(file);
	while(c != EOF)
	{
		printf("%c", c);
		c = fgetc(file);
	}

	fclose(file);
	fopen(".output.txt", "w");
}


int cmd(struct linked_list* args)
{
	if(firstPipe == 1)
	{
		//pipeFile1 = open("input.txt", O_WRONLY|O_CREAT, 0666);
		//pipeFile2 = open("output.txt", O_WRONLY|O_CREAT, 0666);
	}

	if(strcmp(args->head->value, "printenv") == 0){
		if(args->length == 1){
			startPrintenv();
			return 1;
		}
	}
	else if(strcmp(args->head->value, "alias") == 0){
		if(args->length == 1){
			listAlias();
			return 1;
		}
		else if(args->length == 3){
			setAlias(args->head->next->value, args->head->next->next->value);
			return 1;
		}
			printf("syntax error");
			return 1;
	}
	else if(strcmp(args->head->value, "bye") == 0){
		if(args->length == 1){
			exit(1);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "cd") == 0){
		if(args->length == 1){
			changeDirectory("");
			return 1;
		}
		else if(args->length == 2){
			changeDirectory(args->head->next->value);
			return 1;
		}

			printf("syntax error");
			return 1;
	}
	else if(strcmp(args->head->value, "unsetenv") == 0){
		if(args->length == 2){
			unsetEnv(args->head->next->value);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "unalias") == 0){
		if(args->length == 2){
			unsetAlias(args->head->next->value);
			return 1;
		}

		printf("Syntax Error");
		return 1;
	}
	else if(strcmp(args->head->value, "setenv") == 0){
		if(args->length == 3){
			setEnv(args->head->next->value, args->head->next->next->value);
			return 1;
		}

		printf("syntax error");
		return 1;
	}
	else if(strcmp(args->head->value, "alias") == 0){
		if(args->length == 3){
			setAlias(args->head->next->value, args->head->next->next->value);
			return 1;
		}
		printf("syntax error");
		return 1;
	}
	else
	{
		int savedStd;
		savedStd = dup(1);
		pid_t pid;
		int returnVal;
		const char slash = '/';
		char *path = strchr(strdup(variableTable.word[3]),slash);
		strcat(path, "/");
		strcat(path, args->head->value);

		if(firstPipe == 1)
		{
			pipeFile1 = open(".input.txt", O_WRONLY|O_CREAT, 0666);
			pipeFile2 = open(".output.txt", O_WRONLY|O_CREAT, 0666);
		}

		if((pid = fork()) == -1)
		{
			perror("fork error!");
		}
		else if(pid == 0)
		{
			int counter = 0;
			char* arguments[args->length+1];
			struct node* current = args->head;
			while (current != 0){
				arguments[counter] = current->value;
				current = current->next;
				counter += 1;
			}
			arguments[counter] = 0;
	
			if(piping == 1)
			{
				dup2(pipeFile2, 1);
				returnVal = execv(path, arguments);	
				dup2(savedStd, 1);
				close(savedStd);
			}
			else
			{
				returnVal = execv(path, arguments);
			}
		}
		else
		{
			wait(NULL);
		}

		if(returnVal == -1)
			return 0;
	}

	return 1;
}

int testingFunction(struct linked_list* args)
{
	printf("Input: ");
	struct node* current = args->head;
	while (current != 0){
		printf("%s ", current->value);
		current = current->next;
	}
	printf("\n");
	return 1;
}

int setEnv(char *variable, char *word)
{
	if(strcmp(variable, "PATH") == 0){
		printf("Handling Path\n");
		setPath(variable, word);
		return 1;
	}

	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable)  == 0)
		{
			strcpy(variableTable.word[i], word);
			return 1;
		}
	}

	strcpy(variableTable.var[variableIndex], variable);
	strcpy(variableTable.word[variableIndex], word);
	variableIndex++;
	return 1;
}

int startPrintenv()
{
	printf("environment variables:\n");
	for(int i = 0; i < variableIndex; i++)
	{
		printf("%s = %s\n", variableTable.var[i], variableTable.word[i]);
	}

	return 1;
}

int unsetEnv(char *variable)
{
	for (int i = 0; i < variableIndex; i++)
	{
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			strcpy(variableTable.var[i], variableTable.var[variableIndex - 1]);
			strcpy(variableTable.word[i], variableTable.word[variableIndex - 1]);
			variableIndex--;

			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int changeDirectory(char *directory)
{
	if (strcmp(directory,"") == 0){
		chdir(variableTable.word[1]);
		strcpy(variableTable.word[0], variableTable.word[1]);
		return 1;
	}
	else if (directory[0] != '/')
	{
		strcat(variableTable.word[0], "/");
		strcat(variableTable.word[0], directory);

		if (chdir(variableTable.word[0]) == 0) //If we succesfully change directories
		{
			return 1;
		}
		else
		{
			getcwd(cwd, sizeof(cwd));
			strcpy(variableTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else
	{
		if (chdir(directory) == 0)
		{
			strcpy(variableTable.word[0], directory);
			return 1;
		}
		else
		{
			printf("Directory not found\n");
			return 1;
		}
	}

	return 1;
}

int setAlias(char *variable, char *word)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(variable,word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], variable) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if(isLoop(variable, word)){
			printf("Error, expansion of \"%s\" would create a loop.\n", variable);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}

	strcpy(aliasTable.name[aliasIndex], variable);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}

int unsetAlias(char *variable)
{
	for(int i = 0; i < aliasIndex; i++)
	{
		if(strcmp(aliasTable.name[i], variable) == 0)
		{
			strcpy(aliasTable.name[i], aliasTable.name[aliasIndex - 1]);
			strcpy(aliasTable.word[i], aliasTable.word[aliasIndex - 1]);
			aliasIndex--;

			return 1;
		}
	}

	printf("That variable is not defined.\n");
	return 1;
}

int listAlias()
{
	printf("aliases:\n");
	for(int i = 0; i < aliasIndex; i++)
	{
		printf("%s = %s\n", aliasTable.name[i], aliasTable.word[i]);
	}
	return 1;
}

int setPath(char* variable, char* word)
{
	for (int i = 0; i < variableIndex; i++){
		if(strcmp(variableTable.var[i], variable) == 0)
		{
			int counter = 0;
			for (int j = 0; j < strlen(word); j++){
				if(strstr(&word[i],":~") == &word[i]){
					counter++;
					printf("Counter: %d\n", counter);
					j++;
				}
			}
			char *tempPath = malloc(strlen(word) + counter*(strlen(variableTable.word[1])+1));
			char *home_text = malloc(strlen(variableTable.word[1]) + 1);
			strcpy(home_text, ":");
			strcpy(&home_text[1], variableTable.word[1]);
			int iter = 0;

			while (*word) {
				if (strstr(word, ":~") == word) {
					strcpy(&tempPath[iter], home_text);
					iter += strlen(home_text);
					word += 2;
				}
				else{
					tempPath[iter++] = *word++;
				}
			}
		tempPath[iter] = '\0';

		strcpy(variableTable.word[i], tempPath);
		free(tempPath);

		}
	}
	return 1;
}

int isLoop(char *name, char* word)
{
	char* expansion = malloc(strlen(word));
	strcpy(expansion, word);
	char* old_expansion = strdup(" ");

	while(strcmp(old_expansion, expansion)){
		old_expansion = strdup(expansion);

		for(int i = 0; i < aliasIndex; i++){
			if(strcmp(aliasTable.name[i], expansion) == 0){
				expansion = strdup(aliasTable.word[i]);

			}
		}
	}

	if(strcmp(name, expansion) == 0){
		return 1;
	}

	return 0;
}
