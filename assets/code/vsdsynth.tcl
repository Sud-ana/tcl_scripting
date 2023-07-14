#! /bin/env tclsh
#-------------------------------------------------------------------------------------------------------------------#
#-----------------------------------------Checks for vsdsynth correct usage ----------------------------------------#
#-------------------------------------------------------------------------------------------------------------------#

set enable_prelayout_timing 1
set working_dir [exec pwd]
puts "In TCL script working from $working_dir"
set vsd_array_length [llength [split [lindex $argv 0] .]]
set input [lindex [split [lindex $argv 0] .] $vsd_array_length-1]

puts "Start parsing a csv file and understanding the input file $argv "

if {![regexp {^csv} $input] || $argc!=1 } {
	puts "Error in usage"
	puts "Usage: ./vsdsynth <.csv>"
	puts "here <.csv> file has below inputs"
	exit
} else {
	puts "Start parsing csv file"
# ------------------------------------------------------------------------------------------------------------------------------------------------------#
# ---------------- converts .csv to matrix and creates initial variables "DesignName OutputDirectory NetlistDirectory EarlyLibraryPath LateLibraryPath--#
# -------------------If you are modifying this script, please use above variables as starting point. Use "puts" command to report the above variable ---#
# ------------------------------------------------------------------------------------------------------------------------------------------------------#

	set filename [lindex $argv 0]
	package require csv
	package require struct::matrix
	struct::matrix m
	set f [open $filename]
	csv::read2matrix $f m , auto
	close $f
	set columns [m columns]
	m link my_arr
	set num_of_rows [m rows]
	set i 0
	while {$i < $num_of_rows} {
		puts "\nInfo: Setting $my_arr(0,$i) as '$my_arr(1,$i)'"
		if {$i==0} {
			set [string map {" " ""} $my_arr(0,$i)] $my_arr(1,$i)
			#puts "In cell 0"
			#puts "Reiterating the assignment: [string map {" " ""} $my_arr(0,$i)] : $my_arr(1,$i)"
		} else { 
			set [string map {" " ""} $my_arr(0,$i)] [file normalize $my_arr(1,$i)]
			#puts "In cel !=0"
			#puts "Reiterating the assignment: [string map {" " ""} $my_arr(0,$i)] : [file normalize $my_arr(1,$i)]"
		}	
		  set i [expr {$i+1}]
	}
}

puts "\nInfo: Below are the list of initial variables and their values. User can use these variables for further debug. Use 'puts <variable name>' command to query value of below variables."
puts "DesignName = $DesignName"
puts "OutputDirectory = $OutputDirectory"
puts "NetlistDirectory = $NetlistDirectory"
puts "EarlyLibraryPath = $EarlyLibraryPath"
puts "LateLibraryPath = $LateLibraryPath"
puts "ConstraintsFile = $ConstraintsFile"

# ------------------------------------------------------------------------------------------------------------------------------------------------------#
# -------------------------------- Below script checks if directories and files mentioned in csv file exist or not -------------------------------------#
# -------------------- Use above variables as starting point . -----------------------------------------------------------------------------------------#
if {! [file exists $EarlyLibraryPath]} {
	puts "\nError: Cannot find early cell library in pat $EarlyLibraryPath. Exiting.... "
	exit
} else {
	puts "\nInfo: Early cell library found in path $EarlyLibraryPath"
}

if {! [file exists $LateLibraryPath]} {
	puts "\nError: Cannot find early cell library in pat $LateLibraryPath. Exiting.... "
	exit
} else {
	puts "\nInfo: Early cell library found in path $LateLibraryPath"
}

if {! [file exists $OutputDirectory]} {
	puts "\nError: Cannot find early cell library in pat $OutputDirectory. Exiting.... "
	file mkdir $OutputDirectory
	exit
} else {
	puts "\nInfo: Early cell library found in path $OutputDirectory"
}

