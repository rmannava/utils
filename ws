#!/bin/bash
# set current workspace by either workspace name or workspace number
# makes no guarantees about successful switch (e.g. invalid index numbers)

data=~/utils/ws_data/names

# lists all mappings
function list {
    # count the number of lines in the data file
    count=$(echo $(wc -l $data) | cut -d ' ' -f 1)
    if [[ $count = 0 ]]
    then
        echo "No mappings to list"
    else
        cat $data
    fi
}

# adds a name - index mapping for the given name and index
function add_name {
    name="$1"
    index="$2"
    # check for valid index
    if [[ "$index" =~ ^[0-9]+$ ]]
    then
        # add entry to data file
        echo "$name - $index" >> $data
        echo "Name $name added for workspace index $index"
    else
        echo "$index is not a valid index"
    fi
}

# removes all name - index mappings for the given name
function remove_name {
    name="$1"
    grep -q "^$name - " $data
    # check if name was found
    if [[ $? = 0 ]]
    then
        # remove all mappings for name
        sed -i "/^$name - /d" $data
        echo "Name $name removed"

    else
        echo "Name $name not found"
    fi
}

# removes all name - index mappings for the given index
function remove_index {
    index="$1"
    grep -q " - $index$" $data
    # check if index was found
    if [[ $? = 0 ]]
    then
        # remove all mappings for index
        sed -i "/ - $index$/d" $data
        echo "Workspace with index $index removed"
    else
        echo "Workspace with index $index not found"
    fi
}

# changes all old_name mappings to new_name mappings
function rename {
    old_name="$1"
    new_name="$2"
    grep -q "^$old_name - " $data
    # check if old_name was found
    if [[ $? = 0 ]]
    then
        # swap all mappings for old_name to new_name
        sed -i "s/^$old_name - /$new_name - /g" $data
        echo "$old_name renamed to $new_name"
    else
        echo "Name $old_name not found"
    fi
}

# finds a workspace index from the given name
function find_index {
    name="$1"
    # search for name
    line=$(grep "^$name - " $data)
    # check if name was found
    if [[ $? = 0 ]]
    then
        # select the index string and trim
        index=$(echo $line | cut -d '-' -f 2 | xargs)
        echo "Mapping $line found"
    else
        index=-1
    fi
}

# tries to switch current workspace to the given index
function switch_workspace {
    index="$1"
    echo "Attempting switch to workspace $index"
    wmctrl -s "$index"
}

# resets all workspace mappings
function reset {
    # clear the data file
    > $data
    echo "All workspace mappings reset"
}

# check for default use case
if [[ -z "$1" ]]
then
    echo "Default option selected"
    switch_workspace 0
fi
# check if input is an index
if [[ "$1" =~ ^[0-9]+$ ]]
then
    # check if index given is actually a name
    find_index $1
    if [[ $index != -1 ]]
    then
        switch_workspace "$index"
    else
        echo "$1 interpreted as workspace index"
        switch_workspace "$1"
    fi
elif [[ "$1" = "list" ]]
then
    list
elif [[ "$1" = "add" ]]
then
    # make sure both required arguments are present
    if [[ -z "$2" || -z "$3" ]]
    then
        echo "Name and workspace index required"
    else
        add_name $2 $3
    fi
elif [[ "$1" = "remove" ]]
then
    # make sure both required arguments are present
    if [[ -z "$2" || -z "$3" ]]
    then
        echo "Identifier and value required"
    else
        # check removal method
        if [[ "$2" = "name" ]]
        then
            remove_name $3
        elif [[ "$2" = "index" ]]
        then
            remove_index $3
        else
            echo "Identifier must be [name,index]"
        fi
    fi
elif [[ "$1" = "rename" ]]
then
    # make sure both required arguments are present
    if [[ -z "$2" || -z "$3" ]]
    then
        echo "Old_name and new_name required"
    else
        rename "$2" "$3"
    fi
elif [[ "$1" = "reset" ]]
then
    reset
# print usage information
elif [[ "$1" = "help" ]]
then
    echo "Usage: ws [add|index|list|name|remove|rename]"
    echo ""
    echo "With no arguments, switches to workspace 0"
    echo ""
    echo "add:    expects a name and a index; adds a mapping of name - index"
    echo "index:  expects a valid workspace index, giving priority to interpretation as a name; changes workspace to the given index"
    echo "list:   lists all name - index mappings"
    echo "name:   expects an existing workspace name; changes workspace to the corresponding index"
    echo "remove: expects an identifier of [name|index] and a value; removes all mappings for the name or index"
    echo "rename: expects an old_name and new_name; changes all mappings for old_name to new_name"
    echo "reset:  resets all workspace mappings"
    echo ""
# perform requested switch
else
    find_index $1
    # check if index parsing was successful
    if [[ $index != -1 ]]
    then
        switch_workspace "$index"
    else
        echo "Name $1 not found"
    fi
fi
