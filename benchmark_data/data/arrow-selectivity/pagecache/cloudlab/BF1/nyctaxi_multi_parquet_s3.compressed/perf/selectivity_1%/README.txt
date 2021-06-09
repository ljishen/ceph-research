[Results in this folder are credited to Ulmer, Craig D <cdulmer@sandia.gov>]


These are the results from running the conbech dataset selectivity benchmark on a bluefield 1 card.

The nyctaxi dataset was maually downloaded from amazon (see below) and stored on an nfs mountpoint
that lives on the host. We ran the test before these tests to warm the cache.

The tests are for reading parquet files at 1% selectivity. The first line of the logs shows the details.

Manually downloading the data (proxy/firewall problems):
- Ran the script, it generated a dirpath for ursa-labs-taxi-data/2009/01 in data
- Manually created the other 3 directories
- Manually downloaded into each dir from amazon:
   wget https://ursa-labs-taxi-data.s3.us-east-2.amazonaws.com/2009/01/data.parquet