if {! [file exists $NetlistDirectory]} {
	puts "\nError: Cannot find early cell library in pat $NetlistDirectory. Exiting.... "
	exit
} else {
	puts "\nInfo: Early cell library found in path $NetlistDirectory"
}
if {! [file exists $ConstraintsFile]} {
	puts "\nError: Cannot find early cell library in pat $ConstraintsFile. Exiting.... "
	exit
} else {
	puts "\nInfo: Early cell library found in path $ConstraintsFile"
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------------------------- Constraint File Creations  ------------------------------------------------------------------------------#
#------------------------------------------------- SDC FILE FORMAT  ----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Dumping SDC constraints for $DesignName"
# Create a matrix name 
::struct::matrix constraints 
# Give a channel identifier to the item which is a open constraints file handle.
set chan [open $ConstraintsFile]
csv::read2matrix $chan constraints , auto
close $chan
set number_of_rows [constraints rows]
puts "number of rows = $number_of_rows"
set number_of_columns [constraints columns]
puts "number of columns = $number_of_columns"

# Extract index of each port keyword in the constraint file as each wil need diffennt 
# ------ check ro number for "clocks" and column number for "IO delays and slew rate selection " in constraints.csv ------ #
#  {0 0} -> 0 0 -> 0 as search retuns {0 0 }
set clock_start [lindex [lindex [constraints search all CLOCKS] 0] 1]
puts "clock_start = $clock_start"
set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0] 0]
puts "clock_start_column = $clock_start_column"

#--------- Check row number for  "inputs" section in constraints.csv--------------#
set input_ports_start [lindex [lindex [constraints search all INPUTS] 0] 1]
puts "input_ports_Start = $input_ports_start"

#--------- Check row number for  "outputs" section in constraints.csv--------------#
set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0] 1]
puts "output_ports_Start = $output_ports_start"

##----------------------------- clock constraints --------------------------------##
#----------------------------- clock latency constraints --------------------------#
######  Search a rectangle in a matrix area;  column 1, row 1 to column2 row 2 to get the "clock early rise delay" start cell and then loop through all the "CLOCKS" sections
# ----------------------------------- Get the CLOCK delay constraints --------------------------------------------#

set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_delay] 0 ] 0]

set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_delay] 0 ] 0]

set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_delay] 0 ] 0]

set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_delay] 0 ] 0]

# ----------------------------------- Get the CLOCK transition constraints --------------------------------------------#
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_slew] 0 ] 0]

set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_slew] 0 ] 0]

set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_slew] 0 ] 0]

set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_slew] 0 ] 0]

# ----------------------------------- Get the Frequency and Duty cycle constraints --------------------------------------------#

set clock_frequency_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] frequency] 0 ] 0]

set clock_duty_cycle_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] duty_cycle] 0 ] 0]

#  ----------------------------------- Get the INPUTS constraints --------------------------------------------#
## $number_of_colums-1 as the INPUTS has one fewer column than maximum returend by columns query for CLOCKSs which is overall max in the code. 
## Search for the string as shown below
set input_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_delay] 0 ] 0]
set input_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_delay] 0 ] 0]
set input_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_delay] 0 ] 0]
set input_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_delay] 0 ] 0]

set input_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_slew] 0 ] 0]
set input_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_slew] 0 ] 0]
set input_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_slew] 0 ] 0]
set input_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_slew] 0 ] 0]

set related_clock [lindex [lindex [constraints search rect $clock_start_column $input_ports_start [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] clocks] 0 ] 0]

# ---------- Ceate a new file in the output directory in write mode to store the SYNOPSYS DESIGN CONSTRAINT .sdc file ----------#
set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]
set i [expr {$clock_start+1}]
set end_of_ports [expr {$input_ports_start-1}]
puts "\nInfo-SDC: Working on clock constraints......"
while {$i < $end_of_ports } {
	puts "Today is day 3 & SSM has currently progressed to parsing the CLOCK section of the sdc constraints file for cell [constraints get cell 0 $i] "
	puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell $clock_frequency_start $i] -waveform \{0 [expr {[constraints get cell $clock_frequency_start $i]*[constraints get cell $clock_duty_cycle_start $i]/100}]\} \[get_ports [constraints get cell 0 $i]\]"
	#puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell 1 $i] -waveform \{0 [expr {[constraints get cell 1 $i]*[constraints get cell 2 $i]/100}]\} \[get_ports [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -rise -min [constraints get cell $clock_early_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_early_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -rise -max [constraints get cell $clock_late_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_transition -fall -max [constraints get cell $clock_late_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
	set i [expr {$i+1}]
	}

set i [expr {$input_ports_start+1}]
set end_of_ports [expr {$output_ports_start-1}]
puts "\nInfo-SDC: Working on IO constraints ...."
puts "\nInfo-SDC: Categorizing input ports as bits and bussed. "

