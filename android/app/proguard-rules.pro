# MITIGACIÓN M9: Reverse Engineering
# Reglas de ProGuard para ofuscar el código

# Mantener clases necesarias para Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Mantener clases de la aplicación
-keep class com.secure.owaspnote.** { *; }

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Ofuscar nombres de clases y métodos
-repackageclasses ''
-allowaccessmodification

# Optimizaciones adicionales
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Remover logs en release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Mantener excepciones para debugging
-keepattributes SourceFile,LineNumberTable

# Reglas para librerías específicas
-keep class com.google.crypto.** { *; }
-keep class androidx.security.crypto.** { *; }