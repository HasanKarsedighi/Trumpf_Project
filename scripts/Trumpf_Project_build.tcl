
# ============================================================
# 1. PROJECT SETTINGS
# ============================================================

# Define the project name
set project_name "Trumpf_Project"

# Define the target FPGA chip
set part_name "xc7z020clg400-1"

# Get the directory containing this Tcl script
set script_dir [file dirname [file normalize [info script]]]

# Get the root directory of the project
set root_dir [file normalize "$script_dir/.."]

# Define the output directory for Vivado
set project_dir "$root_dir/vivado/$project_name"


# ============================================================
# 2. CREATE VIVADO PROJECT
# ============================================================

# Prevent overwriting an existing project
if {[file exists "$project_dir/$project_name.xpr"]} {
    error "Project already exists: $project_dir"
}

# Create a new Vivado project
create_project $project_name $project_dir -part $part_name

# Select the PYNQ-Z2 development board
set_property board_part "tul.com.tw:pynq-z2:part0:1.0" [current_project]

# Set VHDL as the target language
set_property target_language VHDL [current_project]

# Enable VHDL-2008 support
set_property enable_vhdl_2008 1 [current_project]


# ============================================================
# 3. ADD VHDL SOURCE FILES
# ============================================================

# Find all VHDL files in the RTL source directory
set rtl_files [glob -nocomplain "$root_dir/rtl/src/*.vhd"]

# Stop if no VHDL source files are found
if {[llength $rtl_files] == 0} {
    error "No RTL VHDL files found!"
}

# Add VHDL files to the design sources
add_files -fileset sources_1 $rtl_files


# ============================================================
# 4. ADD SIMULATION FILES
# ============================================================

# Find all VHDL testbench files
set sim_files [glob -nocomplain "$root_dir/sim/*.vhd"]

# Add simulation files if available
if {[llength $sim_files] > 0} {

    # Add testbench files to the simulation fileset
    add_files -fileset sim_1 $sim_files

    # Set the simulation top module
    set_property top Tb [get_filesets sim_1]
}


# ============================================================
# 5. ADD IP CORES
# ============================================================

# Find XCI files inside IP_Cores subdirectories
set ip_files [glob -nocomplain \
    "$root_dir/IP_Cores/*/*.xci"]

# Stop if no IP Core files are found
if {[llength $ip_files] == 0} {
    error "No XCI files found!"
}

# Add IP Core configuration files to the project
add_files -fileset sources_1 $ip_files

# Get all IP objects in the project
set ip_list [get_ips]


# ============================================================
# 6. CHECK AND UPGRADE IP CORES
# ============================================================

# Refresh the IP catalog
update_ip_catalog

# Display the current status of all IP Cores
report_ip_status

# Check each IP separately
foreach ip $ip_list {

    # Get the IP name
    set ip_name [get_property NAME $ip]

    # Check whether the IP is locked
    set locked [get_property IS_LOCKED $ip]

    # Check whether an upgrade version is available
    set versions [get_property UPGRADE_VERSIONS $ip]

    # Upgrade only if the IP is locked and upgrade is available
    if {$locked && $versions ne ""} {

        puts "Upgrading IP: $ip_name"
        upgrade_ip $ip

    } elseif {$locked} {

        # Stop if a locked IP cannot be upgraded
        error "IP $ip_name is locked and cannot be upgraded!"

    } else {

        puts "IP $ip_name is ready."
    }
}

# Check the IP status after upgrading
report_ip_status


# ============================================================
# 7. GENERATE IP OUTPUT PRODUCTS
# ============================================================

# Enable Out-of-Context synthesis checkpoints for each IP
foreach ip_file $ip_files {
    set_property generate_synth_checkpoint true [get_files $ip_file]
}

# Generate synthesis and simulation output products
generate_target all [get_ips]


# ============================================================
# 8. GENERATE IP DESIGN CHECKPOINTS (DCP)
# ============================================================

# Create Out-of-Context synthesis runs for all IP Cores
create_ip_run [get_ips]

# Run synthesis for each IP separately
foreach ip [get_ips] {

    # Get the IP name
    set ip_name [get_property NAME $ip]

    # Determine the synthesis run name
    set run_name "${ip_name}_synth_1"

    # Check whether the OOC run exists
    set ip_run [get_runs -quiet $run_name]

    if {[llength $ip_run] == 0} {
        error "IP synthesis run not found: $run_name"
    }

    # Start IP synthesis
    launch_runs $ip_run

    # Wait until synthesis finishes
    wait_on_run $ip_run

    # Check synthesis completion
    set run_status [get_property STATUS $ip_run]

    if {![string match "*Complete*" $run_status]} {
        error "IP synthesis failed: $run_name ($run_status)"
    }

    puts "IP synthesis completed: $ip_name"
}


# ============================================================
# 9. SET TOP MODULE AND COMPILE ORDER
# ============================================================

# Set the top-level RTL module
set_property top TopModule [get_filesets sources_1]

# Update the RTL compilation order
update_compile_order -fileset sources_1

# Update the simulation compilation order
update_compile_order -fileset sim_1


# ============================================================
# 10. SAVE PROJECT
# ============================================================

# Save the Vivado project
save_project

# Display the final IP status
report_ip_status

# Print a success message
puts "======================================"
puts "Project created successfully!"
puts "IP output products generated!"
puts "IP synthesis runs completed!"
puts "======================================"