while { $i < $end_of_ports} {
# ---------------------------------------------------------- Differentiating the input ports as bussed and bits ------------------------------- #
	#Categorize input ports as bits and bussed from the verilog file 
	# Glob for wildcard search, $netlist has all the files handles
	# DEBUG THIS SECTION BASED ON D3 L5-6 as to why the tmp file is not storing all the INPUT port names instances. It must search all the files in the verilog folder and get the number of instances of bussed signals 
set netlist [glob -dir $NetlistDirectory *.v] 
#set tmp_file [open /tmp/1 w]
set tmp_file [open /tmp/1 a]
foreach f $netlist {
	set fd [open $f]
	puts "reading file $f"
	while {[gets $fd line] != -1} {
		set pattern1 " [constraints get cell 0 $i];"
		if {[regexp -all -- $pattern1 $line]} {
			#puts "pattern1 \"$pattern1\" found and matching line in verilog file \"$f\" is \"$line\""
			set pattern2 [lindex [split $line ";"] 0]
			#puts "creating pattern2 by splitting pattern1 using semi-colon as delimiter => \"$pattern2\""
			if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
			#puts "Out of all patterns, \"$pattern2\" has matring string \"input\". So preserving this line and ignoring others."			
			set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
			#puts "printing first 3 elements of pattern2 as \"$s1\" using space as delimiter"
			# WHY AM I UNABLE TO WRITE TO THE TMP_FILE APART FROM FIRST ITERATION ONLY ? LINE 201 has write instead of append
			puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"		
			#puts "replace multiple spaces in s1 by single space and reformat as \"[regsub -all {\s+} $s1 " "]\""
			}
		}
	}
close $fd
}
close $tmp_file
#--------------------------------------------------------------------------------------------------------------##
#--------------------------------- Create Input delay and slew constraints  ------------------------------------#
#---------------------------------------------------------------------------------------------------------------#

set tmp_file [open /tmp/1 r]
#puts "reading [read $tmp_file]"
#puts "reading /tmp/1 file as [split [read $tmp_file] \n]"
#puts "sorting /tmp/1 contents as [lsort -unique [split [read $tmp_file] \n]]"
#puts "joining /tmp/1 as [join [lsort -unique [split [read $tmp_file] \n]] \n]"
set tmp2_file [open /tmp/2 w]
puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
close $tmp_file
close $tmp2_file
set tmp2_file [open /tmp/2 r]
#puts "count is [llength [read $tmp2_file]] "
set count [llength [read $tmp2_file]]
#puts "splitting content of tmp_2 using space and counting number of elements as $count"
if {$count >2} {
	set inp_ports [concat [constraints get cell 0 $i]*]
	puts "bussed"
} else {
	set inp_ports [constraints get cell 0 $i]
	puts "not bussed"
}
	puts "input port name is $inp_ports since count is $count\n"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $inp_ports\]"


	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $inp_ports\]"
	puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $inp_ports\]"

	set i [expr {$i+1}]
}
#This above { is for the while loop in line 195 for processing bit and bussed lines 
close $tmp2_file

#--------------------------------------------------------------------------------------------------------------##
#--------------------------------- Create output delay and load constraints ------------------------------------#
#---------------------------------------------------------------------------------------------------------------#

set output_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_rise_delay] 0 ] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_fall_delay] 0 ] 0]
set output_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_rise_delay] 0 ] 0]
set output_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_fall_delay] 0 ] 0]
set output_load_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] load] 0] 0]
set related_clock [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] clocks] 0] 0]
set i [expr {$output_ports_start+1}]
set end_of_ports [expr {$number_of_rows}]
#puts "\noutput_early_rise_delay_start = $output_early_rise_delay_start"
#puts "\noutput_early_fall_delay_start = $output_early_fall_delay_start"
#puts "\noutput_late_rise_delay_start = $output_late_rise_delay_start"
#puts "\noutput_late_fall_delay_start = $output_late_fall_delay_start"
puts "\nInfo-SDC: Working on IO constraints........"
puts "\nInfo-SDC: Categorizing output ports as bits and bussed"

