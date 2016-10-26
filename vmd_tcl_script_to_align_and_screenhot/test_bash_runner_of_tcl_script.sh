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

print_script_banner () { _
    echo
    echo Run as: ./script 
    echo    method_name 
    echo    aa_name 
    echo    conf_name 
    echo    aligned_xyz_file 
    echo    ref_xyz_file
    echo    selection_indices_file
    echo    tcl_vmd_script_rendering_screenshot_of_aligned_mols
    echo
} 

parse_args () { _ $@
    case $# in
        0)
            em TEST
            var method_name "om2"
            var aa_name "Ala"
            var conf_name "xab"
            var aligned_xyz_file "o-aligned-om2-xab-Ala.xyz" \
                -check_if_file_exists || exit 1 
            var ref_xyz_file "r-om2-xab-Ala.xyz" \
                -check_if_file_exists || exit 1 
            var selection_indices_file \
                "Ala.selection" \
                -check_if_file_exists || exit 1 
            var tcl_vmd_script_rendering_screenshot_of_aligned_mols \
                "$PWD/tcl_vmd_script_rendering_screenshot_of_aligned_mols.tcl" \
                -check_if_file_exists || exit 1 
        ;;
        7)
            var method_name $1
            var aa_name $2
            var conf_name $3
            var aligned_xyz_file $4 \
                -check_if_file_exists || exit 1 
            var ref_xyz_file $5 \
                -check_if_file_exists || exit 1 
            var selection_indices_file $6 \
                -check_if_file_exists || exit 1 
            var tcl_vmd_script_rendering_screenshot_of_aligned_mols \
                "$7" \
                -check_if_file_exists || exit 1 
        ;;
        *)
            print_script_banner && exit 1
        ;;
    esac
} 

set_init_vars () { _
    var pwd $PWD
    var vmd "/usr/local/bin/vmd" \
        -check_if_file_exists || exit 1 
    var dir_w_vmd_processing \
        "$method_name-$aa_name-$conf_name-vmd_processing_dir" \
        -crdir_if_not_exists || exit 1 
} 

run_vmd () { _ $@
    $vmd \
        -e $tcl_vmd_script_rendering_screenshot_of_aligned_mols \
        -m $ref_xyz_file $aligned_xyz_file \
        -args $@ 
} 

convert_image_to_png_and_pdf () { _
    # we convert first to eps, then
    # to pdf because size is smaller

    set_init_vars () { _
        # image from VMD
        var tga_image \
            `find ./ -name "*tga"` \
            -check_if_file_exists || exit 1 

        # formats to which we will convert
        var png_image \
            ${tga_image//tga/png}
        var pdf_image \
            ${tga_image//tga/pdf}
        var eps_image \
            ${tga_image//tga/eps}

        # convert progs
        var convert_prog \
            `which convert` \
            -check_if_file_exists || exit 1 
        var epstopdf \
            `which epstopdf` \
            -check_if_file_exists || exit 1 
    } 

    run_convert () { _ $@
        $1 $2 $3
    } 

    run_epstopdf () { _ $@
        $1 $2 --outfile="$3"
    } 

    #                            body                           #   

    set_init_vars

    run_convert $convert_prog \
        $tga_image $png_image

    run_convert $convert_prog \
        $tga_image $eps_image

    run_epstopdf $epstopdf \
        $eps_image $pdf_image

    #                            end                            #   
} 
#                            body                           #   

parse_args $@

set_init_vars

cp -v \
    $aligned_xyz_file \
    $ref_xyz_file \
    $selection_indices_file \
    $dir_w_vmd_processing

cd $dir_w_vmd_processing || exit 1

run_vmd \
    $method_name \
    $aa_name \
    $conf_name \
    $aligned_xyz_file \
    $ref_xyz_file \
    $selection_indices_file

convert_image_to_png_and_pdf
#                            end                            #   
