%{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include "global.h"

int yylex();
int yyerror(char *s);



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



int cmd0(char* command);
int cmd1(char* command, char *input1);
int cmd2(char* command, char *input1, char* input2);
int cmd(char* command, struct linked_list *args);

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
%token <string> TESTING CMD STRING END IN OUT TO
%type <list> args
%%

args :	STRING					{push_back($$ = new_list(), $1);}
	|
	args STRING				{push_back($$ = $1, $2);}
	;

cmd_line : 
	TESTING args END			{testingFunction($2); return 1;}
	| CMD END				{cmd0($1); return 1;}
	| CMD args END				{cmd($1, $2); return 1;}

%%

int yyerror(char *s)
{
	printf("%s\n", s);
	return 0;
}

int cmd0(char* command)
{
	if(strcmp(command, "printenv") == 0){
		startPrintenv();
	}
	else if(strcmp(command, "alias") == 0){
		listAlias();
	}
	else if(strcmp(command, "bye") == 0){
		exit(1);
	}
	else if(strcmp(command, "cd") == 0){
		changeDirectory("");
	}
	else{
		// checking if not built in
		pid_t pid;
		int returnVal;
		const char slash = '/';
		
		char *path = strchr(strdup(variableTable.word[3]), slash);
		strcat(path, "/");
		strcat(path, command);
	
		if((pid = fork()) == -1)
		{
			perror("fork error!");
		}
		else if(pid == 0)
		{
			returnVal = execl(path, command, NULL);
			exit(1);
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

int cmd(char* command, struct linked_list* args)
{

	if(strcmp(command, "cd") == 0){
		if(args->length == 1){
			changeDirectory(args->head->value);
			return 1;
		}
		
		printf("syntax error");
		return 1;
	}
	else if(strcmp(command, "unsetenv") == 0){
		if(args->length == 1){
			unsetEnv(args->head->value);
			return 1;
		}
		
		printf("syntax error");
		return 1;
	}
	else if(strcmp(command, "unalias") == 0){
		if(args->length == 1){
			unsetAlias(args->head->value);
			return 1;
		}
		
		printf("Syntax Error");
		return 1;
	}
	else if(strcmp(command, "setenv") == 0){
		if(args->length == 2){
			setAlias(args->head->value, args->head->next->value);
			return 1;
		}
		
		printf("syntax error");
		return 1;
	}
	else if(strcmp(command, "alias") == 0){
		if(args->length == 2){
			setAlias(args->head->value, args->head->next->value);
			return 1;
		}
		printf("syntax error");
		return 1;
	}
	else
	{
		pid_t pid;
		int returnVal;
		const char slash = '/';
		
		char *path = strchr(strdup(variableTable.word[3]),slash);
		strcat(path, "/");
		strcat(path, command);


		if((pid = fork()) == -1)
		{
			perror("fork error!");
		}
		else if(pid == 0)
		{
			int counter = 0;
			char* arguments[args->length+2];
			struct node* current = args->head;
			strcpy(arguments[0], current->value);
			counter += 1;
			while (current != 0){
				arguments[counter] = current->value;
				current = current->next;
				counter += 1;
			}
			arguments[counter] = 0;
			
			returnVal = execv(path, arguments);
		}
		else{
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
