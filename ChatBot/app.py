import json
from providers.excel_provider import ExcelProvider
from services.incident_service import IncidentService
from ai.query_parser import parse_query
from collections import defaultdict


def load_config():
    try:
        with open("config.json", "r") as f:
            return json.load(f)
    except Exception as e:
        print("Error loading config.json:", e)
        exit()


def main():
    config = load_config()
    file_path = config.get("excel_path")

    if not file_path:
        print("Excel path not found in config.json")
        exit()

    print(f"Using Excel file: {file_path}")

    provider = ExcelProvider(file_path)
    service = IncidentService(provider)

    print("\nChatbot started! Type 'exit' to quit.\n")

    while True:
        user_input = input("You: ")

        if user_input.lower() == "exit":
            break

        filters = parse_query(user_input)
        # print("DEBUG:", filters)

        results = service.get_incidents(filters)

        if not results:
            print("Bot: No matching incidents found.\n")
            continue

        grouped = defaultdict(list)
        for inc in results:
            grouped[inc.get("source", "unknown")].append(inc)

        print("Bot:")
        for source, tickets in grouped.items():
            print(f"\n{source.upper()}")
            for inc in tickets:
                print(f"{inc.get('snow_ticket')} - {inc.get('description')}")
        print()


if __name__ == "__main__":
    main()