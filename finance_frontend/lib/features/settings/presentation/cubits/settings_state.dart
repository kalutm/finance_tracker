import 'package:flutter/widgets.dart';

@immutable
abstract class SettingsState{
  const SettingsState();
}



class SettingsStateDark extends SettingsState{
  const SettingsStateDark();
}

class SettingsStateLight extends SettingsState{
  const SettingsStateLight();
}