while { $i < $end_of_ports} {
# ---------------------------------------------------------- Differentiating the input ports as bussed and bits ------------------------------- #
set netlist [glob -dir $NetlistDirectory *.v] 
set tmp_file [open /tmp/1 w]
foreach f $netlist {
	set fd [open $f]
	puts "reading file $f"
	while {[gets $fd line] != -1} {
		set pattern1 " [constraints get cell 0 $i];"
		if {[regexp -all -- $pattern1 $line]} {
			#puts "pattern1 \"$pattern1\" found and matching line in verilog file \"$f\" is \"$line\""
			set pattern2 [lindex [split $line ";"] 0]
			#puts "creating pattern2 by splitting pattern1 using semi-colon as delimiter => \"$pattern2\""
			if {[regexp -all {output} [lindex [split $pattern2 "\S+"] 0]]} {
			#puts "Out of all patterns, \"$pattern2\" has matring string \"input\". So preserving this line and ignoring others."			
			set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"
			#puts "printing first 3 elements of pattern2 as \"$s1\" using space as delimiter"
			# WHY AM I UNABLE TO WRITE TO THE TMP_FILE APART FROM FIRST ITERATION ONLY ? LINE 201 has write instead of append
			puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"		
			#puts "replace multiple spaces in s1 by single space and reformat as \"[regsub -all {\s+} $s1 " "]\""
			}
		}
	}
close $fd
}
close $tmp_file
set tmp_file [open /tmp/1 r]
set tmp2_file [open /tmp/2 w]
puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
close $tmp_file
close $tmp2_file
set tmp2_file [open /tmp/2 r]
set count [split [llength [read $tmp2_file]] " "]
if {$count >2} {
	set op_ports [concat [constraints get cell 0 $i]*]
	puts "bussed"
} else {
	set op_ports [constraints get cell 0 $i]
	puts "not bussed"
}
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $op_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $op_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $op_ports\]"
	puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $op_ports\]"
	set i [expr {$i+1}]
}
close $tmp2_file
close $sdc_file

puts "\nInfo: SDC created. Please use constraints in path $OutputDirectory/$DesignName.sdc"
#------------------------------------------------*-------------------------------------------------------------##
#------------------------------------------------Hierarchy check------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------#

puts "\nInfo: Creating hierarchy check script to be used by Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
#puts "data is \"$data\""
set filename "$DesignName.hier.ys"
#puts "filename \"$DesignName.hier.ys\""
set fileId [open $OutputDirectory/$filename "w"]
#puts "fileId [open $OutputDirectory/$filename\" in write mode"
puts -nonewline $fileId $data
set netlist [glob -dir $NetlistDirectory *.v]
puts "netlist is \"$netlist\""
foreach f $netlist {
	set data $f
	puts "data is \"$f\""
	#puts "\nread_verilog $f"
	puts -nonewline $fileId "\nread_verilog $f"
}
puts -nonewline $fileId "\nhierarchy -check"
close $fileId
#puts -nonewline $fileId "\nhierarchy -check"
#close $fileId

puts "\nclose \"$OutputDirectory/$filename\"\n"
puts "\nChecking hierarchy.................................."
set my_err [catch {exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} msg]
puts "err flag is $my_err"
if {[catch { exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log} msg]} {
	set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
	#puts "log file name is $filename"
	set pattern {referenced in module}
	#puts "pattern is $pattern"	
	set count 0
	set fid [open $filename r]
	while {[gets $fid line] != -1} {
		incr count [regexp -all -- $pattern $line]
		if {[regexp -all -- $pattern $line]} {
			puts "\nError: module [lindex $line 2] is not part of design $DesignName.Please correct RTL in the path '$NetlistDirectory'"
			puts "\nInfo: Hierarchy check FAIL"		
		}	
	}
	close $fid
} else {
	puts "\nInfo: Hierarchy check PASS"
	}
puts "\nInfo: Please find hiearchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more info."
cd $working_dir

#------------------------------------------------*-------------------------------------------------------------##
#--------------------------------------- Main Synthesis script -------------------------------------------------#
#---------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Creating main synthesis script to be used by Yosys"
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"
set filename "$DesignName.ys"
set fileId [open $OutputDirectory/$filename "w"]
puts -nonewline $fileId $data

set netlist [glob -dir $NetlistDirectory *.v]
foreach f $netlist {
	set data $f
	puts -nonewline $fileId "\nread_verilog $f"	
}
puts -nonewline $fileId "\nhierarchy -top $DesignName"
puts -nonewline $fileId "\nsynth -top $DesignName"
#puts -noneline $fileId "\nsplitnets -ports -format __\ndfflibmap -liberty ${LateLibraryPath}\nopt" DISTINGUISH BETEEEN BITS AND BUS
puts -nonewline $fileId "\nsplitnets -ports -format ___\ndfflibmap -liberty ${LateLibraryPath}\nopt"
puts -nonewline $fileId "\nabc -liberty ${LateLibraryPath} "
puts -nonewline $fileId "\nflatten"
puts -nonewline $fileId "\nclean -purge\niopadmap -outpad BUFX2 A:Y -bits\nopt\nclean"
puts -nonewline $fileId "\nwrite_verilog $OutputDirectory/$DesignName.synth.v"
close $fileId
puts "\nInfo: Synthesis script created and cn be accessed from path $OutputDirectory/$DesignName.ys"

