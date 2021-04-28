#!/bin/sh

#Number of Blocks By Miner
sudo -u postgres psql data -c "DROP TABLE blockbyminer"
sudo -u postgres psql data -c "CREATE TABLE blockbyminer AS SELECT "public"."blocks"."miner" AS "miner", CAST("public"."blocks"."creationtime" AS date) AS "creationtime", count(*) AS "count" FROM "public"."blocks" GROUP BY "public"."blocks"."miner", CAST("public"."blocks"."creationtime" AS date) ORDER BY "public"."blocks"."miner" ASC, CAST("public"."blocks"."creationtime" AS date) ASC"

#Hashrate
sudo -u postgres psql data -c "DROP TABLE hashrate"
sudo -u postgres psql data -c "CREATE TABLE hashrate AS SELECT CAST("public"."blocks"."creationtime" AS date) AS "creationtime", "public"."blocks"."chainid" AS "chainid", (CAST(avg((CAST(115792089237316195423570985008687907853269984665640564039457584007913129639935 AS float) / CASE WHEN "public"."blocks"."target" = 0 THEN NULL ELSE "public"."blocks"."target" END)) AS float) / CASE WHEN 3.0 = 0 THEN NULL ELSE 3.0 END / CASE WHEN 1.0E9 = 0 THEN NULL ELSE 1.0E9 END) AS "hashrate" FROM "public"."blocks" LEFT JOIN "public"."transactions" "Transactions" ON "public"."blocks"."hash" = "Transactions"."block" GROUP BY CAST("public"."blocks"."creationtime" AS date), "public"."blocks"."chainid" ORDER BY CAST("public"."blocks"."creationtime" AS date) ASC, "public"."blocks"."chainid" ASC"

#Latest Blocks
sudo -u postgres psql data -c "DROP TABLE latestblocks"
sudo -u postgres psql data -c "CREATE TABLE latestblocks AS SELECT "public"."blocks"."creationtime" AS "creationtime", "public"."blocks"."chainid" AS "chainid", "public"."blocks"."height" AS "height" FROM "public"."blocks" LEFT JOIN "public"."transactions" "Transactions" ON "public"."blocks"."hash" = "Transactions"."block" ORDER BY "public"."blocks"."creationtime" DESC LIMIT 2000"

#Block Utilization
sudo -u postgres psql data -c "DROP TABLE blockutilization"
sudo -u postgres psql data -c "CREATE TABLE blockutilization AS SELECT CAST("public"."transactions"."creationtime" AS date) AS "creationtime", "public"."transactions"."chainid" AS "chainid", (CAST(sum("public"."transactions"."gas") AS float) / CASE WHEN 150000.0 = 0 THEN NULL ELSE 150000.0 END) AS "Utilization" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" WHERE "public"."transactions"."creationtime" >= timestamp with time zone '2019-11-16 00:00:00.000-05:00' GROUP BY CAST("public"."transactions"."creationtime" AS date), "public"."transactions"."chainid" ORDER BY CAST("public"."transactions"."creationtime" AS date) ASC, "public"."transactions"."chainid" ASC"

#Tx by Sender
sudo -u postgres psql data -c "DROP TABLE txbysender"
sudo -u postgres psql data -c "CREATE TABLE txbysender AS SELECT "public"."transactions"."sender" AS "sender", CAST("public"."transactions"."creationtime" AS date) AS "creationtime", count(*) AS "count" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" GROUP BY "public"."transactions"."sender", CAST("public"."transactions"."creationtime" AS date) ORDER BY "public"."transactions"."sender" ASC, CAST("public"."transactions"."creationtime" AS date) ASC"

#Tx per Day
sudo -u postgres psql data -c "DROP TABLE txperday"
sudo -u postgres psql data -c "CREATE TABLE txperday AS SELECT "public"."transactions"."chainid" AS "chainid", CAST("public"."transactions"."creationtime" AS date) AS "creationtime", count(*) AS "count" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" WHERE "public"."transactions"."creationtime" >= timestamp with time zone '2019-11-16 00:00:00.000-05:00' GROUP BY "public"."transactions"."chainid", CAST("public"."transactions"."creationtime" AS date) ORDER BY "public"."transactions"."chainid" ASC, CAST("public"."transactions"."creationtime" AS date) ASC"

