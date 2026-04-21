import pandas as pd
from providers.base import DataProvider


class ExcelProvider(DataProvider):
    def __init__(self, file_path):
        self.sheets = pd.read_excel(file_path, sheet_name=None)

        df_list = []

        for sheet_name, df in self.sheets.items():
            df.columns = [
                col.strip().lower().replace(" ", "_").replace("/", "_")
                for col in df.columns
            ]

            df["source"] = sheet_name.lower()

            df_list.append(df)

        self.df = pd.concat(df_list, ignore_index=True)

    def normalize_priority(self, value):
        if pd.isna(value):
            return ""

        value = str(value).lower()

        # Database sheet format
        if "urgent" in value or "2" in value:
            return "p2"
        elif "routine" in value or "3" in value:
            return "p3"

        # Other sheets
        if "p1" in value:
            return "p1"
        elif "p2" in value:
            return "p2"
        elif "p3" in value:
            return "p3"
        elif "p4" in value:
            return "p4"

        return value

    def get_incidents(self, filters):
        df = self.df.copy()

        # Normalize columns
        for col in ["assignee", "priority", "status", "sla"]:
            if col in df.columns:
                df[col] = df[col].astype(str).str.lower()

        # Normalize priority column
        if "priority" in df.columns:
            df["priority"] = df["priority"].apply(self.normalize_priority)

        #  OPEN / CLOSED
        if filters.get("status") == "open":
            df = df[df["resolution_date"].isna()]
        elif filters.get("status") == "closed":
            df = df[df["resolution_date"].notna()]

        #  Priority filter
        if "priority" in filters and "priority" in df.columns:
            df = df[df["priority"].str.contains(filters["priority"])]

        #  Assignee (FIRST NAME MATCH)
        if "assigned_to" in filters and "assignee" in df.columns:
            df = df[df["assignee"].str.contains(filters["assigned_to"])]

        #  SLA breached
        if filters.get("sla_breached") and "sla" in df.columns:
            df = df[df["sla"].str.contains("breach")]

        #  Source
        if "source" in filters:
            df = df[df["source"].str.contains(filters["source"])]

        return df.to_dict(orient="records")

    def get_incident_count(self, filters):
        return len(self.get_incidents(filters))