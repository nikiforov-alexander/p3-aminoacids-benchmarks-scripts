
# parse_args
if {$argc != 6} {
    puts "Please run program as:"
    puts "vmd \\"
    puts "  -e script \\"
    puts "  -m ref_xyz_name aligned_xyz_name \\"
    puts "  -args method_name \\" 
    puts "        aa_name \\" 
    puts "        conf_name \\" 
    puts "        aligned_xyz_name \\"
    puts "        ref_xyz_name \\"
    puts "        selection_indices_file \\"
    exit
}

# set global vars from args
set method_name [lindex $argv 0]
set aa_name     [lindex $argv 1]
set conf_name   [lindex $argv 2]
set aligned_xyz_name  [lindex $argv 3]
set ref_xyz_name  [lindex $argv 4]
set selection_indices_file  [lindex $argv 5]
set selection_indices_file_pointer [ open $selection_indices_file "r" ]

set fp_log [ open "log-of-vmd-commands-$method_name-$aa_name-$conf_name.log" "w" ]
set fp_w $fp_log
set rmsd 0
set rmsd_selection "all and not name H"
#                          functions

namespace eval print {

	proc writecoords {mol_id aligned_xyz_name} {
		print::putsnow "[dict get [info frame 0] proc] starts" 
        set sel_all [ atomselect $mol_id "all" ]
        set old_filename [molinfo $mol_id get filename]
        set new_filename $aligned_xyz_name
        $sel_all writexyz $new_filename
		print::putsnow "[dict get [info frame 0] proc] ends" 
	}

	proc printmatrix {matrix fp_w} {
	########################### print matrix beatifully ########################### 
		set outw "%5.4f\t%5.4f\t%5.4f\t%5.4f\n"
		for {set i 0} {$i<=3} {incr i} { 
			set vec($i) [lindex $matrix $i] 
			puts $fp_w [format $outw [lindex $vec($i) 0] [lindex $vec($i) 1] [lindex $vec($i) 2] [lindex $vec($i) 3]]
        }
	}

	proc print_indices {} {
		global verbose
		global j
		global nr
		print::putsnow "[dict get [info frame 0] proc] starts" 
		for {set i 1} {$i <= $nr} {incr i} {
			set sel_atom [atomselect $j "serial $i" frame 0 ]
			set name [ $sel_atom get index ]	
			if {$verbose} {puts $name}
		}
		print::putsnow "[dict get [info frame 0] proc] ends" 
	}

	proc vecprint { vec comment } {
		global fp_w
		set i 0
		foreach el $vec {
			puts -nonewline $fp_w [format " %11.6f" [lindex $vec $i]]
			incr i
		}
		puts $fp_w " $comment"
	}

	proc putsnow {args} {
		global fp_w
		set nargs [llength $args]
		puts -nonewline $fp_w "#"
		foreach arg $args {	
			puts -nonewline $fp_w " $arg "
		}
		puts            $fp_w "###########################"
	}

}

namespace eval show {
    proc set_display_settings {} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        color Display Background white
        color Name H 2
        axes location off
        display depthcue off
        display projection orthographic
        display antialias off
        display height 4
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc put_aa_name_on_screen {} {
        print::putsnow "[dict get [info frame 0] proc] starts"
        global aa_name
        global method_name
        global rmsd
        global conf_name
        set sel_all_ref [atomselect 0 all]
        # black
        graphics 0 color 16 
        graphics 0 text [vecadd [measure center $sel_all_ref] {2 1 1}] "$aa_name $method_name $conf_name $rmsd"  size 0.7
        print::putsnow "[dict get [info frame 0] proc] ends"
    } 
    proc local_render {} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        global method_name
        global aa_name
        global conf_name
        set fp_render_tcl [open "render.tcl" "w"]
        set pov "picture-of-aligned-structures-after-opt-and-ref-one-$conf_name-$aa_name-$method_name.pov"
        set tga $pov.tga
        puts $fp_render_tcl "set pov \"$pov\""
        puts $fp_render_tcl "set tga \$pov.tga"
        puts $fp_render_tcl "render POV3 \$pov \"povray +W%w +H%h -I\$pov -O$tga +D +X +A +FT\""
        #                          deprecated part where we wrote
        #                          comment each time we screenshot
        #puts $fp_render_tcl "puts \"Please enter the comment about the system\""
        #puts $fp_render_tcl "gets stdin comment"
        #
        #puts $fp_render_tcl "set fp \[open \"comment\" w\]" 
        #puts $fp_render_tcl "puts \$fp \"$conf_name \$comment\""
        #puts $fp_render_tcl "close \$fp"
        close $fp_render_tcl
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc print_heavy_atom_names_near_atoms {} {
        print::putsnow "[dict get [info frame 0] proc] starts"
        set sel_all [atomselect 0 all]
        for {set serial 1} {$serial <= [ $sel_all num ] } {incr serial} {
            set sel_atom [ atomselect 0 "serial $serial" ]
            lassign [ $sel_atom get { x y z } ] xyz_atom
            set atom_name [ $sel_atom get name ] 
            if { $atom_name != "H" } {
                graphics 0 text [vecadd $xyz_atom {0.1 0.1 0.1}] "$atom_name" size 1
            }
        }
        print::putsnow "[dict get [info frame 0] proc] ends"
    } 
}

