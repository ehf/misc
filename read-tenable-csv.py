#!/usr/bin/env python3

import csv
import sys
import re
import argparse

## python3 read-tenable-csv.py -f ./Scan-2024-01-27.csv  | grep -v -f master.1.txt


def parse_arguments():
    parser = argparse.ArgumentParser(description="Read CSV file.")
    parser.add_argument(
        "-f",
        "--file",
        action="store",
        dest="file",
        help="Path to CSV file",
        required=True,
    )
    parser.add_argument(
        "-cc",
        "--check-credentialed",
        action="store_true",
        dest="creds_check",
        help="Credentialed check",
        required=False,
    )
    parser.add_argument(
        "--mysql",
        action="store_true",
        dest="mysql_creds_check",
        help="MySQL credentialed check",
        required=False,
    )
    parser.add_argument(
        "--postgres",
        action="store_true",
        dest="postgres_creds_check",
        help="PostgreSQL credentialed check",
        required=False,
    )
    return parser.parse_args()


def read_csv_print_fields(
    csv_file,
    creds_plugin,
    check_creds=False,
    mysql_creds_check=False,
    postgres_creds_check=False,
):
    csv.field_size_limit(sys.maxsize)  # increase field size limit

    if mysql_creds_check:
        creds_plugin = "91823"

    if postgres_creds_check:
        creds_plugin = "91826"

    with open(csv_file, newline='') as csvfile:
        csv_reader = csv.DictReader(csvfile)
        for row in csv_reader:
            if check_creds:
                if row['Plugin'] == creds_plugin:
                    print_row_fields(row, check_creds, creds_plugin)
            else:
                if row['Severity'] != "Info":
                    print_row_fields(row, check_creds, creds_plugin)


def print_row_fields(row, check_creds, creds_plugin):
    fields_to_print = ['Plugin', 'Plugin Name', 'Severity', 'IP Address']
    if check_creds:
        fields_to_print.append('Plugin Output')

    row_output= []
    for field in fields_to_print:
        value = row[field]
        if field == 'Plugin Output' and creds_plugin == "19506":
            value = check_credentialed_check(row, field)
        row_output.append(value)

    print(",".join(row_output))


def check_credentialed_check(row, field):
    plugin_output = row[field]
    match = re.search(r'Credentialed checks : (yes|no)', plugin_output)
    if match:
        return match.group()


def main():
    args = parse_arguments()
    csv_file = args.file
    creds_plugin = "19506"
    check_creds = args.creds_check
    check_mysql_creds = args.mysql_creds_check
    check_postgres_creds = args.postgres_creds_check
    read_csv_print_fields(
        csv_file, creds_plugin, check_creds, check_mysql_creds, check_postgres_creds
    )


if __name__ == "__main__":
    main()



##--DONE