puts "\nInfo: Running synthesis....................................."
#------------------------^^^^


#------------------------------------------------*-------------------------------------------------------------##
#--------------------------------------- Run Synthesis script using YOSYS --------------------------------------#
#---------------------------------------------------------------------------------------------------------------#

if {[catch { exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]} {
	puts "\nError: Synthesis failed due to errors. Please refer to log $OutputDirectory/$DesignName.synthesis.log for errors"
	exit
} else {
	puts "\nInfo: Synthesis fnished successfully"	
}
puts "\nInfo: Please refer to log $OutputDirectory/$DesignName.synthesis.log"


#------------------------------------------------*-------------------------------------------------------------##
#--------------------------------------- Edit synth.v to be usabe by Opentimer----------------------------------#
#---------------------------------------------------------------------------------------------------------------#
# Using tmp directory as it refreshes automaticaly for intermediate files
set fileId [open /tmp/1 "w"]
# The below line will dump the output of synth.v all lines that don't have a * and dump it to temporary file
puts -nonewline $fileId [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]
close $fileId

set output [open $OutputDirectory/$DesignName.final.synth.v "w"]

set filename "/tmp/1"
set fid [open $filename r]
	while {[gets $fid line] != -1} {
		puts -nonewline $output [string map {"\\" ""} $line]
		puts -nonewline $output "\n" 	
	}
close $fid
close $output

puts "\nInfo: Please find the synthesized netlist for $DesignName at below path. You can use this netlist for STA Or PNR"
puts "\n$OutputDirectory/$DesignName.final.syth.va"


#}
#------------------------------------------------*-------------------------------------------------------------##
#--------------------------------------- Static Timing Analysis using Opentimer---------------------------------#
#---------------------------------------------------------------------------------------------------------------#
puts "\nInfo: Timing Analysis Started .........................."
puts "\nInfo: Initiaizing number of threads, libraries, sdc, verilog netlist path........"
# Source the reopenStdout proc so that it can be used later on in the script
source /home/vsduser/vsdsynth/procs/reopenStdout.proc
source /home/vsduser/vsdsynth/procs/set_num_threads.proc
#Start logging all puts from standard terminal output file to the .conf file from here as reopenStdout is invoked
reopenStdout $OutputDirectory/$DesignName.conf
set_multi_cpu_usage -localCpu 4
source  /home/vsduser/vsdsynth/procs/read_lib.proc
read_lib -early /home/vsduser/vsdsynth/osu018_stdcells.lib

read_lib -late /home/vsduser/vsdsynth/osu018_stdcells.lib

source /home/vsduser/vsdsynth/procs/read_verilog.proc
read_verilog $OutputDirectory/$DesignName.final.synth.v

source /home/vsduser/vsdsynth/procs/read_sdc.proc
read_sdc $OutputDirectory/$DesignName.sdc
reopenStdout /dev/tty


#---------------------------------- Writing the SPEF file for parasitic compoenents ------------------------------#
if {$enable_prelayout_timing == 1 } {
	puts "\nInfo: enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"
	set spef_file [open $OutputDirectory/$DesignName.spef w]
puts $spef_file "*SPEF \"IEEE 1481-1998\" "
puts $spef_file "*DESIGN \"$DesignName\" "
puts $spef_file "*DATE \"Sun July 7 9:00:00 2023\" "
puts $spef_file "*VENDOR \"VSD TCL WORKSHOP\" "
puts $spef_file "*PROGRAM \"Benchmark Parsitic Extractor\" "
puts $spef_file "*VERSION \"0.0\" "
puts $spef_file "*DESIGN_FLOW \"NETLIST_TYPE_VERILOG\" "
puts $spef_file "*DIVIDER / "
puts $spef_file "*DELIMITER : "
puts $spef_file "*BUS_DELIMITER [ ] "
puts $spef_file "*T_UNIT 1 PS "
puts $spef_file "*C_UNIT 1 FF "
puts $spef_file "*R_UNIT 1 KOHM "
puts $spef_file "*L_UNIT 1 UH "
}
close $spef_file

#-------------------------------------- Writing contents of SPEF file to .conf file for STA -------------------------#

set conf_file [open $OutputDirectory/$DesignName.conf a]
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "
close $conf_file

# -------------------------------------------------- Section to extract OOR ------------------------------------------#
set tcl_precision
set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results} 1]
puts "time_elapsed_in_us is $time_elapsed_in_us"
set time_elapsed_in_sec "[expr {[lindex $time_elapsed_in_us 0]/1000000}]sec"
puts "time_elapsed_in_sec is $time_elapsed_in_sec"
puts "\nInfo: STA finished in $time_elapsed_in_sec seconds"
puts "\nInfo: Refer to $OutputDirectory/$DesignName.results for warnings and errors"

