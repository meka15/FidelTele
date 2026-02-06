
import 'package:shared_preferences/shared_preferences.dart';

class IntroPrefs {
	static const _key = 'intro_completed';

	static Future<bool> isIntroCompleted() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getBool(_key) ?? false;
	}

	static Future<void> setIntroCompleted() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(_key, true);
	}
}
