def paginate(queryset, page=1, limit=20):
    offset = (page-1)*limit
    return queryset.offset(offset).limit(limit)
