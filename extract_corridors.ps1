# =============================================================================
# TRINO EXTRACTION QUERIES — OpenSky Network ADS-B Data
# =============================================================================
# Study: Wind-corrected cruise-speed variation in European aviation
# Author: Joan Tarradellas, EADA Business School
#
# SETUP:
# 1. Download Trino CLI from https://trino.io/download.html
# 2. Place trino-cli.jar in your working directory
# 3. Register at https://opensky-network.org for academic access
# 4. Replace YOUR_USERNAME with your OpenSky username
# 5. Replace OUTPUT_PATH with your local output directory
#
# Each query opens a browser OAuth login window.
# Run queries one at a time.
# =============================================================================

# =============================================================================
# CORRIDOR DEFINITIONS
# =============================================================================
# C1: Central France Northbound
#     Box: 43-47°N, 1°W-4°E | Heading: 330-030° | Airlines: VLG, IBE, IBS, EWG, EZY, AFR
#
# C2: Central Europe Westbound
#     Box: 49-53°N, 4-12°E  | Heading: 260-300° | Airlines: DLH, BAW, AFR, EWG, EZY, IBE, VLG, AUA, SWR
#
# C3: North Atlantic Control (westbound, March only)
#     Box: 50-55°N, 15-5°W  | Heading: 260-300° | Airlines: BAW, AFR, VIR, DLH, KLM, ACA
#
# C4: Iberian Peninsula Southbound
#     Box: 36-42°N, 5-10°W  | Heading: 160-220° | Airlines: VLG, IBE, IBS, RYR, TAP, EZY
#
# C5: Scandinavia Northbound
#     Box: 55-60°N, 10-20°E | Heading: 330-030° | Airlines: DLH, NOZ, SAS, EWG, RYR, WZZ, FIN, EZY
# =============================================================================

# =============================================================================
# UNIX TIMESTAMPS — 10:00 UTC daily, 2023
# Generated in R: as.numeric(as.POSIXct(paste(date, "10:00:00"), tz="UTC"))
# =============================================================================
# January 2023 (31 days):
# 1672567200 1672653600 1672740000 1672826400 1672912800 1672999200 1673085600
# 1673172000 1673258400 1673344800 1673431200 1673517600 1673604000 1673690400
# 1673776800 1673863200 1673949600 1674036000 1674122400 1674208800 1674295200
# 1674381600 1674468000 1674554400 1674640800 1674727200 1674813600 1674900000
# 1674986400 1675072800 1675159200

# March 2023 (31 days):
# 1677664800 1677751200 1677837600 1677924000 1678010400 1678096800 1678183200
# 1678269600 1678356000 1678442400 1678528800 1678615200 1678701600 1678788000
# 1678874400 1678960800 1679047200 1679133600 1679220000 1679306400 1679392800
# 1679479200 1679565600 1679652000 1679738400 1679824800 1679911200 1679997600
# 1680084000 1680170400 1680256800

# June 2023 (30 days):
# 1685613600 1685700000 1685786400 1685872800 1685959200 1686045600 1686132000
# 1686218400 1686304800 1686391200 1686477600 1686564000 1686650400 1686736800
# 1686823200 1686909600 1686996000 1687082400 1687168800 1687255200 1687341600
# 1687428000 1687514400 1687600800 1687687200 1687773600 1687860000 1687946400
# 1688032800 1688119200

# November 2023 (30 days):
# 1698832800 1698919200 1699005600 1699092000 1699178400 1699264800 1699351200
# 1699437600 1699524000 1699610400 1699696800 1699783200 1699869600 1699956000
# 1700042400 1700128800 1700215200 1700301600 1700388000 1700474400 1700560800
# 1700647200 1700733600 1700820000 1700906400 1700992800 1701079200 1701165600
# 1701252000 1701338400

# =============================================================================
# C1 — Central France Northbound
# =============================================================================