#----------------------------- Find worst output violation from timing report file -------------------------------------#
set worst_RAT_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {RAT}
while {[gets $report_file line] != -1} {
	if {[regexp $pattern $line]} {
		set worst_RAT_slack "[expr {[lindex $line 3]/1000}]ns"
		break			
	} else {
		continue		
		}	
}
close $report_file
#----------------------------- finding the number of output violations $pattern: RAT  ------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
	incr count [regexp -all -- $pattern $line]
}
set Number_output_violations $count
close $report_file

#----------------------------- Find worst setup violations -------------------------------------#
set worst_negative_setup_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}
while {[gets $report_file line] != -1} {
	if {[regexp $pattern $line]} {
		set worst_negative_setup_slack "[expr {[lindex $line 3]/1000}]ns"
		break			
	} else {
		continue		
		}	
}
close $report_file
#----------------------------- finding the number of setup violations $pattern: SETUPU  ------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
	incr count [regexp -all -- $pattern $line]
}
set Number_of_setup_violations $count
close $report_file

#----------------------------- Find worst hold violations -------------------------------------#
set worst_negative_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}
while {[gets $report_file line] != -1} {
	if {[regexp $pattern $line]} {
		set worst_negative_hold_slack "[expr {[lindex $line 3]/1000}]ns"
		break			
	} else {
		continue		
		}	
}
close $report_file
#----------------------------- finding the number of hold violations $pattern: Hold ------------------------------------#
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
	incr count [regexp -all -- $pattern $line]
}
set Number_of_hold_violations $count
close $report_file

#----------------------------- Find number of instance -------------------------------------#
set pattern {Num_of_gates}
set report_file [open $OutputDirectory/$DesignName.results r]
while {[gets $report_file line] != -1} {
	if {[regexp -all -- $pattern $line]} {
		set Instance_count [lindex [join $line " "] 4 ]
		break	
	} else {
		continue	
		}
}
close $report_file
# Proof that the QOR report can be generated for each design and not just this one.
#set Instance_count "$Instance_count ErrorMsg"
#set worst_negative_hold_slack "$worst_negative_hold_slack DUMMYns"
 
puts "PRINTING VERTICAL DESIGN QOR REPORTS"
puts "DesignName is \{$DesignName\}"
puts "time_elapsed_in_sec is \{$time_elapsed_in_sec\}"
puts "Instance_count is \{$Instance_count\}"
puts "worst_negative_setup_slack is \{$worst_negative_setup_slack\}"
puts "Number_of_setup_violations is \{$Number_of_setup_violations\}"
puts "worst_negative_hold_slack is \{$worst_negative_hold_slack\}"
puts "Number_of_hold_violations is \{$Number_of_hold_violations\}"
puts "worst_RAT_slack is \{[format {%0.4f} [lindex [split $worst_RAT_slack ns] 0]]ns\}"
puts "Number_output_violations is \{$Number_output_violations\}"

#set TEMPORARY_RAT "[format {%0.4f} [lindex [split $worst_RAT_slack ns] 0]]ns"
#puts $TEMPORARY_RAT

puts "\n"
puts "							***************PRELAYOUT TIMING RESULTS*****************"
set formatStr {%15s%15s%15s%15s%15s%15s%15s%15s%15s}
puts [format $formatStr "-----------"  "-------"  "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
puts [format $formatStr "Design Name"  "Runtime"  "Instance Count" "WNS setup" "FEP Setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT"]
puts [format $formatStr "-----------"  "-------"  "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]

foreach design_name $DesignName runtime $time_elapsed_in_sec  instance_count Instance_count  wns_setup $worst_negative_setup_slack fep_setup $Number_of_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_of_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
	puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}
puts [format $formatStr "-----------"  "-------"  "--------------" "---------" "---------" "--------" "--------" "-------" "-------"]
puts "\n"



 
