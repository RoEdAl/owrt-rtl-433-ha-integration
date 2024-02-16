#
# process MQTT messages
#

inputs | if has("topic") then
    [
      .topic,
      if has("payload") then .payload | tostring else "" end,
      if .retain // false then "-r" else "" end
    ]
else
    "No topic in \(.)" | debug | empty
end | @tsv