# C1 January 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1672567200, 1672653600, 1672740000, 1672826400, 1672912800, 1672999200, 1673085600, 1673172000, 1673258400, 1673344800, 1673431200, 1673517600, 1673604000, 1673690400, 1673776800, 1673863200, 1673949600, 1674036000, 1674122400, 1674208800, 1674295200, 1674381600, 1674468000, 1674554400, 1674640800, 1674727200, 1674813600, 1674900000, 1674986400, 1675072800, 1675159200) AND lat BETWEEN 43.0 AND 47.0 AND lon BETWEEN -1.0 AND 4.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'AFR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C1_jan2023.csv

# C1 March 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1677664800, 1677751200, 1677837600, 1677924000, 1678010400, 1678096800, 1678183200, 1678269600, 1678356000, 1678442400, 1678528800, 1678615200, 1678701600, 1678788000, 1678874400, 1678960800, 1679047200, 1679133600, 1679220000, 1679306400, 1679392800, 1679479200, 1679565600, 1679652000, 1679738400, 1679824800, 1679911200, 1679997600, 1680084000, 1680170400, 1680256800) AND lat BETWEEN 43.0 AND 47.0 AND lon BETWEEN -1.0 AND 4.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'AFR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C1_mar2023.csv

# C1 June 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1685613600, 1685700000, 1685786400, 1685872800, 1685959200, 1686045600, 1686132000, 1686218400, 1686304800, 1686391200, 1686477600, 1686564000, 1686650400, 1686736800, 1686823200, 1686909600, 1686996000, 1687082400, 1687168800, 1687255200, 1687341600, 1687428000, 1687514400, 1687600800, 1687687200, 1687773600, 1687860000, 1687946400, 1688032800, 1688119200) AND lat BETWEEN 43.0 AND 47.0 AND lon BETWEEN -1.0 AND 4.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'AFR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C1_jun2023.csv

# C1 November 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1698832800, 1698919200, 1699005600, 1699092000, 1699178400, 1699264800, 1699351200, 1699437600, 1699524000, 1699610400, 1699696800, 1699783200, 1699869600, 1699956000, 1700042400, 1700128800, 1700215200, 1700301600, 1700388000, 1700474400, 1700560800, 1700647200, 1700733600, 1700820000, 1700906400, 1700992800, 1701079200, 1701165600, 1701252000, 1701338400) AND lat BETWEEN 43.0 AND 47.0 AND lon BETWEEN -1.0 AND 4.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'AFR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C1_nov2023.csv

# =============================================================================
# C2 — Central Europe Westbound
# =============================================================================

# C2 January 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1672567200, 1672653600, 1672740000, 1672826400, 1672912800, 1672999200, 1673085600, 1673172000, 1673258400, 1673344800, 1673431200, 1673517600, 1673604000, 1673690400, 1673776800, 1673863200, 1673949600, 1674036000, 1674122400, 1674208800, 1674295200, 1674381600, 1674468000, 1674554400, 1674640800, 1674727200, 1674813600, 1674900000, 1674986400, 1675072800, 1675159200) AND lat BETWEEN 49.0 AND 53.0 AND lon BETWEEN 4.0 AND 12.0 AND heading BETWEEN 260 AND 300 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'BAW%' OR callsign LIKE 'AFR%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'IBE%' OR callsign LIKE 'VLG%' OR callsign LIKE 'AUA%' OR callsign LIKE 'SWR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 255 AND 305 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C2_jan2023.csv

# C2 March 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1677664800, 1677751200, 1677837600, 1677924000, 1678010400, 1678096800, 1678183200, 1678269600, 1678356000, 1678442400, 1678528800, 1678615200, 1678701600, 1678788000, 1678874400, 1678960800, 1679047200, 1679133600, 1679220000, 1679306400, 1679392800, 1679479200, 1679565600, 1679652000, 1679738400, 1679824800, 1679911200, 1679997600, 1680084000, 1680170400, 1680256800) AND lat BETWEEN 49.0 AND 53.0 AND lon BETWEEN 4.0 AND 12.0 AND heading BETWEEN 260 AND 300 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'BAW%' OR callsign LIKE 'AFR%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'IBE%' OR callsign LIKE 'VLG%' OR callsign LIKE 'AUA%' OR callsign LIKE 'SWR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 255 AND 305 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C2_mar2023.csv

