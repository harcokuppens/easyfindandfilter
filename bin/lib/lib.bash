
#================================================================================================================================
# require a least bash version 5.0 
#================================================================================================================================

check_bash_version_ok() {
       if [[ ${BASH_VERSINFO[0]} -ge 5 ]]
       then
         # we need associative array support which is only since bash version 4 supported
         return 0 
       else 
         echo ""
         echo "ERROR: require newer bash version for sourced file: ${BASH_SOURCE[0]}"
         echo "       We require a least bash version 5.0, current bash version is $BASH_VERSION"
         if [[ "$OSTYPE" == darwin* ]]; then 
         echo "       On macos you can upgrade your bash version using instructions https://www.shell-tips.com/mac/upgrade-bash/"
         fi
         return 1
       fi
}

check_bash_version_ok || return 1



#================================================================================================================================
# conventional search linux/mac
#================================================================================================================================


# utilities
# -----------

nl2null() {
    tr '\n' '\0'
}

null2nl() {
    tr '\0' '\n'
}



read_stdin_into_array() {
    # input_array is reference to array which name is passed as first argument to this function 
    local -n input_array=$1

    # Read lines from stdin and append them to the array
    while IFS= read -r line; do
        input_array+=("$line")
    done
}

has_help_option() {
    local -n myarray=$1 
    local result="false"
    for i in "${myarray[@]}"
    do
      if [[ "$i" == "-h" || "$i" == "-help" || "$i" == "--help"  ]]
      then
         result="true"        
         break
      fi
    done
    echo "$result"
}    



