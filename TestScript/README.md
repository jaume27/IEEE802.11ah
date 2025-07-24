# Explicació codi test proves AHPI7292S script en bash
Aquest codi ens serveix per poder fer proves simulant trànsit de xarxa amb iperf3.
L'objectiu d'aquest codi es el d'automatitzar la recolecció de dades com el throughput o el jitter desde iperf3 variant varies configuracions, en aquest cas el GI (Guard Interval) i el MCS (Modulation coding scheme).
> Aquest codi només funcionarà per el mòdul AHPI7292S, ja que les modificacions de les configuracions es fan a partir dels evk que ens suministra el client.
