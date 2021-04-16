# The Nutshell
**The Nutshell - Simon Kato & Herman Perera**

**Installation**: In our project you'll find the files needed to compile the executable as well as our makefile. It shouldn't be any different than other makefiles. 

**Features**: First we will begin with the features that we have not included, I will detail them in bullet point.

**-not implemented-**
- the & character, running commands in the background
- redirecting using 2>&1 as well as the 2>file construct

**-implemented-**
- built-in commands
- non built-in commands
- redirecting I/O with non built-in commands
- using pipes with non built-in commands
- pipes in conjunction with I/O redirection
- environment variable expansion & alias expansion
- wildcard matching
- tilde expansion

**Workload Distribution**: Simon and I distributed the work in such a way that we felt was fair. The work was broken down as follows.

Simon:
- structuring the scanner & iterating on that structure to accommodate new features and have a clean generalized flow to the parsing
- wildcard matching
- alias expansion
- environment expansion
- tilde expansion

Herman:
- dealing with piping to and fro
- I/O redirection and dealing with these two cases happening together

Both:

- we both worked on getting the initial built-in commands running
- getting non built-in commands working

**Structure of the Nutshell**: 

The nutshell will recursively construct a linked list to accept strings: commands and strings. This is done with the intention of handling a variable amount of input arguments. The linked list do not add the different types of pipes. The pipes are handled recursively given the command and arguments to the left and the right of the specific pipe token. Pipes follow their own recursion rule to handle a variable amount of pipes. 

The life of normal command will follow the following flow: the command and the arguments will be tokenized into a STRING by the lexer. The parser will catch the first STRING and then recursively build a linked list with the arguments. That is, the head will be the command and the next command is the first argument. The command will be sent to a driver function which will determine whether the command is a built-in command or if it is a non-built in command. If the command is built in, exact amount of arguments are expected, and will return error if an incorrect amount of arguments are passed in. If the command is a non-built in command, the PATH variable will be split into however many paths there are (number of colons - 1), and the program will attempt to run the command within that folder. A check is added to assert that any command is run exactly once, despite whether the function be present in multiple of the paths. The return of the non-built in command will be displayed on the console.

In the case that we need to pipe information somewhere else, I will be referring to I/O redirection as piping as well, we can recursively deal with those pipes until the end. I make use of some flags that I have defined for myself to control the flow of the execution and these three situations get dealt with using three functions called in, out, and pipe handler, each one being used of course for input, output, and pipe handling.

Other details about our shell is that we store important information in the variable and alias table, just information that the user can set and make use of (although we also make use of it in several places). Wildcard matching works just as one would expect it to in a usual shell. We include the aliases "." and ".." which represent the current directory and the previous directory, they are updated whenever cd is called. 

**Known Issues**
The tee command does not work.
Commands which would hang in standard shell will hang in our shell.
command bye must be at the end of the commands.txt that is fed into the nutshell: ie. "./nutshell < commands.txt > results.txt 2>&1", commands.txt must end in bye or there will be a bunch of syntax errors, and the command will not terminate because it's continiously printing syntax error.
Commands that do not exist 
-No prompt saying that the command did not exist, but a new line awaiting text will print
- Will cause a minor issue where you will need to type bye multiple times to exit the shell. In results.txt this will appear as having many input lines at the very end.
- This is because every child process will be created, depending on the number of paths in PATH will not be deleted. It does not cause issues in running commands since we have a check for only allowing one process to output the results of a non-built in command to account for causes where a function is present in multiple paths in the PATH variable. 