# C2 June 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1685613600, 1685700000, 1685786400, 1685872800, 1685959200, 1686045600, 1686132000, 1686218400, 1686304800, 1686391200, 1686477600, 1686564000, 1686650400, 1686736800, 1686823200, 1686909600, 1686996000, 1687082400, 1687168800, 1687255200, 1687341600, 1687428000, 1687514400, 1687600800, 1687687200, 1687773600, 1687860000, 1687946400, 1688032800, 1688119200) AND lat BETWEEN 49.0 AND 53.0 AND lon BETWEEN 4.0 AND 12.0 AND heading BETWEEN 260 AND 300 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'BAW%' OR callsign LIKE 'AFR%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'IBE%' OR callsign LIKE 'VLG%' OR callsign LIKE 'AUA%' OR callsign LIKE 'SWR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 255 AND 305 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C2_jun2023.csv

# C2 November 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1698832800, 1698919200, 1699005600, 1699092000, 1699178400, 1699264800, 1699351200, 1699437600, 1699524000, 1699610400, 1699696800, 1699783200, 1699869600, 1699956000, 1700042400, 1700128800, 1700215200, 1700301600, 1700388000, 1700474400, 1700560800, 1700647200, 1700733600, 1700820000, 1700906400, 1700992800, 1701079200, 1701165600, 1701252000, 1701338400) AND lat BETWEEN 49.0 AND 53.0 AND lon BETWEEN 4.0 AND 12.0 AND heading BETWEEN 260 AND 300 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'BAW%' OR callsign LIKE 'AFR%' OR callsign LIKE 'EWG%' OR callsign LIKE 'EZY%' OR callsign LIKE 'IBE%' OR callsign LIKE 'VLG%' OR callsign LIKE 'AUA%' OR callsign LIKE 'SWR%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 255 AND 305 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C2_nov2023.csv

# =============================================================================
# C3 — North Atlantic Control (March 2023 only)
# =============================================================================

java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1677664800, 1677751200, 1677837600, 1677924000, 1678010400, 1678096800, 1678183200, 1678269600, 1678356000, 1678442400, 1678528800, 1678615200, 1678701600, 1678788000, 1678874400, 1678960800, 1679047200, 1679133600, 1679220000, 1679306400, 1679392800, 1679479200, 1679565600, 1679652000, 1679738400, 1679824800, 1679911200, 1679997600, 1680084000, 1680170400, 1680256800) AND lat BETWEEN 50.0 AND 55.0 AND lon BETWEEN -15.0 AND -5.0 AND heading BETWEEN 260 AND 300 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'BAW%' OR callsign LIKE 'AFR%' OR callsign LIKE 'VIR%' OR callsign LIKE 'DLH%' OR callsign LIKE 'KLM%' OR callsign LIKE 'ACA%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 255 AND 305 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C3_mar2023.csv

# =============================================================================
# C4 — Iberian Peninsula Southbound
# =============================================================================

# C4 January 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1672567200, 1672653600, 1672740000, 1672826400, 1672912800, 1672999200, 1673085600, 1673172000, 1673258400, 1673344800, 1673431200, 1673517600, 1673604000, 1673690400, 1673776800, 1673863200, 1673949600, 1674036000, 1674122400, 1674208800, 1674295200, 1674381600, 1674468000, 1674554400, 1674640800, 1674727200, 1674813600, 1674900000, 1674986400, 1675072800, 1675159200) AND lat BETWEEN 36.0 AND 42.0 AND lon BETWEEN -10.0 AND -5.0 AND heading BETWEEN 160 AND 220 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'RYR%' OR callsign LIKE 'TAP%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 155 AND 225 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C4_jan2023.csv

