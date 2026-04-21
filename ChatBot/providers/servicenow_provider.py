import requests
from providers.base import DataProvider


class ServiceNowProvider(DataProvider):
    def __init__(self):
        self.instance = "https://your-instance.service-now.com"
        self.auth = ("username", "password")

    def get_incidents(self, filters):
        query = []

        if 'priority' in filters:
            query.append(f"priority={filters['priority']}")

        if 'status' in filters:
            query.append(f"state={filters['status']}")

        if 'assigned_to' in filters:
            query.append(f"assigned_to={filters['assigned_to']}")

        query_str = "^".join(query) if query else ""

        url = f"{self.instance}/api/now/table/incident"
        params = {
            "sysparm_query": query_str,
            "sysparm_limit": 10
        }

        response = requests.get(url, auth=self.auth, params=params)
        response.raise_for_status()

        return response.json().get("result", [])

    def get_incident_count(self, filters):
        return len(self.get_incidents(filters))