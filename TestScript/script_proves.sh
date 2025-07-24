#!/bin/bash

######### CONFIGURACIÓ PROVES #########

# Nom fitxer resultats
OUTPUT_FILE="iperf3_results_estalviEnergia.csv"

# Iteracions iperf3 per configuració
REPETITIONS=3 

# Duració prova iperf3 (-t)
IPERF_TEST_DURATION=10 #segons

#Protocol
PROTOCOL=0 # [0: TCP, 1: UDP]

#Extracció de resultats
    # En aquest cas només agafa la línea recive
NUMBER_OF_LINES_TO_EXTRACT=3
NUMBER_OF_LINES_TO_EXTRACT_HEAD=1

#Downlink
downlink=0

#######################################

set -e

if [ -z "$1" ]; then
    echo "USAGE: $0 <SERVER_IP>"
    exit 1
fi

SERVER_IP="$1"
MCS_INDEXES=(0 1 2 3 4 5 6 7)
GI_INTERVALS=("short" "long")

extract_lines() {
    local input_string="$1"

    echo "$input_string" | tail -n "$NUMBER_OF_LINES_TO_EXTRACT" | head -n "$NUMBER_OF_LINES_TO_EXTRACT_HEAD"
}

#Capcelera document resultats
echo "RESULTATS TEST IPERF3 VARIANT MCS I GI" > "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

