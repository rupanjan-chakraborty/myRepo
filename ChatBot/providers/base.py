class DataProvider:
    def get_incidents(self, filters):
        raise NotImplementedError

    def get_incident_count(self, filters):
        raise NotImplementedError