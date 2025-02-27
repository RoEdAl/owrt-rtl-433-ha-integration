#
# process MQTT messages
#

inputs | if has("topic") then
  if has("payload") then
    (.payload | type) as $pt |
    (if ["object", "array"] | index($pt) then .payload | tostring else .payload end) as $p |
    if has("retain") and .retain then
      @sh "mosquitto_pub \($pubopts) \($auth) -r -t \(.topic) -m \($p)"
    else
      @sh "mosquitto_pub \($pubopts) \($auth) -t \(.topic) -m \($p)"
    end
  else
    if has("retain") and .retain then
      @sh "mosquitto_pub \($pubopts) \($auth) -t \(.topic) -n -r"
    else
      @sh "mosquitto_pub \($pubopts) \($auth) -t \(.topic) -n"
    end
  end
else
  "No topic in \(.)" | debug | empty
end

#inputs | if has("topic") then
#    [
#      @sh .topic,
#      if has("payload") then .payload | tostring else "" end,
#      if .retain // false then "-r" else "" end
#    ]
#else
#    "No topic in \(.)" | debug | empty
#end | join("\t")
