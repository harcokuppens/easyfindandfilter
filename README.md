# Easy find and filter

Make finding files and words in files easier using simple specialised find and filtering commands using pipelines with optionally using an optimised search using your platforms desktop search index.


To use these commands read the documentation in the `help_find` command:


    $ help_find
    
    NAME 

      easyfindandfilter: find commands with filters and output tuning

    DESCRIPTION

      Make finding files and words in files easier using simple specialised find, filtering and output commands.
      These commands can be combined using pipelines as follows:

            FIND_CMD | FILTER_CMD_1  | FILTER_CMD_2 | ... | OUTPUT_CMD

      By default searching is done using the 'find' command, however providing the '-x' option we
      can speed up searching using an indexed searching tool.   
      Results of indexed search are always absolute paths, whereas when using find we get relative paths.
      When using indexed search we can only search locations which are indexed. For example, hidden folders
      starting with '.' are not indexed. So when searching with 'find' command hidden folders are searched
      but not with indexed search.
  
      To see the actual command run you can use the '-n' or '--dry-run' option.

    All find command commands are based on a base command:

      findbase [-i] [-n|--dry-run] [-x|--index] [--dir|-d DIR] [--dir-only] 
                [--min NUMDAYS] [--max NUMDAYS] [--minsize SIZE] [--maxsize SIZE]
                [--grepfilename WORD] [--ext EXT] [--grepcontent WORD]

    OPTIONS
    
        -i 
            search case insensitive. Default search is case sensitive.
            Note that when using indexed search using recoll on linux the search is 
            already by default case insensitive.

        -n|--dry-run
            do not actual run the constructed command but instead print it

        -x|--index
            use indexed searched instead of using find/grep  (recoll on linux, mdfind on macos)

        --dir|-d DIR
            start searching from DIR

        --dir-only
            only search for directories 

        --min NUMDAYS 
            search for files which last changed NUMDAYS or more ago

        --max NUMDAYS 
            search for files which last changed NUMDAYS or less ago

        --minsize SIZE 
            search for files which have size SIZE or bigger
            where 
              SIZE=[0-9]+[bkmgBKMG]?  
              the unit letter is either b(byte),k(kibibyte),m(mibibyte),g(gibibyte) 
              the unit letter is case insensitive and by default the unit is byte.
            examples: 23,23G,23g,23m,23b,23K,23k

        --maxsize SIZE 
            search for files which have size SIZE or smaller
        
        --grepfilename WORD
            search for files containing WORD in filename 

        --ext EXT
            search for files with extension .EXT    

        --grepcontent WORD
            search for files containing WORD in content


    DERIVED FIND COMMANDS

      -> all commands  can use same options as in findbase 
          but positional params in them overrule the corresponding option param

      ff [WORD] [EXT] : find files with WORD in filepath in PWD recursively
        -> if EXT is missing and WORD starts with . , then it is used as extension

      fft [WORD]    : find text files with WORD in filepath in PWD recursively
                      note: same as  'ff [WORD] .txt' where WORD is optional 

      fd  [WORD]    : find directories with WORD in filepath in PWD recursively

      fw WORD [EXT] : find word in files, that is files containing word, in PWD recursively
      fwt WORD      : find word in text files, that is text files containing word, in PWD recursively
                      note: same as  'fwt WORD .txt' 

      => for searching specific dir just use --dir option, default is cwd 

    FILTER COMMANDS
    
        Using the option '-i' below we can filter case insensitive.

        - grep     [-i] : filters on matching filepath (the standard 'grep' command)
        - grepname [-i] : filters on matching filename
        - contains [-i] : filters on matching word in file's contents

    OUTPUT COMMANDS 

        Using the option '-r' below we revert the sort order.

          - timed     [-r]   : sort on datetime and add datetime prefix.
          - sized     [-r]   : sort on size and add size prefix (1K = 1024, 1M = 1048576, ...) 
          - bytesized [-r]   : sort on size and add size prefix in bytes 
          - timesort  [-r]   : only sort on datetime
          - sizesort  [-r]   : only sort on size 
          - show [-i] [-c N] WORD : 
                              Matching word in file's contents and show N lines of context of match.
                              Using the option '-i' below we can match show WORD case insensitive.
          - rw [-y] MATCH REPLACEMENT : 
                              Replace each MATCH with REPLACEMENT in file's contents.
                              Per file asks user confirmation unless -y option is supplied.

    EXAMPLES
 
        find text files matching 'help' in dayrange 3-10 old
          fft --min 3 --max 10 help | timed

        find text files in dayrange 3-10 old
          fft --min 3 --max 10 | timed

        find all text files containing rdesk in ~/doc
          fw --dir ~/doc rdesk .txt
    
        combined with contains
          fft --min 3 --max 10     | contains container | timed
          ff --min 3 --max 10 .txt | contains container | timed
            or   
          fw --min 3 --max 10 --ext .txt  container | timed

        search for container or box 
          fft --min 3 --max 10 | contains -e container -e box | timed
        search for container and box 
          fft --min 3 --max 10 | contains container | contains  box | timed

        show context of matches (sorted on time)     
          fft --min 3 --max 10 | contains container | timesort | show container
  


    SPECIAL CONVENIENT COMMANDS 

        - for searching in documents folder we have aliases with d appended: 
          ffd,fftd,fdd,fwd,fwd,fwtd
  
        - finding text files changed in last 100 days:   
          fl (current dir), fld (in documents dir)
