# Explicació codi test proves AHPI7292S script en bash
Aquest codi ens serveix per poder fer proves simulant trànsit de xarxa amb iperf3.
L'objectiu d'aquest codi es el d'automatitzar la recolecció de dades com el throughput o el jitter desde iperf3 variant varies configuracions, en aquest cas el GI (Guard Interval) i el MCS (Modulation coding scheme).
> Aquest codi només funcionarà per el mòdul AHPI7292S, ja que les modificacions de les configuracions es fan a partir dels evk que ens suministra el client.

### Configuracions aplicació
```python
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
```