# C4 March 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1677664800, 1677751200, 1677837600, 1677924000, 1678010400, 1678096800, 1678183200, 1678269600, 1678356000, 1678442400, 1678528800, 1678615200, 1678701600, 1678788000, 1678874400, 1678960800, 1679047200, 1679133600, 1679220000, 1679306400, 1679392800, 1679479200, 1679565600, 1679652000, 1679738400, 1679824800, 1679911200, 1679997600, 1680084000, 1680170400, 1680256800) AND lat BETWEEN 36.0 AND 42.0 AND lon BETWEEN -10.0 AND -5.0 AND heading BETWEEN 160 AND 220 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'RYR%' OR callsign LIKE 'TAP%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 155 AND 225 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C4_mar2023.csv

# C4 June 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1685613600, 1685700000, 1685786400, 1685872800, 1685959200, 1686045600, 1686132000, 1686218400, 1686304800, 1686391200, 1686477600, 1686564000, 1686650400, 1686736800, 1686823200, 1686909600, 1686996000, 1687082400, 1687168800, 1687255200, 1687341600, 1687428000, 1687514400, 1687600800, 1687687200, 1687773600, 1687860000, 1687946400, 1688032800, 1688119200) AND lat BETWEEN 36.0 AND 42.0 AND lon BETWEEN -10.0 AND -5.0 AND heading BETWEEN 160 AND 220 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'RYR%' OR callsign LIKE 'TAP%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 155 AND 225 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C4_jun2023.csv

# C4 November 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1698832800, 1698919200, 1699005600, 1699092000, 1699178400, 1699264800, 1699351200, 1699437600, 1699524000, 1699610400, 1699696800, 1699783200, 1699869600, 1699956000, 1700042400, 1700128800, 1700215200, 1700301600, 1700388000, 1700474400, 1700560800, 1700647200, 1700733600, 1700820000, 1700906400, 1700992800, 1701079200, 1701165600, 1701252000, 1701338400) AND lat BETWEEN 36.0 AND 42.0 AND lon BETWEEN -10.0 AND -5.0 AND heading BETWEEN 160 AND 220 AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'VLG%' OR callsign LIKE 'IBE%' OR callsign LIKE 'IBS%' OR callsign LIKE 'RYR%' OR callsign LIKE 'TAP%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND AVG(heading) BETWEEN 155 AND 225 ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C4_nov2023.csv

# =============================================================================
# C5 — Scandinavia Northbound
# =============================================================================

# C5 January 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1672567200, 1672653600, 1672740000, 1672826400, 1672912800, 1672999200, 1673085600, 1673172000, 1673258400, 1673344800, 1673431200, 1673517600, 1673604000, 1673690400, 1673776800, 1673863200, 1673949600, 1674036000, 1674122400, 1674208800, 1674295200, 1674381600, 1674468000, 1674554400, 1674640800, 1674727200, 1674813600, 1674900000, 1674986400, 1675072800, 1675159200) AND lat BETWEEN 55.0 AND 60.0 AND lon BETWEEN 10.0 AND 20.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'NOZ%' OR callsign LIKE 'SAS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'RYR%' OR callsign LIKE 'WZZ%' OR callsign LIKE 'FIN%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C5_jan2023.csv

# C5 March 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1677664800, 1677751200, 1677837600, 1677924000, 1678010400, 1678096800, 1678183200, 1678269600, 1678356000, 1678442400, 1678528800, 1678615200, 1678701600, 1678788000, 1678874400, 1678960800, 1679047200, 1679133600, 1679220000, 1679306400, 1679392800, 1679479200, 1679565600, 1679652000, 1679738400, 1679824800, 1679911200, 1679997600, 1680084000, 1680170400, 1680256800) AND lat BETWEEN 55.0 AND 60.0 AND lon BETWEEN 10.0 AND 20.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'NOZ%' OR callsign LIKE 'SAS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'RYR%' OR callsign LIKE 'WZZ%' OR callsign LIKE 'FIN%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C5_mar2023.csv

