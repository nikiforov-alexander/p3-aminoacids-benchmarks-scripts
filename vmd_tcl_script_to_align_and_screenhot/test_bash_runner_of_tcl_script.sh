#!/bin/bash 

# INCLUDE_BASH_SCRIPTS_PATH is variable that has to be set up
# as absolute path to where all bash scripts to be included
# will lie

if [ -z $INCLUDE_BASH_SCRIPTS_PATH ] ; then
    echo
    echo Please export INCLUDE_BASH_SCRIPTS_PATH
    echo with path to helpful bash scripts
    echo
    exit 1
fi

helpful_bash_funcs_include_script="$INCLUDE_BASH_SCRIPTS_PATH/helpful_bash_funcs.sh"

if [ -f $helpful_bash_funcs_include_script ] ; then
    source $helpful_bash_funcs_include_script
else
    echo
    echo helpful_bash_funcs_include_script $helpful_bash_funcs_include_script
    echo does not exist
    echo
    exit 1
fi

#                          functions

set_init_vars () { _
    var pwd $PWD
    var vmd "/usr/local/bin/vmd" \
        -check_if_file_exists || exit 1 
} 

print_script_banner () { _
    echo
    echo Run as: ./script method_name aa_name conf_name aligned_xyz_name
    echo
} 

parse_args () { _ $@
    case $# in
        0)
            em TEST
            var method_name "om2"
            var aa_name "Ala"
            var conf_name "xab"
            var aligned_xyz_name "o-aligned-om2-xab-Ala.xyz" \
                -check_if_file_exists || exit 1 
        ;;
        4)
            var method_name $1
            var aa_name $2
            var conf_name $3
            var aligned_xyz_name $4 \
                -check_if_file_exists || exit 1 
        ;;
        *)
            print_script_banner && exit 1
        ;;
    esac
} 

#                            body                           #   

set_init_vars

parse_args $@

#                            end                            #   