fetch_options() {

    # https://www.semicolonandsons.com/code_diary/bash/use-arrays-instead-of-strings-for-building-up-bash-argument-lists-to-pass-to-other-commands
    # https://www.lukeshu.com/blog/bash-arrays.html
    # https://medium.com/@linuxschooltech/create-and-use-associative-array-in-bash-script-5f4e32a00577
    # https://stackoverflow.com/questions/3112687/how-to-iterate-over-associative-arrays-in-bash
    # 
    #https://stackoverflow.com/questions/10582763/how-to-return-an-array-in-bash-without-using-globals

    #       we pass args (input) and timequery (result) arrays by reference to
    #       function which changes them. (removing used args in args array,
    #       and putting query params for find command in timequery array.
    #         local args=("$@")
    #         local options=()
    #         fetch_options args options     
    #       we use options ass.array in _base_find to construct the find command   
    #       which actually get run
    local -n arr=$1
    local -n ref_options=$2
    
    # https://stackoverflow.com/questions/16860877/remove-an-element-from-a-bash-array#51916199
    #   remove element at index
    # https://stackoverflow.com/questions/16860877/remove-an-element-from-a-bash-array#47798640
    #   reindex array (see comments)


    #options: [-i] [-n|--dry-run] [-x|--index] [--dir|-d DIR] [--dir-only] [--min NUMDAYS] [--max NUMDAYS] [--grepfilename WORD] 
    
    # default value
    ref_options+=( ["index"]="false" )
    ref_options+=( ["dry-run"]="false" )
    ref_options+=( ["dir-only"]="false" )
    ref_options+=( ["help"]="false" )
    ref_options+=( ["caseinsens"]="false" )

    i=0 # bash arrays are 0-indexed 
    size=${#arr[@]}
    while [ "$i" -lt "$size" ]; do
        arg="${arr[$i]}"

        # stop parsing options when finding '--' 
        if [[ "$arg" == "--" ]]
        then 
            unset "arr[$i]"
            break
        fi

        if [[ "$arg" == "--dir" || "$arg" == "--min" || "$arg" == "--max" || "$arg" == "--minsize" || "$arg" == "--maxsize" || "$arg" == "--grepfilename" || "$arg" == "--ext" || "$arg" == "--grepcontent" || "$arg" == "--index" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # value
            value="${arr[i]}"
            unset "arr[$i]"
            i=$((i+1));
            # store 
            arg=${arg#--}
            ref_options+=( [$arg]="$value" )
            continue
        fi 

        # one letter version; need to set name manually  
        if [[ "$arg" == "-d"  ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # value
            value="${arr[i]}"
            unset "arr[$i]"
            i=$((i+1));
            # store 
            ref_options+=( ["dir"]="$value" )
            continue
        fi 

        #  flag option (no value associated with option)
        if [[ "$arg" == "-x" || "$arg" == "--index" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # store 
            ref_options+=( ["index"]="true" )
            continue
        fi       
        if [[ "$arg" == "-n" || "$arg" == "--dry-run" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # store 
            ref_options+=( ["dry-run"]="true" )
            continue
        fi       
#        if [[ "$arg" == "-f" || "$arg" == "--no-index" ]]
#        then 
#            unset "arr[$i]"
#            i=$((i+1))
#            # store 
#            ref_options+=( ["index"]="false" )
#            continue
#        fi              
        if [[ "$arg" == "--dir-only" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # store 
            ref_options+=( ["dir-only"]="true" )
            continue
        fi  

        if [[ "$arg" == "-i" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # store 
            ref_options+=( ["caseinsens"]="true" )
            continue
        fi  

        if [[ "$arg" == "-h" || "$arg" == "--help" ]]
        then 
            unset "arr[$i]"
            i=$((i+1))
            # store 
            ref_options+=( ["help"]="true" )
            continue
        fi 

        # no matched option
        if [[ "$arg" == -* ]]
        then 
           echo "ERROR: unknown option '$arg'" 1>&2
           return 1
        fi

        # ignore none option
        i=$((i+1))
    done




    local sizequery=()
    if [[ -n "${ref_options[maxsize]}" ]] 
    then 
        local max_in_bytes
        local maxsize="${ref_options[maxsize]}"
        get_size_in_bytes "$maxsize" max_in_bytes ||  { printf "ERROR: '$maxsize' is not a valid size! \n" 1>&2 && return 1; }
        ref_options[maxsize]=${max_in_bytes}
    fi 
    if [[ -n "${ref_options[minsize]}" ]] 
    then 
        local min_in_bytes
        local minsize="${ref_options[minsize]}"
        get_size_in_bytes "$minsize" min_in_bytes ||  { printf "ERROR: '$minsize' is not a valid size! \n" 1>&2 && return 1; }
        ref_options[minsize]=${min_in_bytes}
    fi 
    
    # reindex arr after removing options from it; making positional arguments work by number again!
    arr=( "${arr[@]}" )
}    

# helper associative array printing
print_pair(){ echo "   $1 -> $2";}
print_array(){
  #arr="$(declare -p $1)" ; eval "declare -A f="${arr#*=};
  local -n f=$1
  for i in ${!f[@]}; do print_pair "$i" "${f[$i]}"; done
}

# all higher functions call this function with as only argument the options they
# overrule
#        [--min NUMDAYS] [--max NUMDAYS]
#        [--grepfilename] WORD [--ext EXT] [--grepcontent WORD] "
_find_base() {
    local -n findbaseoptions=$1
    
    # if dir not set then by default search from .
    if [[ -z "${findbaseoptions[dir]}" ]] 
    then 
        findbaseoptions[dir]="."   
    fi 

    # prefer indexed find if available
    if [[ "${findbaseoptions[index]}"  == "true"  ]]
    then
        if  _check_index_cmd
        then      
            _indexed_find_base findbaseoptions
            return 0
        else    
            echo "WARNING: indexed search not available, switching to 'find' search (slower)" >&2 
        fi    
    fi
    # default find with 'find' command
    _command_find_base findbaseoptions
}   


get_size_in_bytes() {
    local inputsize="$1"
    local -n answer=$2

    # only integers then size in bytes
    local re_is_num='^[0-9]+$'
    if [[ $inputsize =~ $re_is_num ]] ; then
        answer=$inputsize
        return 0
    fi  

    local unit=${inputsize: -1}
    local unit_in_bytes=0;
    unit="${unit,,}"
    number=${inputsize::-1}
    if ! [[ $number =~ $re_is_num ]] ; then
         #echo "error: invalid size 1" >&2; 
         return 1
    fi 

    case "$unit"  in
    "b" )
        unit_in_bytes=1
        ;; 
    k)
        unit_in_bytes=1024 
        ;;
    "m" )
        unit_in_bytes=1048576
        ;;
    "g" )
        unit_in_bytes=1073741824 
        ;;
    * )   
        #echo "error: invalid size 2" >&2; 
        return 1
        ;;
    esac
    answer=$((number * unit_in_bytes))
}

_command_find_base() {
    local -n findoptions=$1
    if [[ "${findoptions[index]}"  == "true"  ]]
    then
        if  _check_index_cmd
        then      
            _indexed_find_base findoptions
            return 0
        else    
            echo "ERROR: indexed search using command '$INDEXED_FIND_CMD' is not available, use none-indexed search using 'find' command instead (slower)" >&2 
            return 1
            #echo "WARNING: indexed search not available, switching to 'find' search (slower)" >&2 
        fi    
    fi

    local grepfilename="${findoptions[grepfilename]}"
    local grepcontent="${findoptions[grepcontent]}"
    local ext="${findoptions[ext]}"
    local max="${findoptions[max]}"
    local min="${findoptions[min]}"
    local maxsize="${findoptions[maxsize]}"
    local minsize="${findoptions[minsize]}"
    local dir="${findoptions[dir]}"
    local dryrun="${findoptions[dry-run]}"
    local dironly="${findoptions[dir-only]}"
    local caseinsens="${findoptions[caseinsens]}"

    if [[ -z "$dir" ]] 
    then 
        dir="."
    else 
        dir="$dir/"    
    fi 
    
    # time options:
    #   --min n :  file is n*24 hours old or older     
    #   --max n :  file is n*24 hours old or younger 
    # where   
    #    --min a --max b  specifies all days in timerange [ a*24h old , b*24h old ]  including the boundary days
    # so 
    #    --min 0  means all files of today and older
    #    --min 1  means all files of yesterday and older
    #    --max 0  means all files of today and newer
    #    --max 1  means all files of yesterday and newer

    #   find  -mtime 0 :  all files in last 24 hours : [ 0 , 24 ]    ~'today'
    #   find  -mtime +0 : all files older then '-mtime 0' : [ 24 , inf ]            
    #   find  -mtime -0 : all files newer then '-mtime 0' : [ future , 0 (now ]
    #       => with +n and -n then n itself is not included 
    #   find   : all files  older then now (assume no files with future date)
    #    -> --min 0 :  no mtime option
    #    -> --min 1 :  -mtime +0   (0 not included)
    #    -> --min 2 :  -mtime +1   (1 not included)
    #    -> --max 0 :  -mtime -1   (1 not included)
    #    -> --max 1 :  -mtime -2   (2 not included)
    #   we can have negative numbers: meaning days in future
    #    -> find  -mtime +-1  : more older (+) then  1 day in future(-1) (not including that day) :    older then now!
    #    -> find  -mtime +-2  : more older (+) then  2 day in future(-2) (not including that day) :    older then 1 day in future!
    #   so we can do for 
    #    --> --min 0 :  -mtime +-1
    #      
    #   so  
    #     --min a  :   
    #          n=a-1 
    #          options = ( -mtime +n )
    #     --max b  :   
    #          n=b+1 
    #          options = ( -mtime -n )
    #
    local timequery=()
    if [[ -n $max ]] 
    then 
        max=$((max+1))
        timequery+=( -mtime -${max} )
    fi 
    if [[ -n $min ]] 
    then 
        min=$((min-1))
        timequery+=( -mtime +${min} )
    fi 


    local sizequery=()
    if [[ -n $maxsize ]] 
    then 
        sizequery+=( -size -${maxsize}c )
    fi 
    if [[ -n $minsize ]] 
    then 
        sizequery+=( -size +${minsize}c )
    fi 

    if [[ "$dryrun"  == "true"  ]]
    then
       precmd="echo"
       printf "options used:\n"
       print_array findoptions
    else
       precmd=""
    fi

    if [[ "$dironly"  == "true"  ]] 
    then 
        findtype="d" 
    else
        findtype="f"
    fi      

    if [[ "$caseinsens"  == "true"  ]] 
    then 
        findname="iname" 
    else
        findname="name"
    fi   

    local namequery=()
    if [[ -n "$grepfilename" && -n "$ext" ]]
    then
       namequery+=( -$findname "*${grepfilename}*${ext}" )
    elif [[ -n "$grepfilename" ]]   
    then 
       namequery+=( -$findname "*${grepfilename}*" )
    elif [[ -n "$ext" ]]   
    then
       namequery+=( -$findname "*${ext}" )
    fi      

    if [[ -n "$grepcontent" ]] 
    then 
       $precmd find "$dir"  -type $findtype "${namequery[@]}" "${sizequery[@]}"  "${timequery[@]}" -printf "%p\n" 2>/dev/null | contains  "$grepcontent"
    else
       $precmd find "$dir"   -type $findtype "${namequery[@]}" "${sizequery[@]}" "${timequery[@]}" -printf "%p\n" 2>/dev/null
    fi   
}

INDEXED_FIND_CMD="unknown"

_check_index_cmd() {
    # check required command       
    command -v $INDEXED_FIND_CMD &> /dev/null
}

# TODO: _indexed_find_base for linux
if [[ "$OSTYPE" == "linux-gnu" ]]; then

    INDEXED_FIND_CMD="recoll"

    # we use the platform independent recoll, and not baloo(kde) nor tracker(gnome)  
    # see: https://wiki.archlinux.org/title/List_of_applications/Utilities#Full-text_indexers

    # https://www.recoll.org/usermanual/webhelp/docs/
    # https://www.recoll.org/usermanual/webhelp/docs/RCL.SEARCH.COMMANDLINE.html
    # -t : use commandline version of recoll (not gui)
    # -b : basic. Just output urls, no mime types or titles
    

    _indexed_find_base() {
        local -n indexfindoptions=$1

        local grepfilename="${indexfindoptions[grepfilename]}"
        local grepcontent="${indexfindoptions[grepcontent]}"
        local ext="${indexfindoptions[ext]}"
        local max="${indexfindoptions[max]}"
        local min="${indexfindoptions[min]}"
        local maxsize="${indexfindoptions[maxsize]}"
        local minsize="${indexfindoptions[minsize]}"
        local dir="${indexfindoptions[dir]}"
        local dryrun="${indexfindoptions[dry-run]}"
        local dironly="${indexfindoptions[dir-only]}"
        local caseinsens="${indexfindoptions[caseinsens]}"

        if [[ -z "$dir" ]] 
        then 
            dir="$PWD/"    
        else  
            dir=$(realpath "$dir")		
            dir="$dir/"    
        fi 
        local withindirexpr="dir:$dir" 


	# time range
	# https://www.recoll.org/usermanual/webhelp/docs/RCL.SEARCH.LANG.SPECIALFIELDS.html
	# Only dates are supported, no times. 
	#   date:2001-03-01/2002-05-01
	# If the / is present but an element is missing, the missing element is interpreted as the lowest or highest date in the index.
	# note: we cannot have range with start and end period, so we have to calculate dates
	#       for which we use gnu date. src: https://www.linuxquestions.org/questions/programming-9/bash-date-days-subtraction-addition-and-compare-946527-print/
        local timequery=""
        if [[  -n "$max" || -n "$min" ]]
        then     
            if [[ -z "$max" ]]
                then 
                begin=""
            else 
                begin=$(date +"%Y-%m-%d" -d "$max days ago")
                # note: works with GNU's date which is standard on linux
                fi	      
            if [[ -z "$min" ]]
                then 
                end=""
            else 
                    end=$(date +"%Y-%m-%d" -d "$min days ago")
                # note: works with GNU's date which is standard on linux
                fi	      
            if [[ -z "$min" && -z "$max" ]]
                then 
                    timequery=""
                else	      
                    timequery="date:$begin/$end"
            fi   
        fi    

        local sizequery=""
        if [[ -n $maxsize ]] 
        then 
            sizequery="size<$maxsize"
        fi 
        if [[ -n $minsize ]] 
        then 
            sizequery="$sizequery size>$minsize"
        fi 

        ## The default index build with recoll is case insensitive.
        ## Instead a 'raw index' can be build with recoll, but we assume people use the standard installation, so we assume case insensitivity by default!
        # if [[ "$caseinsens"  == "true"  ]] 
        # then 
        #     caseletter="" 
        # else
        #     caseletter="C"
        # fi  
        
        local grepfilenamequery=""
        if [[  -n "$grepfilename"  ]]
        then
            grepfilenamequery="filename:*$grepfilename*"
        fi    

        local extquery=""
        if [[  -n "$ext"  ]]
        then
	    # remove dot(s) prefix
            ext=${ext##*.}
            extquery="ext:$ext"
        fi    

        local grepcontentquery=""
        if [[ -n $grepcontent ]] 
        then 
            grepcontentquery="$grepcontent"
        fi   
        
        if [[ "$dironly" == "true" ]]
        then 
            typeexpr='mime:inode/directory' 
	    # source:
	    #  https://askubuntu.com/questions/243831/how-to-make-recoll-search-or-locate-folder-only-not-the-files
	    #  https://stackoverflow.com/questions/18869772/mime-type-for-a-directory
        else
            typeexpr='-mime:inode/directory' 
        fi    

        if [[ "$dryrun"  == "true"  ]]
        then
            precmd="echo"
            printf "options used:\n"
            print_array indexfindoptions
        else
            precmd=""
        fi

        $precmd recoll -t -b "$withindirexpr" $sizequery $timequery $grepfilenamequery $extquery $grepcontentquery $typeexpr   2>/dev/null | sed -e 's/^file:\/\///'
     }
fi

if [[ "$OSTYPE" == darwin* ]]; then 

    INDEXED_FIND_CMD="mdfind"

    _indexed_find_base() {

        local -n indexfindoptions=$1

        local grepfilename="${indexfindoptions[grepfilename]}"
        local grepcontent="${indexfindoptions[grepcontent]}"
        local ext="${indexfindoptions[ext]}"
        local max="${indexfindoptions[max]}"
        local min="${indexfindoptions[min]}"
        local maxsize="${indexfindoptions[maxsize]}"
        local minsize="${indexfindoptions[minsize]}"
        local dir="${indexfindoptions[dir]}"
        local dryrun="${indexfindoptions[dry-run]}"
        local dironly="${indexfindoptions[dir-only]}"
        local caseinsens="${indexfindoptions[caseinsens]}"

        if [[ -z "$dir" ]] 
        then 
            dir="."
        else 
            dir="$dir/"    
        fi 
        local withindirexpr=( "-onlyin" "$dir" )
        #  no onlyin option is same as  "-onlyin /" option

        # options
        #   --min n :  file has date n days or more ago     
        #   --max n :  file has date n days or less ago   
        # where   
        #    n=0 is today
        #    n=1 is yesterday
        #    --min a --max b  specifies all days in range [ a, b ] including the boundary days
        # so 
        #    --min 0  means all files of today and older
        #    --min 1  means all files of yesterday and older
        #    --max 0  means all files of today and newer
        #    --max 1  means all files of yesterday and newer
        #
        # for mdfind we have to specify a time range which gives integer range
        # relative to today.  
        #   range(-5,-2)  = [-5,-2)  ->   3 to 5 days old
        #   range(-5,0)   = [-5,0)  ->    1 t0 5 days old
        #   range(-5,1)   = [-5,1)  ->    0 t0 5 days old
        # so 
        #   when --min a --max b  specifies all days in range [ a, b ] including the boundary days
        #                              from minimal a days ago to maximum of b days ago 
        # then this translates to inrange for mdfind:
        #   range(-b,-a+1)

        local timequery=""
        if [[  -n "$max" || -n "$min" ]]
        then     
           # if value not set, then set to default value
           max=${max:-10000}
           min=${min:-0}
           inrange_arg1="-$max"
           inrange_arg2=$(( "-$min" + 1))  
           timequery="InRange(kMDItemContentModificationDate, \$time.today(${inrange_arg1}d) , \$time.today(${inrange_arg2}d) )  && " 
        fi    

        local sizequery=""
        if [[ -n $maxsize ]] 
        then 
            sizequery="kMDItemFSSize < $maxsize && "
        fi 
        if [[ -n $minsize ]] 
        then 
            sizequery="$sizequery kMDItemFSSize > $minsize && "
        fi 

        if [[ "$caseinsens"  == "true"  ]] 
        then 
            caseletter="c" 
        else
            caseletter=""
        fi  

        local grepfilenamequery=""
        if [[  -n "$grepfilename"  ]]
        then
            grepfilenamequery="kMDItemDisplayName == '*$grepfilename*'$caseletter &&"
        fi    

        local extquery=""
        if [[  -n "$ext"  ]]
        then
            extquery="kMDItemDisplayName == '*$ext'$caseletter &&"
        fi    

        local grepcontentquery=""
        if [[ -n $grepcontent ]] 
        then 
            grepcontentquery="kMDItemTextContent=='*$grepcontent*'$caseletter && "
        fi   

        if [[ "$dironly" == "true" ]]
        then 
            typeexpr='kMDItemContentType==public.folder' 
        else
            typeexpr='kMDItemContentType!=public.folder'
        fi    

        if [[ "$dryrun"  == "true"  ]]
        then
            precmd="echo"
            printf "options used:\n"
            print_array indexfindoptions
        else
            precmd=""
        fi

        $precmd mdfind "${withindirexpr[@]}"  "$sizequery $timequery $grepfilenamequery $extquery $grepcontentquery $typeexpr "  
     }

fi 

