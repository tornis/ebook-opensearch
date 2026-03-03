#!/usr/bin/env python3
"""
Script para carregar customer_transactions no OpenSearch
"""
import pandas as pd
import json
import sys
import re

csv_file = sys.argv[1] if len(sys.argv) > 1 else "sample_dataset.csv"
index_name = sys.argv[2] if len(sys.argv) > 2 else "customer_transactions"

try:
    # Ler CSV com pandas usando engine Python para melhor handling de quotes
    df = pd.read_csv(csv_file, encoding='utf-8', engine='python', quoting=1)  # quoting=1 é csv.QUOTE_ALL

    # Emitir NDJSON para bulk import
    for _, row in df.iterrows():
        # Verificar se esta é uma linha mal formada (customer_id contém toda a linha)
        customer_id_str = str(row["Customer ID"]).strip()

        # Se customer_id contém vírgulas e começa com aspas, é uma linha mal formada
        if "," in customer_id_str and '"' in customer_id_str:
            # Tentar parsear manualmente
            try:
                # Remover aspas externas
                clean = customer_id_str.strip('"')
                # Dividir por vírgula respeitando strings entre aspas
                parts = []
                current = ""
                in_quotes = False
                for char in clean:
                    if char == '"':
                        in_quotes = not in_quotes
                    elif char == ',' and not in_quotes:
                        parts.append(current.strip('"').strip())
                        current = ""
                        continue
                    current += char
                parts.append(current.strip('"').strip())

                if len(parts) >= 9:
                    cust_id, name, surname, gender, birthdate, amount, date, merchant, category = parts[:9]
                    try:
                        amount = float(amount)
                    except:
                        amount = 0.0
                else:
                    continue  # Pular esta linha se não conseguir parsear

                doc = {
                    "customer_id": cust_id,
                    "name": name,
                    "surname": surname,
                    "gender": gender,
                    "birthdate": birthdate,
                    "transaction_amount": amount,
                    "date": date,
                    "merchant_name": merchant,
                    "category": category
                }
                print(json.dumps({"index": {"_index": index_name}}))
                print(json.dumps(doc))
            except:
                continue
        else:
            # Linha bem formada
            # Action line
            print(json.dumps({"index": {"_index": index_name}}))

            # Document line - tratar NaN do pandas
            doc = {
                "customer_id": str(row["Customer ID"]),
                "name": str(row["Name"]) if pd.notna(row["Name"]) else "",
                "surname": str(row["Surname"]) if pd.notna(row["Surname"]) else "",
                "gender": str(row["Gender"]) if pd.notna(row["Gender"]) else "",
                "birthdate": str(row["Birthdate"]) if pd.notna(row["Birthdate"]) else "",
                "transaction_amount": float(row["Transaction Amount"]) if pd.notna(row["Transaction Amount"]) else 0.0,
                "date": str(row["Date"]) if pd.notna(row["Date"]) else "",
                "merchant_name": str(row["Merchant Name"]) if pd.notna(row["Merchant Name"]) else "",
                "category": str(row["Category"]) if pd.notna(row["Category"]) else ""
            }
            print(json.dumps(doc))

except Exception as e:
    print(f"Erro: {e}", file=sys.stderr)
    sys.exit(1)
