#!/bin/bash 
shopt -s expand_aliases

default_number_of_indentation_spaces="4"
set_indentation_for_print_function () {
    #                            number_of_spaces_of_current_function is set to (max number of inner function - 2) * default_number_of_indentation_spaces 
    #                            -2 is because we dont consider main function in FUNCNAME array - which is if your run bash decoration from any script,
    #                            and decoration_function "_" itself.
    number_of_spaces_of_current_function=`echo ${#FUNCNAME[@]} | awk \
        -v default_number_of_indentation_spaces="$default_number_of_indentation_spaces" '
        { print ($1-3)*default_number_of_indentation_spaces}
        '`
    #                            actual indent is sum of default_number_of_indentation_spaces + number_of_spaces_of_current_function
    let INDENT=$number_of_spaces_of_current_function+$default_number_of_indentation_spaces
} 

cf () {
    error_cf="ERROR cat_file $@ at line ${BASH_LINENO[0]}:"
	local file
    set_indentation_for_print_function 
    string_equal_to_number_of_spaces_to_indent_em=`awk -v l="${INDENT:=0}" 'BEGIN {for(i=1;i<=l;i++) printf(" ")}'`
    case $# in	
        0) em no args provided && return 1 ;;
        *)
            if [ -z $2 ] ; then
                if [ -f $1 ] ; then
                    em "$1:"
                    [ ! -s $1 ] && em $error_cf file is zero-size && return 1
                    cat -n $1 | sed "s/^/$string_equal_to_number_of_spaces_to_indent_em/"
                else
                    em $error_cf file $1 doesnt exist && return 1
                fi
            elif [ $2 == "s" ] ; then
                if [ -f $1 ] ; then
                    em "$1:"
                    [ ! -s $1 ] && em $error_cf file is zero-size && return 1
                    cat -n $1 | sed "s/^/$string_equal_to_number_of_spaces_to_indent_em/"
                else
                    em $error_cf file $1 doesnt exist && return 1
                fi
            else
                for file in $@ ; do
                    if [ -f $file ] ; then
                        em "$file:"
                        [ ! -s $file ] && em $error_cf file is zero-size && return 1
                        cat -n $file | sed "s/^/$string_equal_to_number_of_spaces_to_indent_em/"
                    else
                        em $error_cf $file doesnt exist
                    fi
                done
            fi
        ;;
    esac
    return 0
}

