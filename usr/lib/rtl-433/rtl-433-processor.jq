#
# process input from rtl_433
#

def is_kinetic_button($m): [
		"doorbell-primary",
		"doorbell-secondary"
	] | index($m);

def is_basic_light_switch($m): ["lightswitch-basic"] | index($m);

def is_on_off($b): [ "ON", "OFF" ] | index($b);
def is_valid_button($b): ["A", "B", "C", "D", "E"] | index($b);

inputs 
	| split("\t") as [$topic,$payload]
	| ($topic | split("/") | last) as $rtlsn
	| $payload | fromjson
	| if has("model") and has("button") and has("action") and is_valid_button(.button) and is_on_off(.action) then
		  {snr: .snr, noise: .noise, freq: .freq} as $a
		| {topic: "remote/\(.model)/\(.button)/state", payload: .action}
		, {topic: "remote/\(.model)/\(.button)/attributes", payload: $a}
	  elif has("model") and has("id") and has("temperature_C") and has("freq") then
  	          {snr: .snr, noise: .noise, freq: .freq} as $a
		| {retain: true, topic:"sensor/\(.model)/\(.id)/temperature", payload: .temperature_C}
		, {topic: "sensor/\(.model)/\(.id)/attributes", payload: $a}
	  elif has("model") and has("id") and has("temperature_C") and has("freq1") then
                  {snr: .snr, noise: .noise, freq: [.freq1, .freq2]} as $a
                | {retain: true, topic: "sensor/\(.model)/\(.id)/temperature", payload: .temperature_C}
                , if has("humidity") then
                    {retain: true, topic: "sensor/\(.model)/\(.id)/humidity", payload: .humidity}
                  else empty end
		, {topic: "sensor/\(.model)/\(.id)/attributes", payload: $a}
	  elif has("model") and is_kinetic_button(.model) then
		  {snr: .snr, noise: .noise, freq: .freq} as $a
		| {topic: "kinetic/\(.model)/state", payload: "ON"}
                , {topic: "kinetic/\(.model)/attributes", payload: $a}
	  elif has("model") and is_basic_light_switch(.model) then
		  {event_type: "on", rtl_sn: env.RTLSN, snr: .snr, noise: .noise, freq: .freq} as $s
		| {topic: "kinetic/\(.model)/state", payload: $s}
	  elif has("stats") then
	        {topic: "stats/\($rtlsn)", payload: .}
	  else
                {topic: "unknown/\($rtlsn)", payload: .}
          end
	, if has("noise") then {topic: "status/noise/\($rtlsn)", payload: .noise} else empty end
        , if has("time") then {topic: "status/timestamp/\($rtlsn)", payload: .time} else empty end

	| .topic = "rtl_433/ha/" + .topic
	| if (.payload | type) == "object" then .payload.rtl_sn=$rtlsn else . end
