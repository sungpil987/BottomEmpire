extends SceneTree

func _initialize() -> void:
	var settings := EditorInterface.get_editor_settings()
	var sdk := OS.get_environment("ANDROID_HOME")
	if sdk.is_empty():
		sdk = OS.get_environment("ANDROID_SDK_ROOT")
	print("ANDROID SDK: ", sdk)
	settings.set_setting("export/android/android_sdk_path", sdk)
	settings.set_setting("export/android/debug_keystore", ProjectSettings.globalize_path("res://debug.keystore"))
	settings.set_setting("export/android/debug_keystore_user", "androiddebugkey")
	settings.set_setting("export/android/debug_keystore_pass", "android")
	settings.save()
	quit()
