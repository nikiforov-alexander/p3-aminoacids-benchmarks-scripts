
# parse_args
if {$argc != 5} {
    puts "Please run program as:"
    puts "./script method_name aa_name conf_name aligned_xyz_name ref_xyz_name"
}

# set global vars from args
set method_name [lindex $argv 0]
set aa_name     [lindex $argv 1]
set conf_name   [lindex $argv 2]
set aligned_xyz_name  [lindex $argv 3]
set ref_xyz_name  [lindex $argv 4]

set fp_log [ open "log-of-vmd-commands-$method_name-$aa_name-$conf_name.log" "w" ]
set fp_w $fp_log
set rmsd 0
set rmsd_selection "all and not name H"
#                         #  printing stuff #                         #  
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
#                         #  show functions #                         #  
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
        graphics 0 color 0
        graphics 0 text [vecadd [measure center $sel_all_ref] {1 1 1}] "$aa_name $method_name $conf_name $rmsd"  size 0.7
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
        puts $fp_render_tcl "puts \"Please enter the comment about the system\""
        puts $fp_render_tcl "gets stdin comment"
        puts $fp_render_tcl "set fp \[open \"comment\" w\]" 
        puts $fp_render_tcl "puts \$fp \"$conf_name \$comment\""
        puts $fp_render_tcl "close \$fp"
        close $fp_render_tcl
        print::putsnow "[dict get [info frame 0] proc] ends" 
    }
}
#                         # aligning namespace #                         #  
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
#                         #  body #                         #  
align::main 1
show::set_display_settings
show::put_aa_name_on_screen
show::local_render
close $fp_log
#                         #  end #                         #  
