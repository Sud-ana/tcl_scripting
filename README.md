
## Introduction
This is a TCL programming workshop documentation following along the program by VSD. 

Tool Command Language (Tcl) is a scripting language commonly used in various domains, including software development, system administration, and electronic design automation (EDA). Tcl is known for its simplicity, flexibility, and ease of integration with other programming languages and tools. Tcl scripting involves writing scripts in the Tcl language to automate tasks, execute commands, and manipulate data.

The overall task is divided into two key objectives:
* **SHELL SCRIPT**: Write a top level shell function to invoke the utility in linux shell
* **TCL SCRIPT**: A TCL encapsulated function .tcl file for achieving the file manipulation and formatting into the interchangeable and reusable format.

The overall objective is to use the csv file defining the design files and the **Synopsys Design Constraint** file to create a new report file in sdc format. 

## Progress chart
- [x] Create the Linux command
  - [x] Create Usage description
  - [x] Create case for incorrect file name
  - [x] Create case to invoke the tcl script  
- [ ] Create the framework for tcl script
  - [ ] Create the case to accept the file as an argument and check it's a valid file

## Breakdown of tasks and creating UNIX function
First we create a command that will execute the GUI. 
![Executing the TCL script](/assets/Day1_MakingExecutable_Script.png)

## Programming the TCL script
Next we start to create a TCL script for reading the input csv file and parse the contents into a variable to use throughout the code.
![Executing the TCL script](/assets/Day2_BareBonesTCL_Script.jpg)

## Convert the constraints file into SDC format
Get the rows and columns in sdc file to make it into a matrix
![Rows and columns from SDC file](/assets/Day_2_Get_number_of_rows_columns_in_SDC_file.jpg)


## References
* TCL Programming Workshop for VLSI industry by VSD.
* 
