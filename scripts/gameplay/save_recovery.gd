class_name SaveRecovery
extends RefCounted
# Redundant checked files, rather than relying on overwrite-rename being atomic on Windows.
var error := ""
var notice := ""
var trusted_path := ""
var trusted_checksum := PackedByteArray()
var timings := {"sha256_ms": 0.0, "validation_ms": 0.0, "decode_ms": 0.0, "io_ms": 0.0}


static func exists(path: String) -> bool:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(path + suffix):
			return true
	return false


static func digest(bytes: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish()


func checked(
	path: String, magic: String, maximum: int, validator: Callable, trust_previous: bool = false
) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var size := file.get_length()
	if size < 40 or size > maximum + 40:
		file.close()
		return {}
	var header := file.get_buffer(8).get_string_from_ascii()
	var checksum := file.get_buffer(32)
	var bytes := file.get_buffer(size - 40)
	file.close()
	if header != magic or bytes.size() != size - 40 or checksum != timed_digest(bytes):
		return {}
	if trust_previous and path == trusted_path and checksum == trusted_checksum:
		return {"cached": true}
	var started := Time.get_ticks_usec()
	var value: Variant = bytes_to_var(bytes)
	timings.decode_ms += (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	var valid: bool = validator.call(value)
	timings.validation_ms += (Time.get_ticks_usec() - started) / 1000.0
	if not valid:
		return {}
	trusted_path = path
	trusted_checksum = checksum
	return {"value": value}


func copy_flushed(source: String, destination: String) -> bool:
	var input := FileAccess.open(source, FileAccess.READ)
	if input == null:
		return false
	var size := input.get_length()
	var bytes := input.get_buffer(size)
	var read_ok := input.get_error() == OK and bytes.size() == size
	input.close()
	if not read_ok:
		return false
	var output := FileAccess.open(destination, FileAccess.WRITE)
	if output == null:
		return false
	output.store_buffer(bytes)
	output.flush()
	var ok := output.get_error() == OK
	output.close()
	return ok


func load_checked(
	path: String, magic: String, maximum: int, validator: Callable, trust_previous: bool = false
) -> Dictionary:
	error = ""
	notice = ""
	if not exists(path):
		return {"missing": true}
	for suffix in ["", ".tmp", ".bak"]:
		var result := checked(path + suffix, magic, maximum, validator, trust_previous and suffix.is_empty())
		if result.is_empty():
			continue
		if not suffix.is_empty():
			# Keep the recovery source intact until the replacement is confirmed.
			if (
				not copy_flushed(path + suffix, path + ".recover")
				or DirAccess.rename_absolute(path + ".recover", path) != OK
			):
				error = "Valid recovery save found, but it could not be restored. Existing files kept."
				return {}
			if suffix == ".tmp":
				DirAccess.remove_absolute(path + suffix)
			trusted_path = path
			notice = "Save recovered from " + suffix + " backup."
		return result
	error = "Save is unreadable or damaged. Existing files kept."
	return {}


func write(path: String, magic: String, bytes: PackedByteArray, maximum: int, validator: Callable) -> bool:
	var started := Time.get_ticks_usec()
	timings = {"sha256_ms": 0.0, "validation_ms": 0.0, "decode_ms": 0.0, "io_ms": 0.0}
	error = ""
	if bytes.size() > maximum:
		error = "Save is too large. Existing files kept."
		return false
	if exists(path):
		var prior := load_checked(path, magic, maximum, validator, true)
		if prior.is_empty():
			return false
		# The main file remains good while replacing the redundant backup.
		if (
			not copy_flushed(path, path + ".bak.stage")
			or DirAccess.rename_absolute(path + ".bak.stage", path + ".bak") != OK
		):
			error = "Could not preserve the previous save. Existing files kept."
			return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "Could not open the save file. Existing files kept."
		return false
	file.store_buffer(magic.to_ascii_buffer())
	var checksum := timed_digest(bytes)
	file.store_buffer(checksum)
	file.store_buffer(bytes)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		error = "Could not replace the save. Recovery files kept."
		return false
	trusted_path = path
	trusted_checksum = checksum
	timings.io_ms = (
		(Time.get_ticks_usec() - started) / 1000.0
		- timings.sha256_ms
		- timings.validation_ms
		- timings.decode_ms
	)
	return true


func timed_digest(bytes: PackedByteArray) -> PackedByteArray:
	var started := Time.get_ticks_usec()
	var checksum := digest(bytes)
	timings.sha256_ms += (Time.get_ticks_usec() - started) / 1000.0
	return checksum
