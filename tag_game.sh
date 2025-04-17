#!/bin/bash

# Grid size
ROWS=30
COLS=30

# Player initial positions
player1_row=$((ROWS / 2 - 2))
player1_col=$((COLS / 3))
player2_row=$((ROWS / 2 + 2))
player2_col=$((COLS * 2 / 3))

time_limit=60  # Game time limit in seconds
start_time=$(date +%s)
tagged=true  # Player 1 starts as 'it'
tag_cooldown=0

# Obstacle and teleport positions
obstacle_count=10
declare -A obstacles

# Generate random obstacles
for ((i=0; i<obstacle_count; i++)); do
    row=$((RANDOM % ROWS + 1))
    col=$((RANDOM % COLS + 1))
    obstacles[$row,$col]="#"
done

# Function to place teleport points
place_teleports() {
    teleport1_row=$((RANDOM % ROWS + 1))
    teleport1_col=$((RANDOM % COLS + 1))
    teleport2_row=$((RANDOM % ROWS + 1))
    teleport2_col=$((RANDOM % COLS + 1))
}

place_teleports

# Function to print the grid
display_grid() {
    clear
    for ((i=1; i<=ROWS; i++)); do
        echo -n "    "
        for ((j=1; j<=COLS; j++)); do
            if [[ $i -eq $player1_row && $j -eq $player1_col ]]; then
                if $tagged; then
                    echo -ne " \e[1;31m1\e[0m "
                else
                    echo -ne " \e[1;32m1\e[0m "
                fi
            elif [[ $i -eq $player2_row && $j -eq $player2_col ]]; then
                if ! $tagged; then
                    echo -ne " \e[1;31m2\e[0m "
                else
                    echo -ne " \e[1;32m2\e[0m "
                fi
            elif [[ ${obstacles[$i,$j]} == "#" ]]; then
                echo -ne " \e[1;37m#\e[0m "
            elif [[ $i -eq $teleport1_row && $j -eq $teleport1_col ]]; then
                echo -ne " \e[1;34mT\e[0m "
            elif [[ $i -eq $teleport2_row && $j -eq $teleport2_col ]]; then
                echo -ne " \e[1;34mT\e[0m "
            else
                echo -n " . "
            fi
        done
        echo ""
    done
}

# Function to move the players
move_player() {
    local key=$1
    local -n row=$2
    local -n col=$3
    local new_row=$row
    local new_col=$col

    case $key in
        w) ((new_row--)); ;;
        s) ((new_row++)); ;;
        a) ((new_col--)); ;;
        d) ((new_col++)); ;;
        i) ((new_row--)); ;;
        k) ((new_row++)); ;;
        j) ((new_col--)); ;;
        l) ((new_col++)); ;;
    esac

    if [[ -z ${obstacles[$new_row,$new_col]} && $new_row -ge 1 && $new_row -le $ROWS && $new_col -ge 1 && $new_col -le $COLS ]]; then
        row=$new_row
        col=$new_col
    fi
}

stty -echo -icanon time 0 min 0

# Game loop
while true; do
    display_grid

    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    remaining=$((time_limit - elapsed))
    echo "Time left: $remaining seconds"

    if ((remaining <= 0)); then
        if $tagged; then
            echo -e "\e[1;31m\e[1mTime's up! PLAYER 1 LOSES!\e[0m"
        else
            echo -e "\e[1;34m\e[1mTime's up! PLAYER 2 LOSES!\e[0m"
        fi
        echo -e "\a"
        break
    fi

    read -sn1 keypress
    if [[ "$keypress" =~ [wasd] ]]; then
        move_player "$keypress" player1_row player1_col
    elif [[ "$keypress" =~ [jikl] ]]; then
        move_player "$keypress" player2_row player2_col
    fi
    
    # Teleportation logic (Both players can teleport)
    if [[ $player1_row -eq $teleport1_row && $player1_col -eq $teleport1_col ]]; then
        player1_row=$teleport2_row
        player1_col=$teleport2_col
        place_teleports
    elif [[ $player1_row -eq $teleport2_row && $player1_col -eq $teleport2_col ]]; then
        player1_row=$teleport1_row
        player1_col=$teleport1_col
        place_teleports
    fi
    
    if [[ $player2_row -eq $teleport1_row && $player2_col -eq $teleport1_col ]]; then
        player2_row=$teleport2_row
        player2_col=$teleport2_col
        place_teleports
    elif [[ $player2_row -eq $teleport2_row && $player2_col -eq $teleport2_col ]]; then
        player2_row=$teleport1_row
        player2_col=$teleport1_col
        place_teleports
    fi

    # Tagging logic
    if [[ $player1_row -eq $player2_row && $player1_col -eq $player2_col && $tag_cooldown -eq 0 ]]; then
        tagged=$(! $tagged && echo true || echo false)
        tag_cooldown=3
        echo -e "\e[1;33mTag passed! You are now the Tagger!\e[0m"
        echo -e "\a"
    fi

    if ((tag_cooldown > 0)); then
        ((tag_cooldown--))
    fi

done

stty sane
