
class AppWindowDto{
  final String appName;
  final String windowTitle;

  AppWindowDto({required this.appName, required this.windowTitle});

  @override
  String toString() {
    return 'Window title: $windowTitle. AppName $appName';
  }
}