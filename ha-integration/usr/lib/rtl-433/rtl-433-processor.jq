#
# process input from rtl_433
#

def is_kinetic_button($m): ["doorbell-primary","doorbell-secondary", "lightswitch-basic"] | index($m);
def is_motion_detector($m): ["Heckermann PIR Sensor 2"] | index($m);
def is_on_off($b): [ "ON", "OFF" ] | index($b);
def is_valid_button($b): ["A", "B", "C", "D", "E"] | index($b);
def is_generic_remote($m): ["Generic-Remote"] | index($m);

def diag_attrs_obj:
    ["time", "model", "id", "freq", "freq1", "freq2", "noise", "rssi", "snr", "mod", "tristate"] as $a |
    {time: "timestamp", mod: "modulation"} as $m |
    to_entries |
    map(
      .key as $k |
      if $a | index($k) then
        if $m | has($k) then
          {key: $m[$k], value: .value}
        else . end
      else empty end
    ) |
    from_entries |
    if has("freq1") and has("freq2") then
      [ .freq1, .freq2 ] as $f |
      del(.freq1) | del(.freq2 ) |
      .freq = $f
    else . end |
    if has("timestamp") then .timestamp = (.timestamp | tonumber) else . end;
def diag_attrs($t): {topic: "\($t)/attributes", payload: diag_attrs_obj};

def pub_sensor($t;$p;$n):
	if has($p) then {topic: "\($t)/\($n//$p)", payload: .[$p], retain: true} else empty end;
def diag_sensor($t;$p;$n):
	if has($p) then {topic: "\($t)/\($n//$p)", payload: .[$p]} else empty end;
def diag_num_sensor($t;$p;$n):
        if has($p) then {topic: "\($t)/\($n//$p)", payload: .[$p]|tonumber} else empty end;
def diag_sensors($t):
	diag_sensor($t; "model"; null),
	diag_sensor($t; "id"; null),
	diag_sensor($t; "channel"; null),
	diag_num_sensor($t; "time"; "timestamp"),
	diag_sensor($t; "freq"; null),
	diag_sensor($t; "freq1"; null),
	diag_sensor($t; "freq2"; null),
	diag_sensor($t; "noise"; null),
	diag_sensor($t; "snr"; null),
	diag_sensor($t; "rssi"; null),
	diag_sensor($t; "battery_ok"; "battery"),
	diag_sensor($t; "msg_counter"; "msgcnt"),
	diag_sensor($t; "mod"; "modulation"),
	diag_sensor($t; "tristate"; null);

inputs 
	| split("\t") as [$topic,$payload]
	| ($topic | split("/") | last) as $rtlsn
	| $payload | fromjson
	| if has("model") and has("button") and has("action") and is_valid_button(.button) and is_on_off(.action) then
		"remote/\(.model)/\(.button)" as $t |
		{topic: "\($t)/state", payload: .action},
		diag_attrs($t)
	  elif has("model") and is_kinetic_button(.model) then
		"kinetic/\(.model)" as $t |
		{topic: "\($t)/event", payload: diag_attrs_obj}
	  elif has("model") and is_motion_detector(.model) then
		"motion/\(.model)" as $t |
                {topic: "\($t)/state", payload: "on"},
		{topic: "\($t)/event", payload: .time|tonumber},
		diag_attrs($t)
	  elif has("model") and (is_generic_remote(.model) | not) and has("id") then
		(if has("channel") then "sensor/\(.model)/\(.id)/\(.channel)" else "sensor/\(.model)/\(.id)" end) as $t |
		pub_sensor($t; "temperature_C"; "temperature"),
		pub_sensor($t; "humidity"; null),
		pub_sensor($t; "rain_mm"; "rain"),
		diag_sensors($t)
	  elif has("model") and is_generic_remote(.model) and has("id") and has("cmd") then
		"generic-remote/\(.id)" as $t |
		{topic: "\($t)/cmd", payload: .cmd},
		diag_attrs($t)
	  elif has("stats") then
	        {topic: "stats/\($rtlsn)", payload: .}
	  else
                {topic: "unknown/\($rtlsn)", payload: .}
          end
	, if has("noise") then {topic: "status/noise/\($rtlsn)", payload: .noise} else empty end
        , if has("time") then {topic: "status/timestamp/\($rtlsn)", payload: .time|tonumber} else empty end

	| .topic = "rtl_433/ha/" + .topic
	| if (.payload | type) == "object" then .payload.rtl_sn=$rtlsn else . end
