def parse_query(user_input: str) -> dict:
    user_input = user_input.lower()
    filters = {}

    # Priority
    if "p1" in user_input or "priority 1" in user_input:
        filters["priority"] = "p1"
    elif "p2" in user_input:
        filters["priority"] = "p2"
    elif "p3" in user_input:
        filters["priority"] = "p3"
    elif "p4" in user_input:
        filters["priority"] = "p4"
    elif "urgent" in user_input:
        filters["priority"] = "urgent"
    elif "routine" in user_input:
        filters["priority"] = "routine"

    # Status
    if "open" in user_input:
        filters["status"] = "open"
    elif "closed" in user_input or "resolved" in user_input:
        filters["status"] = "closed"

    # SLA breached
    if "sla" in user_input and "breach" in user_input:
        filters["sla_breached"] = True

    # 🔥 Dynamic assignee detection (any name in query)
    words = user_input.split()
    for word in words:
        if len(word) > 2:  # avoid noise words
            filters["assigned_to"] = word

    # Source (sheet)
    if "eks" in user_input:
        filters["source"] = "eks"
    elif "argo" in user_input:
        filters["source"] = "argo"
    elif "scm" in user_input:
        filters["source"] = "scm"
    elif "atlas" in user_input or "on-prem" in user_input:
        filters["source"] = "on-prem k8s-atlas"
    elif "database" in user_input:
        filters["source"] = "database"

    return filters