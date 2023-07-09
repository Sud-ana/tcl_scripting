
## Introduction
This is a TCL programming workshop documentation following along the program by VSD. 

Tool Command Language (Tcl) is a scripting language commonly used in various domains, including software development, system administration, and electronic design automation (EDA). Tcl is known for its simplicity, flexibility, and ease of integration with other programming languages and tools. Tcl scripting involves writing scripts in the Tcl language to automate tasks, execute commands, and manipulate data.

The overall task is divided into two key objectives:
* **SHELL SCRIPT**: Write a top level shell function to invoke the utility in linux shell
* **TCL SCRIPT**: A TCL encapsulated function .tcl file for achieving the file manipulation and formatting into the interchangeable and reusable format.

The overall objective is to use the csv file defining the design files and the **Synopsys Design Constraint** file to create a new report file in sdc format. The secondary objective is to understand the industry standard specifications for the CLOCKS, INPUTS and OUTPUTS constraints while transforming them using TCL commands. 

## Progress chart
- [x] Create the Linux command
  - [x] Create Usage description
  - [x] Create case for incorrect file name
  - [x] Create case to invoke the tcl script  
- [x] Create the framework for tcl script
  - [x] Create the case to accept the file as an argument and check it's a valid file
  - [x] Develop sections to auto-generate the output directory and file names
  - [x] Develop the section to read the CLOCKs from the constraints file and format it into the SDC defined constraints
  - [x] Develop the section to read the INPUTs from the constraints file and format it into the SDC defined constraints
  - [x] Develop the section to read the OUTPUTs from the constraints file and format it into the SDC defined constraints
- [ ] Introduction to EDA tools : Yosys, Opentimer
  - [x]  Using Yosys to synthesize a module defined in RTL to GLS to generate the synthesis netlist report in .synth.v
    - [x] Hierarchical check and error logging
  - [ ] OpenTimer tool introduction
    - [ ] Use TCL to convert the synthesis SDC netlist report in synth.v with redundant information into format[2] for openTimer tool  (or any timing tool) to consume the netlist
    - [x] Introduction to procs
      - [x] Reviewed existing procs in the utility
    - [x] SPEF file generation
    - [x] .conf file generation
  - [ ] Generating an QOR Quality of Results check report:       

## Breakdown of tasks and creating UNIX function
First we create a command that will execute the GUI. 
![Executing the TCL script](/assets/Day1_MakingExecutable_Script.png)

## Programming the TCL script
Next we start to create a TCL script for reading the input csv file and parse the contents into a variable to use throughout the code.
![Executing the TCL script](/assets/Day2_BareBonesTCL_Script.jpg)
It is useful to auto-generate the directory and filenames for the utility programmatically. This is achieved by 
* an iteration to gather and map the cell content of the input csv file
* A search and replace to replace all spaces with no space
* setting the formatted name to the values specified in the adjacent column in the excel.
  *  This is achieved by reading the csv file as a matrix and using a while {} loop
![File Variables](/assets/D2_FileVariables.jpg)
 
## Convert the constraints file into SDC format
Get the rows and columns in sdc file to make it into a matrix
![Rows and columns from SDC file](/assets/Day_2_Get_number_of_rows_columns_in_SDC_file.jpg)

One of the methods to map the CLOCK constraints is to do a rectangular search in a given area . The area is defined by the row and column numbers of the clock constraints but these are stored as different variables. The key feature of TCL that gets used in accessing them are 
* matrix search rect
* lindex
* puts -nonewline <filename> to output the formatted string into the sdc file instead of printing to terminal.
On opening the file generated, I see a snapshot of the latency and transition formatted strings as shown below:
After the CLOCK section is completely evaluated, we can take a sneak peak at the sdc file generated so far.
![CLOCK parsed in sdc file](/assets/Day3/D3_Clock_Constraints_parsed.jpg)
![Mapping the CLOCK constraints into a sdc file](/assets/Day3/D3_StartMapping_designConstraints_into_sdc_output_1.jpg)

### Convert input section
The algorithm uses the following sections
  * globbing to search for wildcard entries
  * 

