# Regras do R8 para o build de release.
# Flutter e plugins já trazem as próprias regras; aqui só o que o R8 reclama.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.plugins.** { *; }
