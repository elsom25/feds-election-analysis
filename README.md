feds-election-analysis
======================

Consumes multiple `csv` files to build a voters list, and multiple `txt` files of results data.

General usage:

	./analyse_election -v my_data_1.csv,my_data_2.csv -r results.txt

This outputs a single file `__election_data.csv` of crunched results that may be consumed as needed.

The plan is to eventually also output an analysed dataset.
