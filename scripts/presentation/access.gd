extends RefCounted
## Accessibility choices the views read while drawing, set from the settings page. Colour-safe swaps the teal/rust
## pair used for held/healthy and threat/hurt for a blue/orange pair that reads under red-green colour blindness;
## reduced motion stills the pulsing rings and the white hit flash and snaps the camera; captions show the sounds that
## carry information (see Captions).
static var colour_safe: bool = false
static var reduce_motion: bool = false
static var captions: bool = false


## Held ground, health and safety.
static func good() -> Color:
	return Color("56b4e9") if colour_safe else Color("9dceb3")


## Threat, damage and danger.
static func threat() -> Color:
	return Color("e69f00") if colour_safe else Color("d88c63")


## The live health bar: `good` above 30 %, `threat` at or below.
static func health(fraction: float) -> Color:
	return good() if fraction > 0.3 else (Color("ffd166") if colour_safe else Color("ffac82"))


## 0..1 for a pulsing ring; held at full when motion is reduced.
static func pulse(msec: int) -> float:
	return 1.0 if reduce_motion else 0.5 + 0.5 * sin(float(msec) / 250.0)


## Reads the three settings from a preferences store.
static func load_from(values: Dictionary) -> void:
	colour_safe = bool(values.get("colour_safe", false))
	reduce_motion = bool(values.get("reduce_motion", false))
	captions = bool(values.get("captions", false))