# C5 June 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1685613600, 1685700000, 1685786400, 1685872800, 1685959200, 1686045600, 1686132000, 1686218400, 1686304800, 1686391200, 1686477600, 1686564000, 1686650400, 1686736800, 1686823200, 1686909600, 1686996000, 1687082400, 1687168800, 1687255200, 1687341600, 1687428000, 1687514400, 1687600800, 1687687200, 1687773600, 1687860000, 1687946400, 1688032800, 1688119200) AND lat BETWEEN 55.0 AND 60.0 AND lon BETWEEN 10.0 AND 20.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'NOZ%' OR callsign LIKE 'SAS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'RYR%' OR callsign LIKE 'WZZ%' OR callsign LIKE 'FIN%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C5_jun2023.csv

# C5 November 2023
java -jar trino-cli.jar --server https://trino.opensky-network.org --user YOUR_USERNAME --external-authentication --catalog minio --schema osky --output-format CSV_HEADER --execute "SELECT DATE(FROM_UNIXTIME(time)) AS flight_date, icao24, callsign, SUBSTR(callsign, 1, 3) AS airline_prefix, ROUND(AVG(velocity) * 1.94384, 1) AS groundspeed_kts, ROUND(AVG(baroaltitude) / 0.3048, 0) AS altitude_ft, ROUND(AVG(heading), 1) AS track_deg, ROUND(AVG(lat), 3) AS avg_lat, ROUND(AVG(lon), 3) AS avg_lon, COUNT(*) AS ping_count FROM state_vectors_data4 WHERE hour IN (1698832800, 1698919200, 1699005600, 1699092000, 1699178400, 1699264800, 1699351200, 1699437600, 1699524000, 1699610400, 1699696800, 1699783200, 1699869600, 1699956000, 1700042400, 1700128800, 1700215200, 1700301600, 1700388000, 1700474400, 1700560800, 1700647200, 1700733600, 1700820000, 1700906400, 1700992800, 1701079200, 1701165600, 1701252000, 1701338400) AND lat BETWEEN 55.0 AND 60.0 AND lon BETWEEN 10.0 AND 20.0 AND (heading >= 330 OR heading <= 30) AND onground = false AND baroaltitude BETWEEN 9754 AND 12192 AND ABS(vertrate) < 1.5 AND (callsign LIKE 'DLH%' OR callsign LIKE 'NOZ%' OR callsign LIKE 'SAS%' OR callsign LIKE 'EWG%' OR callsign LIKE 'RYR%' OR callsign LIKE 'WZZ%' OR callsign LIKE 'FIN%' OR callsign LIKE 'EZY%') GROUP BY DATE(FROM_UNIXTIME(time)), icao24, callsign HAVING COUNT(*) >= 20 AND (AVG(heading) >= 330 OR AVG(heading) <= 30) ORDER BY flight_date, groundspeed_kts DESC" > OUTPUT_PATH/C5_nov2023.csv

# =============================================================================
# CONVERT TO UTF-8 (Windows PowerShell)
# =============================================================================
$files = @("C1_jan2023","C1_mar2023","C1_jun2023","C1_nov2023",
           "C2_jan2023","C2_mar2023","C2_jun2023","C2_nov2023",
           "C3_mar2023",
           "C4_jan2023","C4_mar2023","C4_jun2023","C4_nov2023",
           "C5_jan2023","C5_mar2023","C5_jun2023","C5_nov2023")

foreach ($f in $files) {
    Get-Content "OUTPUT_PATH\$f.csv" -Encoding Unicode |
    Set-Content "OUTPUT_PATH\${f}_utf8.csv" -Encoding UTF8
    $count = (Get-Content "OUTPUT_PATH\${f}_utf8.csv").Count - 1
    Write-Host "$f : $count flights"
}
