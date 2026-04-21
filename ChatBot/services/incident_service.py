class IncidentService:
    def __init__(self, provider):
        self.provider = provider

    def get_incidents(self, filters):
        return self.provider.get_incidents(filters)

    def get_incident_count(self, filters):
        return self.provider.get_incident_count(filters)