#Barra de progrés
total_iterations=$(( ${#MCS_INDEXES[@]} * ${#GI_INTERVALS[@]} * REPETITIONS ))
current_iteration=0
bar_length=50 
max_progress_line_length=100

is_first_iteration=true

#Amagar cursor
if command -v tput >/dev/null 2>&1; then
    HIDE_CURSOR=$(tput civis)
    SHOW_CURSOR=$(tput cnorm)
else
    HIDE_CURSOR='\033[?25l' 
    SHOW_CURSOR='\033[?25h'
fi

display_progress_bar() {
    local iperf_internal_progress_percent="$1"
    local overall_progress_percent=$(( ($current_iteration * 100) / $total_iterations ))

    local filled_length=$(( ($bar_length * $overall_progress_percent) / 100 ))
    local empty_length=$(( $bar_length - $filled_length ))
    local filled_bar=$(printf "%${filled_length}s" | tr ' ' '#')
    local empty_bar=$(printf "%${empty_length}s" | tr ' ' '-')

    local progress_string=$(printf "[%s%s] %d%% (%d/%d) - %d%%" \
        "$filled_bar" "$empty_bar" "$overall_progress_percent" "$current_iteration" "$total_iterations" \
        "$iperf_internal_progress_percent")

    printf "\r" 
    if command -v tput >/dev/null 2>&1; then
        tput el 
    else
        printf "%*s\r" "$max_progress_line_length" ""
    fi
    printf "%s" "$progress_string"
}

printf "%s" "$HIDE_CURSOR"
trap 'printf "%s\n" "$SHOW_CURSOR"' EXIT

#ESTIMACIÓ TEMPS
script_start_time=$(date +%s)

base=$(( ${#MCS_INDEXES[@]} * ${#GI_INTERVALS[@]} * REPETITIONS * IPERF_TEST_DURATION ))
extra=$(( ${#MCS_INDEXES[@]} * ${#GI_INTERVALS[@]} * REPETITIONS))
tiempo_estimado=$(( base + extra ))

minuts_estimados=$((tiempo_estimado / 60))
segons_estimados=$((tiempo_estimado % 60))

rellotge_estimado=$(printf "%02d:%02d" $minuts_estimados $segons_estimados)

#CAPCELERA PROGRAMA
clear
echo "================================================================"
echo "               Análisis de Rendimiento Wi-Fi HaLow"
echo "                (IEEE 802.11ah) Módulo AHPI7292S"
echo "================================================================"

press_any_key_to_continue() {
    local message="${1:-Presiona qualsevol tecla per continuar...}"
    echo -e "\n$message"
    read -n 1 -s
    echo
}

#COMPROVACIÓ SERVIDOR IPERF3
check_server_availability() {
    local server_ip="$1"
    local ping_count=1 
    local ping_timeout=10 
    local iperf3_port=5201 
    local iperf3_test_duration=1 
    local RED='\033[0;31m'
    local GREEN='\033[0;32m' 
    local YELLOW='\033[0;33m' 
    local NC='\033[0m'

    echo -e "\nComprovant disponibilitat servidor iperf3 amb IP: $server_ip\n"

    if ! ping -c "$ping_count" -W "$ping_timeout" "$server_ip" > /dev/null 2>&1; then
        echo -e "${RED}ERROR: El servidor $server_ip no és accesible via ping.${NC}"
        echo -e "${YELLOW}Assegura't que la IP és correcta i el servidor està en línia.${NC}\n"
        return 1 # Fallo ping
    fi
    echo -e "${GREEN}Servidor $server_ip accesible via ping.${NC}\n"

    echo "Comprovar si iperf3 -s està actiu a $server_ip:$iperf3_port..."

    if iperf3 -c "$server_ip" -p "$iperf3_port" -t "1" > /dev/null 2>&1; then
        echo 
        echo -e "${GREEN}iperf3 -s està actiu i escoltant a $server_ip:$iperf3_port.${NC}"
        return 0 
    else
        echo -e "${RED}ERROR: No s'ha pogut connectar a iperf3 -s a $server_ip:$iperf3_port.${NC}"
        echo -e "${YELLOW}Assegura't que 'iperf3 -s' s'està executant al servidor.${NC}"
        return 1 # Fallo iperf3
    fi
}

if check_server_availability "$SERVER_IP"; then
    press_any_key_to_continue
else
    exit 1
fi

clear
echo "================================================================"
echo "               Anàlisis de Rendiment Wi-Fi HaLow"
echo "                (IEEE 802.11ah) Mòdul AHPI7292S"
echo "================================================================"

#CAPCELERA TESTS
echo " "
echo -e "Test with iperf3 in server \033[0;33m $SERVER_IP \033[0m starting..."
echo "Estimated completion time: $rellotge_estimado"
echo " "

if [ "$PROTOCOL" -eq 1 ]; then
    protocol_nom="UDP"
else
    protocol_nom="TCP"
fi

echo -e "\e[1;34mProtocol en ús: $protocol_nom\e[0m"
echo "--------------------------">> $OUTPUT_FILE
echo "Protocol: $protocol_nom   ">> $OUTPUT_FILE
echo "--------------------------">> $OUTPUT_FILE
echo >> $OUTPUT_FILE


for gi_int in "${GI_INTERVALS[@]}"; do
    for mcs_idx in "${MCS_INDEXES[@]}"; do

        #CONFIGURACIÓ MÒDUL WIFI-HALOW
	./cli_app set rc off > /dev/null 2>&1 #Permet determinar MCS
        ./cli_app test mcs "$mcs_idx" > /dev/null 2>&1
        ./cli_app set gi "$gi_int" > /dev/null 2>&1

        for rep_idx in $(seq 1 "$REPETITIONS"); do

            #Format línea de progrés
            if [ "$is_first_iteration" = false ]; then
                printf "\033[2A"
                if command -v tput >/dev/null 2>&1; then
                    tput el
                else
                    printf "\r%*s\r" "$max_progress_line_length" ""
                fi
                printf "\033[1B"
                if command -v tput >/dev/null 2>&1; then
                    tput el
                else
                    printf "\r%*s\r" "$max_progress_line_length" ""
                fi
                printf "\033[1A\r"
            fi

            current_elapsed_seconds=$(( $(date +%s) - script_start_time ))
            elapsed_minuts=$((current_elapsed_seconds / 60))
            elapsed_segons=$((current_elapsed_seconds % 60))
            elapsed_time_formatted=$(printf "%02d:%02d" $elapsed_minuts $elapsed_segons)
            printf "MCS: %s, GI: %s (Repetición: %d/%d) (Tiempo: %s)" "$mcs_idx" "$gi_int" "$rep_idx" "$REPETITIONS" "$elapsed_time_formatted"
            printf "\n"

            #Crida a iperf3
            if [ "$PROTOCOL" -eq 0 ]; then
                iperf3 -c "$SERVER_IP" -t "$IPERF_TEST_DURATION" > /tmp/iperf3_output_$$ 2>&1 &
            else
                iperf3 -c "$SERVER_IP" -t "$IPERF_TEST_DURATION" -u -b 20M > /tmp/iperf3_output_$$ 2>&1 &
            fi

            IPERF_PID=$!

            total_internal_steps=$((IPERF_TEST_DURATION * 10))
            for (( i=0; i<=$total_internal_steps; i++ )); do

                current_elapsed_seconds=$(( $(date +%s) - script_start_time ))
                elapsed_minuts=$((current_elapsed_seconds / 60))
                elapsed_segons=$((current_elapsed_seconds % 60))
                elapsed_time_formatted=$(printf "%02d:%02d" $elapsed_minuts $elapsed_segons)

                printf "\033[1A\r"
                if command -v tput >/dev/null 2>&1; then
                    tput el
                else
                    printf "%*s\r" "$max_progress_line_length" ""
                fi
                printf "MCS: %s, GI: %s (Repetición: %d/%d) (Tiempo: %s)" "$mcs_idx" "$gi_int" "$rep_idx" "$REPETITIONS" "$elapsed_time_formatted"
                printf "\033[1B\r"

                iperf_internal_progress_percent=$(( (i * 100) / total_internal_steps ))
                display_progress_bar "$iperf_internal_progress_percent"

                if [ "$i" -lt "$total_internal_steps" ]; then
                    sleep 0.1 
                fi
            done

            wait "$IPERF_PID"
            last_iperf_output=$(cat /tmp/iperf3_output_$$)
            rm /tmp/iperf3_output_$$

            current_iteration=$((current_iteration + 1))

            current_elapsed_seconds=$(( $(date +%s) - script_start_time ))
            elapsed_minuts=$((current_elapsed_seconds / 60))
            elapsed_segons=$((current_elapsed_seconds % 60))
            elapsed_time_formatted=$(printf "%02d:%02d" $elapsed_minuts $elapsed_segons)

            printf "\033[1A\r" 
            if command -v tput >/dev/null 2>&1; then
                tput el
            else
                printf "\r%*s\r" "$max_progress_line_length" ""
            fi
            printf "MCS: %s, GI: %s (Repetición: %d/%d) (Tiempo: %s)" "$mcs_idx" "$gi_int" "$rep_idx" "$REPETITIONS" "$elapsed_time_formatted"
            printf "\033[1B\r"
            display_progress_bar 100
            printf "\n" 

            extracted_result=$(extract_lines "$last_iperf_output")

            echo "MCS: $mcs_idx, GI: $gi_int ($rep_idx/$REPETITIONS)" >> "$OUTPUT_FILE"
            echo "-> \"$extracted_result\"" >> "$OUTPUT_FILE"

            is_first_iteration=false
        done 
        echo "----------" >> "$OUTPUT_FILE"
    done
done

echo
echo -e "\e[1;32m✅ Tests completats amb èxit\e[0m"
echo "Resultats a $OUTPUT_FILE"