em () { #desription: echo with colors like one below
    debug=${debug:=0}
    #                            print first INDENT spaces in front of echo
    #set_indentation_for_print_function
    echo
    awk -v l="${INDENT:=0}" 'BEGIN {for(i=1;i<=l;i++) printf(" ")}'
    #                            set string_equal_to_number_of_spaces_to_indent_em
    string_equal_to_number_of_spaces_to_indent_em=`echo $INDENT | awk '{for(i=1;i<=$1;i++) printf(" ")}'` 
    #                            cycle of color printing with fold at 80 and trimming with string_equal_to_number_of_spaces_to_indent_em
    local i=1
    for arg in $@ ; do
         if [ ${#arg} -gt 80 ] || [ $i -gt 2 ] ; then
             tput setaf 0 && tput bold
         else 
             tput setaf $i && tput bold
         fi
         echo -n -e "$arg " 
         let i=$i+1
    done
    #                            last echo with in grey color 
    tput setaf 0 && tput bold && echo && tput sgr0
    return 0
}
em_with_indent_but_no_color () { #desription: echo with colors like one below
    debug=${debug:=0}
    #                            print first INDENT spaces in front of echo
    awk -v l="${INDENT:=0}" 'BEGIN {for(i=1;i<=l;i++) printf(" ")}'
    #                            set string_equal_to_number_of_spaces_to_indent_em
    string_equal_to_number_of_spaces_to_indent_em=`echo $INDENT | awk '{for(i=1;i<=$1;i++) printf(" ")}'` 
    #                            cycle of color printing with fold at 80 and trimming with string_equal_to_number_of_spaces_to_indent_em
    local i=1
    echo $@ > temp
    awk \
        -v terminal_width=`tput cols` \
        -v string_equal_to_number_of_spaces_to_indent_em="$string_equal_to_number_of_spaces_to_indent_em" \
        ' 
        BEGIN { FS="" } 
        {
            total_length = length(string_equal_to_number_of_spaces_to_indent_em)
             for(i=1;i<=NF;i++) {
                 if (total_length % terminal_width == 0) {
                     printf("\n%s",string_equal_to_number_of_spaces_to_indent_em)
                     total_length += length(string_equal_to_number_of_spaces_to_indent_em)
                 }
                 printf("%s",$i)
                 total_length += 1
             }
        }
        ' temp 
    rm temp 
    #sed "s/^/$string_equal_to_number_of_spaces_to_indent_em/"
#    for arg in $@ ; do
#         if [ ${#arg} -gt 80 ] ; then
#             tput setaf 0 && tput bold
#         else 
#             tput setaf $i && tput bold
#         fi
#         echo -n -e "$arg " | sed "s/^/$string_equal_to_number_of_spaces_to_indent_em/"
##        echo -n -e "$arg " 
#         let i=$i+1
#    done
    #                            last echo with in grey color 
    tput setaf 0 && tput bold && echo && tput sgr0
    echo
    return 0
}
em_no_color () { #desription: echo with colors like one below
    #                            print first INDENT spaces in front of echo
    awk -v l="${INDENT:=0}" 'BEGIN {for(i=1;i<=l;i++) printf(" ")}'
    #                            set string_equal_to_number_of_spaces_to_indent_em
    string_equal_to_number_of_spaces_to_indent_em=`echo $INDENT | awk '{for(i=1;i<=$1;i++) printf(" ")}'` 
    #                            cycle of color printing with fold at 80 and trimming with string_equal_to_number_of_spaces_to_indent_em
    for arg in $@ ; do
         tput setaf 0 && tput bold
         echo -n -e "$arg " 
    done
    #                            last echo with in grey color 
    tput setaf 0 && tput bold && echo && tput sgr0 
    return 0
}
###########################  function special ###########################  
print () { #desription: echo with colors like one below
    set_indentation_for_print_function 
    awk -v l="${INDENT:=0}" 'BEGIN {for(i=1;i<=l;i++) printf(" ")}'
    echo $@
}
_ () { # function that echoes the function name starts or ends

    #declare | vim -
    error_of_echo_function="ERROR in _ echo_function:"
    #
    #                            set indent_of_echo_function using default value of 4 spaces
    #
    default_number_of_indentation_spaces="4"
        #declare | grep 'FUNCNAME=' | grep -v declare # DEBUG 
    indent_of_echo_function=`echo ${#FUNCNAME[@]} | awk \
        -v default_number_of_indentation_spaces="$default_number_of_indentation_spaces" '
        { print ($1-2)*default_number_of_indentation_spaces}
        '`
    let INDENT=$indent_of_echo_function+$default_number_of_indentation_spaces
    [ $indent_of_echo_function -le 0 ] && echo $error_of_echo_function wrong_indent $indent_of_echo_function && return 1
    string_equal_to_number_of_spaces_to_indent=`echo $indent_of_echo_function | awk '
        { for(i=1;i<=$1;i++) printf(" ") } 
        '`
        #echo "number_of_spaces is ${#string_equal_to_number_of_spaces_to_indent}" # DEBUG
    #                            
    #                            set func_name_to_echo depending on verbosity and checking whether we are in function indeed and not in body 
    #                            
    [ -z ${FUNCNAME[1]} ] && echo $error_of_echo_function use in script only && return 1
    if [ -z $verbose_emf ] ; then
        func_name_to_echo=${FUNCNAME[1]}
    else
        if [ $verbose_emf == "1" ] ; then
            func_name_to_echo="${FUNCNAME[1]}"
            for ((number_of_function=2;number_of_function<${#FUNCNAME[@]}-1;number_of_function++)) ; do
                func_name_to_echo+=" :: ${FUNCNAME[$number_of_function]}"
            done
        else
            func_name_to_echo=${FUNCNAME[1]}
        fi
    fi
    #
    #                            set func_state and curr_func_name_to_echo 
    #
    if [ -z $func_state ] ; then 
        func_state="started"
        list_of_all_function_used_in_script+=", $func_name_to_echo"
            # echo "list is $list_of_all_function_used_in_script" #DEBUG
    else
        if [ `echo $list_of_all_function_used_in_script | grep -c "\<$func_name_to_echo\>"` -ge 1 ] ; then
                #echo "list is $list_of_all_function_used_in_script" #DEBUG
            func_state="ended"
        else
            func_state="started"
            list_of_all_function_used_in_script+=", $func_name_to_echo"
                #echo "list is $list_of_all_function_used_in_script w func_name_to_echo $func_name_to_echo" #DEBUG
                #echo "list started is $list_of_all_function_used_in_script" #DEBUG
        fi
    fi
    #
    #                            finally echo funcname start 
    #
    case $func_name_to_echo in 
        main) echo $error_of_echo_function cannot use _ echo_function in body script && return 1 ;;
        *)
            case $func_state in
                started) 
                    tput setaf 9 && tput bold
                    echo "${string_equal_to_number_of_spaces_to_indent}$func_name_to_echo : $@" 
                    tput sgr0
                ;;
                ended)   
                    #tput setaf 0 && tput bold
                    #if [ -z $verbose_emf ] ; then 
                    #    echo "${string_equal_to_number_of_spaces_to_indent}} "   
                    #else 
                    #    if [ $verbose_emf -ge 1 ] ; then
                    #        echo "${string_equal_to_number_of_spaces_to_indent}$func_name_to_echo } "   
                    #    else
                    #        echo "${string_equal_to_number_of_spaces_to_indent}} "   
                    #    fi
                    #fi
                    #tput sgr0
                    if [ ${#FUNCNAME[@]} -eq 3 ] ; then
                        #echo unsetting list
                        unset list_of_all_function_used_in_script
                        unset func_state
                    fi
                ;;
                *) echo $error_of_echo_function func_state is $func_state && return 1 ;;
            esac
        ;;
    esac 

} 
#                         #  #                         #  
ray () {
    ask_dywtp_question () {
        em Do you want to proceed "?"
        read -n 1 -s a
        if  [ -z $a ] ; then
            return 1
        elif [ ${a[0]:0:1} != "y" ] ; then
            return 1
        else
            return 0
        fi
    }

    if [ -z $silent ] ; then
        ask_dywtp_question || return 1
    else
        if [ $silent == "no" ] ; then
            ask_dywtp_question || return 1
        else
            return 0
        fi
    fi
}
########################### create dir if it doesnt exist and remove contents if it exists ###########################  
crdir () {
    echo $FUNCNAME starts 
    case $# in
        1)
            if [ -d $1 ] ; then
                if [ `ls $1 | awk 'END {print NR}'` -ne 0 ] ; then
                    rm -r $1/* 
                    return $?
                else
                    em $1 is empty 
                fi
            else
                mkdir $1
                return $?
            fi 
            return 0
        ;;
        *) em too many args && return 1 ;;
    esac
    echo $FUNCNAME ends 
}
crdir_if_not_exist () {
    _
    case $# in
        1)
            if [ -d $1 ] ; then
                if [ `ls $1 | awk 'END {print NR}'` -ne 0 ] ; then
                    em $1 exist && return 1
                else
                    em $1 exist but is empty && return 1
                fi
            else
                mkdir -v $1
                [ $? -ne 0 ] && return 1
            fi 
            return 0
        ;;
        *) em too many args && return 1 ;;
    esac
    _
}
crdir_if_exist_overwrite () {
    _
    case $# in
        1)
            if [ -d $1 ] ; then
                em removing dir $1
                rm -v -r $1
            fi
            em creating new $1
            mkdir -v $1
            [ $? -ne 0 ] && return 1
            return 0
        ;;
        *) em too many args && return 1 ;;
    esac
    _
}
###########################  source and vim ###########################  
ss_and_vim () {
    case $# in
        0)
            em now type ss and then vv to vim this file $filename_tail
            echo "alias vv=\"vim $filename\"" > ~/tmp/.tempaliases 
        ;;
        *)
            if [ -f $1 ] ; then
                vim $1
                em now type ss and then vv to vim $1 file 
                echo "alias vv=\"vim $1\"" > ~/tmp/.tempaliases 
            else
                em $1 doesnt exist
            fi
        ;;
    esac
}
#                         #  remove #                         #  
function remove_ee {
    for file in $@ ; do 
        if  [ -f $file ] ; then
            rm $file
        fi
    done
}
###########################  colors ###########################  
gray  () { tput setaf 0 && tput bold ; }
red   () { tput setaf 1 && tput bold ; }
green () { tput setaf 2 && tput bold ; }
blue  () { tput setaf 3 && tput bold ; }
resetcolor () { tput sgr0 ; }
#                         #  check if args as a file exist #                         #  
check_if_it_exists () {
    echo $FUNCNAME starts
    ls $@
    if [ $? -eq 0 ] ; then
        [ `ls $@ | awk 'END {print NR}'` -ne 1 ] && em many $@ files && return 1
    else
        em $@ file doesnt exit && return 1
    fi
    echo $FUNCNAME ends && return 0
} 
alias check_if_file_exist="check_if_it_exists"
alias check_if_file_exists="check_if_it_exists"
#                         #  remove_if_exists #                         #  
remove_if_exists () {
    echo $FUNCNAME starts
    for file in $@ ; do
        if [ -f $file ] ; then
            em removing file $file
            rm $file
        else
            em file $file doesnt exist
        fi
    done
    echo $FUNCNAME ends
} 

#                            find_the_last_variable_name 
set_var () {
    error_set_var="ERROR set_var $@ at line ${BASH_LINENO[0]}:"
    
    parse_additional_argument () {
        case $3 in
            *create_empty_file*) 
                > $2
                eval "$1=$2"
            ;;
            *check_if_file_exist*) 
                [ ! -f $2 ] && em $error_set_var file $1 doesnt exist && return 1 
                gray && em_no_color "file" $1 exist && tput sgr0
                eval "$1=$2"
            ;;
            *check_if_dir_exist*)  
                [ ! -d $2 ] && em $error_set_var dir $1 doesnt exist && return 1 
                gray && em_no_color "dir" $2 exist && tput sgr0
                eval "$1=$2"
            ;;
            *check_if_it_exist*)  
                [ ! -e $2 ] && em $error_set_var $1 doesnt exist && return 1 
                gray && em_no_color "dir" $2 exist && tput sgr0
                eval "$1=$2"
            ;;
            *tail|*set_tail)
                eval "${1}_tail=`echo $2 | awk -F"/" '{print $NF}'`"
                gray && em_no_color "${1}_tail is `echo $2 | awk -F"/" '{print $NF}'`" && tput sgr0
                eval "$1=$2"
            ;;
            *create_new_dir_if_it_doesnt_exist|*crdir_*)
                eval "$1=$2"
                em $1 is set to $2
                crdir_if_not_exist $2 || return 1
            ;;
            *create_new_dir_overwrite_if_exist|*overwrite_*)
                eval "$1=$2"
                crdir_if_exist_overwrite $2 || return 1
            ;;
            *) em $error_set_var wrong 3-rd argument \"$3\" && return 1 ;;
        esac
        [ -z $var_counter ] && em $1 is $2
        [ ! -z $var_counter ] && [ $var_counter -eq 3 ] && em $1 is $2
        return 0
    } 
    case $# in
        0)  em $error_set_var need 2 or 3 arguments to set && return 1 ;;
        1)  em $error_set_var $1 value is empty && return 1 ;;
        2) 
            em $1 is $2
            eval "$1=$2"
        ;;
        3) parse_additional_argument $@ || return 1 ;;
        *) 
            var_counter=1 
            for argument in $@ ; do
                if [ $var_counter -ge 3 ] ; then 
                    parse_additional_argument $1 $2 $argument || return 1
                fi
                let var_counter=$var_counter+1
            done
            unset var_counter
            #[ $# -gt 3 ] && em $error_set_var more than 3 arguments $@ cannot set && return 1 
        ;;
    esac
    unset error_set_var
    return 0
} 
alias var="set_var"
#                            echo var just by name                              
echo_var () {
    error_echo_var="echo_var error:"
    case $# in
        0) em $error_echo_var has to be at least one argument && return 1 ;;
        1) eval "em var $1 is \$$1" ;;
        *) em $error_echo_var too many args: $@ && return 1 ;;
    esac
} 
#                           rewrite cd 
cd () {
    error_cd="ERROR cd $@:"
    case $# in
        0) em $error_cd zero args && return 1 ;;
        1)
            if [ ! -d $1 ] ; then 
                em $error_cd: $1 doesnt work
                return 1
            else
                em entering dir $1
                builtin cd $1
                return 0
            fi
        ;;
        *) em $error_cd too many args && return 1 ;;
    esac
} 
#                            exit with em exit 
exit_debug () {
    em exiting with status $1
    em LINENO $LINENO, FUNCNAME array is ${FUNCNAME[@]} 
    builtin exit $1
} 
exit () {
    if [ ! -z $1 ] && [ $1 -ne 0 ] ; then
        em exiting with status $1
        line_number_at_which_error_occured=`declare | grep 'BASH_LINENO=' | grep -v grep | awk '{print $1}' | awk -F"\"" '{print $2}'`
        if [ ! -z $line_number_at_which_error_occured ] ; then 
            em line_number_at_which_error_occured is $line_number_at_which_error_occured:
            [ ! -z ${BASH_SOURCE[1]} ] && sed -n "$line_number_at_which_error_occured p" ${BASH_SOURCE[1]}
            echo
        fi
        case ${#FUNCNAME[@]} in
            2) em error in body of script ;;
            3) echo ${FUNCNAME[2]} ;;
            *)
                echo -n ${FUNCNAME[2]}
                for ((i=3;i<${#FUNCNAME[@]};i++)) ; do
                    echo -n "::${FUNCNAME[$i]}"
                done
                echo
            ;;
        esac
    fi
    builtin exit $1
} 
#                            check_if_we_are_in_right_dir
check_if_we_are_in_right_dir () { _
    if [ $pwd_tail == $1 ] ; then
        em we are in right dir    
    else
        em we are in wrong dir: $1 && return 1
    fi
} 
#                            
#                         #  variables #                         #  
#                            
export s="$HOME/my-scripts"
export aliases_scripts="$s/bash_aliases.sh"
export err="$s/.err-file"
export TRASH_DIR_MAIN="$HOME/.trash"
export TRASH_INFO="$HOME/.trash/list-of-files"
