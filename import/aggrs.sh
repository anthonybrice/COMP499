http PUT 127.0.0.1:8080/api/music/songs aggrs:='[
{ "type": "pipeline"
, "uri": "group2"
, "stages": [ { "_$match": { "_$var": "matchQuery" } }
            , { "_$project": { "_$var": "key" } }
            , { "_$group": { "_id": { "_$var": "groupBy" } } }
            , { "_$unwind": "$_id" }
            ]
}
,
{ "type": "pipeline"
, "uri": "group"
, "stages": [ { "_$project": { "_$var": "key" } }
            ]
}
,
{ "type": "mapReduce"
, "uri": "getKeys"
, "map": "function () { for (var key in this) { if (key !== \"_id\" && key !== \"picture\") emit(key, null) } }"
, "reduce": "function (key, stuff) { return null }"
, "query": { "_$var": "query" }
}
]'