![Spit the bussed lines ](/assets/D3_SplitBusLines_1.jpg)
The input ports defined as a bus are parsed and saved in a sdc format that necessitates the presence of *\** 

![Bussed signals](/assets/Bussed_InputPorts_searched_into.jpg)

### Writing constraints for the output section
```
Tcl commands used to write a loop to iterate over the rows and columns specific to OUTPUT section
  For each row which is a port, identify if the port is single signal or bussed to define is by name or name*
    Parse the ; to get the SDC formatted values. 
```
![Output Port Delay parsed](/assets/OutputPortDelays.jpg)

So this concludes the first part of tool scripts that had the following features:
* Creating a command and passing the .csv from UNIX shell to TCL script
    * Convert all the inputs to format[1] & SDC format which will be passed to Yosys synthesis tool
    * Convert format[1] & SDC to format[2] and pass to timing tool "Opentimer"
      * We will then generate a report which will be used for benchmarking . 
# Yosys and Opentimer EDA tools:
 We start the task by building a memory of word size 1 and address size 1 to represent a 2 bit memory's behavioural description in the RTL.
 ## Synthesis of GLS from RTL
 To this end we define a RTL as below:
 ![memory_module](/assets/Synthesis/memory_module.jpg)
 The yosys environment is invoked and we run a bunch of yosys synthesis configurations as below
  ![memory_module](/assets/Synthesis/memory_synthesis.jpg)
  ![memory_module](/assets/Synthesis/run_synthesis.jpg)
  This brings up the synthesized GLS with functional gates when I type *show* in the yosys prompt.
  ![memory_module](/assets/Synthesis/synthesized_GLS.jpg)

### Error checking in the hierarchy
The objective of this step is to ensure that there are no errors in the module definitions and all the instantiated modules are well connected hierarchically. The error logs and flags should be generated in case of any missing module names to direct the user to approprate debug mechanisms.
  ![memory_module](/assets/Synthesis/Hierarchy_Checked_Successfully.jpg)
  
  ## Successful synthesis execution
I use Yosys to synthesize the design and log the output into a synth.v file which is to be consumed by the timing tool for timing report generation. 
 ![memory_module](/assets/Synthesis/Creating_and_dumping_synthesis_script_openDOTys.jpg)
 ![memory_module](/assets/Synthesis/4_synthesis_logged.jpg)

 ## Procs
   Procs are used extensively in scripting for re-using parts of the code. The procedure is similar to functions in other high level languages. The procs are sourced prior to their use and defined in the sourced files. 
   Example of a proc is shown below:
  ![Proc example](/assets/Procs/1_Proc_Example.jpg)
  ![Proc_output](/assets/Procs/2_Proc_executed.jpg)

Several different procs are required to be developed for the utility, some of them are named here and are getting used to generate a conf (STA timing analysis configuration file), and some others
* reopenStdout.proc to log all the prints from the terminal standard output to a .conf file
* set_num_threads to initiate multithreading to analyze the results faster
* read_lib
* read_verilog
* read_sdc to convert the sdc constraint to open timer format.
The read_sdc proc achieves the desired functionality by parsing the CLOCKS, INPUTS , OUTPUTS sequentially one after the other. So for this part one needs to understand the syntax of the constraints and develop the proc segmented for each constraint accordingly.


## SPEF generation
SPEF file has the parasitic extraction format required for the physical design elaboration step. We just create a template spef file for the utility as shown in the output spef file dumped to the output directory.

![SPEF File Output](/assets/conf/2_spef_file_dumped.jpg)

### conf file generation
The .conf file has useful information which is used in the yosys synthesis. So the conf file is created in the TCL script that has the following paths

* path to the final synthesized netlist,
* path to spef file,
* timing files,
* standard cell
* related procs :
  * timing initialisation
  * timing report
  * worst path reports
  * threading set
The .conf generated from the TCL script is shown here:

![SPEF File Output](/assets/conf/0_conf_spef.jpg)
![SPEF File Output](/assets/conf/1_conf_file_created.jpg)

# QOR report
  The quality of the report gives a summarized report for the static timing analysis which is useful to benchmark different tools or results. 

## References
* TCL Programming Workshop for VLSI industry by VSD.
* 
