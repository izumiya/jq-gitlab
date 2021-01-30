# Burndown Chart
#
# curl -s --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com/api/v4/issues?milestone=$MILESTONE&per_page=1000&scope=all" | jq -r -f burndown-chart.jq 
#
{
    "start_date": (.[0]|.milestone.start_date),
    "open_issues": ({
       "open": (
        [ .[] | .created_at[0:19]+"Z"|fromdate|. + 3600 * 9|strftime("%Y-%m-%d") ]
        | group_by(.)
        | reduce .[] as $v({};. + {($v|.[0]): ($v|length) })
        ),
        "close": (
        [ .[] | .closed_at[0:19] | if . == null then null else .+"Z"|fromdate|. + 3600 * 9|strftime("%Y-%m-%d") end | select(. != null)]
        | group_by(.)
        | reduce .[] as $v({};. + {($v|.[0]): (-1*($v|length)) })
        )
    }
    | [ (.open|to_entries), (.close|to_entries) ] | flatten | group_by(.key)
    | reduce .[] as $v([{}, 0]; [ .[0] + { ($v|.[0]|.key): (([$v|.[]|.value]|add) + .[1])}, .[1] + ([$v|.[]|.value]|add) ])
    | .[0]
    )
}
| reduce (.open_issues|to_entries|.[]) as $item([.start_date]; . + (if .[0] > ($item|.key) then null else [$item] end)) | .[1:]
| .[]
| [.key, .value]
| @csv