namespace eval align {
    proc move_structure_to_reference_one {mol_id} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        global rmsd_selection
        set ref_atoms_sel  [ atomselect 0 "$rmsd_selection" ]
        set toalign_sel    [ atomselect $mol_id "$rmsd_selection" ]

        set all_toalign_sel    [ atomselect $mol_id "all" ]

        set transmatrix [measure fit $toalign_sel $ref_atoms_sel ] 

        $all_toalign_sel move $transmatrix 
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc calculate_rmsd_between_structures {mol_id} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        global rmsd_selection
        global fp_log
        global rmsd
        global aa_name
        global method_name
        global conf_name
        set ref_atoms_sel  [ atomselect 0 "$rmsd_selection" ]
        set toalign_sel    [ atomselect $mol_id "$rmsd_selection" ]
        set rmsd [format "%4.3f" [measure rmsd $toalign_sel $ref_atoms_sel] ]
        puts $fp_log [format "rmsd of %25s %15s using %10s is %4.3f" $conf_name $aa_name $method_name $rmsd ]

        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc main {mol_id} {
        global aligned_xyz_name
        print::putsnow "[dict get [info frame 0] proc] starts" 
        move_structure_to_reference_one $mol_id
        calculate_rmsd_between_structures $mol_id
        print::writecoords $mol_id $aligned_xyz_name
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
}

namespace eval representation {
    proc set_new {mol_id color_id} {
        # makes molecule single colored
        print::putsnow "[dict get [info frame 0] proc] starts" 
        mol delrep 0 $mol_id
        #mol representation Lines 2.0
        #                      ball_radius lines_width lines_res balls_res
        #mol representation CPK 0.10000 0.05 100.000000 100.000000
        mol color ColorID $color_id
        mol selection all 
        mol material Opaque
        mol addrep $mol_id
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc delete {mol_id} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        mol delrep 0 $mol_id
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
    proc add_rep_as_color_for_atoms {mol_id color_id selection} {
        print::putsnow "[dict get [info frame 0] proc] starts" 
        mol representation CPK 0.10000 0.05 100.000000 100.000000
        mol color ColorID $color_id
        mol selection $selection 
        mol addrep $mol_id
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }

    proc add_rmsd_text_for_group_of_atoms {sel_of_atoms_of_group color_id} {
        # select ref group of atoms and aligned to 
        # calculate rmsd
        set ref_group_atoms_selection [atomselect 0 "$sel_of_atoms_of_group"]
        set aligned_group_atoms_sel [atomselect 1 "$sel_of_atoms_of_group"]

        # measure and format rmsd
        set rmsd [format "%4.3f" [measure rmsd $ref_group_atoms_selection $aligned_group_atoms_sel]]

        # change color of text
        graphics 0 color $color_id
        
        # print rmsd at point "center_of_molecule" + vector_to_add 
        # with scaled_y_coord_of_rmsd_text
        set scaled_y_coord_of_rmsd_text [expr {$color_id*0.5}]
        set vector_to_add "1 $scaled_y_coord_of_rmsd_text 1"
        graphics 0 text [vecadd [measure center [atomselect 0 all]] $vector_to_add] "$rmsd"  size 0.7

    }

    proc split_selection_file_and_apply_rep_for_atom_groups {file_pointer} {
        print::putsnow "[dict get [info frame 0] proc] starts"
        set color_id 0
        foreach line [split [read $file_pointer] "\n"] {
            if {[llength $line] != 0 } {
                set selection_of_group_of_atoms "[lrange $line 1 end]"

                add_rep_as_color_for_atoms 1 $color_id $selection_of_group_of_atoms

                add_rmsd_text_for_group_of_atoms $selection_of_group_of_atoms $color_id

                incr color_id
            } 
        }
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
}
#                         #  body #                         #  
align::main 1

show::set_display_settings
show::put_aa_name_on_screen
show::local_render

representation::set_new 0 3
representation::delete  1
representation::set_new 1 0
representation::split_selection_file_and_apply_rep_for_atom_groups $selection_indices_file_pointer

show::print_heavy_atom_names_near_atoms
close $fp_log
#                         #  end #                         #  