#Tx by Hour
sudo -u postgres psql data -c "DROP TABLE txbyhour"
sudo -u postgres psql data -c "CREATE TABLE txbyhour AS SELECT CAST(extract(hour from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) AS "creationtime", CAST("Blocks"."creationtime" AS date) AS "creationtime_2", count(*) AS "count" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" GROUP BY CAST(extract(hour from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer), CAST("Blocks"."creationtime" AS date) ORDER BY CAST(extract(hour from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) ASC, CAST("Blocks"."creationtime" AS date) ASC"

#Tx by Day
sudo -u postgres psql data -c "DROP TABLE txbyday"
sudo -u postgres psql data -c "CREATE TABLE txbyday AS SELECT CASE WHEN ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) = 0 THEN 7 ELSE ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) END AS "creationtime", CAST("Blocks"."creationtime" AS date) AS "creationtime_2", count(*) AS "count" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" GROUP BY CASE WHEN ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) = 0 THEN 7 ELSE ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) END, CAST("Blocks"."creationtime" AS date) ORDER BY CASE WHEN ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) = 0 THEN 7 ELSE ((CAST(extract(dow from CAST("public"."transactions"."creationtime" AS timestamp)) AS integer) + 1) % 7) END ASC, CAST("Blocks"."creationtime" AS date) ASC"

#Latest Txs
sudo -u postgres psql data -c "DROP TABLE latesttxs"
sudo -u postgres psql data -c "CREATE TABLE latesttxs AS SELECT "public"."transactions"."creationtime" AS "creationtime", "public"."transactions"."chainid" AS "chainid", "public"."transactions"."code" AS "code", "public"."transactions"."requestkey" AS "requestkey", "Blocks"."height" AS "height" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" WHERE ("public"."transactions"."code" IS NOT NULL AND ("public"."transactions"."code" <> '' OR "public"."transactions"."code" IS NULL)) ORDER BY "public"."transactions"."creationtime" DESC LIMIT 2000"

#KDA Spend in Gas
sudo -u postgres psql data -c "DROP TABLE kdaspent"
sudo -u postgres psql data -c "CREATE TABLE kdaspent AS SELECT "public"."transactions"."sender" AS "sender", CAST("public"."transactions"."creationtime" AS date) AS "creationtime", sum(("public"."transactions"."gas" * "public"."transactions"."gasprice")) AS "sum" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" GROUP BY "public"."transactions"."sender", CAST("public"."transactions"."creationtime" AS date) ORDER BY "public"."transactions"."sender" ASC, CAST("public"."transactions"."creationtime" AS date) ASC"

#Average KDA cost per Tx
sudo -u postgres psql data -c "DROP TABLE kdapertx"
sudo -u postgres psql data -c "CREATE TABLE kdapertx AS SELECT "public"."transactions"."chainid" AS "chainid", CAST("public"."transactions"."creationtime" AS date) AS "creationtime", avg(("public"."transactions"."gas" * "public"."transactions"."gasprice")) AS "avg" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" WHERE "public"."transactions"."creationtime" >= timestamp with time zone '2019-11-16 00:00:00.000-05:00' GROUP BY "public"."transactions"."chainid", CAST("public"."transactions"."creationtime" AS date) ORDER BY "public"."transactions"."chainid" ASC, CAST("public"."transactions"."creationtime" AS date) ASC"

#Average Gas Used
sudo -u postgres psql data -c "DROP TABLE gasused"
sudo -u postgres psql data -c "CREATE TABLE gasused AS SELECT "public"."transactions"."chainid" AS "chainid", CAST("public"."transactions"."creationtime" AS date) AS "creationtime", avg("public"."transactions"."gas") AS "avg" FROM "public"."transactions" LEFT JOIN "public"."blocks" "Blocks" ON "public"."transactions"."block" = "Blocks"."hash" WHERE ("public"."transactions"."creationtime" >= timestamp with time zone '2019-11-16 00:00:00.000-05:00' AND "public"."transactions"."code" IS NOT NULL AND ("public"."transactions"."code" <> '' OR "public"."transactions"."code" IS NULL)) GROUP BY "public"."transactions"."chainid", CAST("public"."transactions"."creationtime" AS date) ORDER BY "public"."transactions"."chainid" ASC, CAST("public"."transactions"."creationtime" AS date) ASC"
