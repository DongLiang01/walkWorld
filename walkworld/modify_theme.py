import re

file_path = '/Users/dongliang/Desktop/DLLT.git/walkWord/walkworld/lib/app/theme/app_theme_tokens.dart'

with open(file_path, 'r') as f:
    content = f.read()

tokens = [
    'profilePageBackground',
    'profileCardBackground',
    'profileCardBorder',
    'profileTextPrimary',
    'profileTextSecondary',
    'profileAccentBlue',
    'profileAccentOrange',
    'profileAccentPurple',
    'profileIconBgBlue',
    'profileIconBorderBlue',
    'profileIconBgOrange',
    'profileIconBorderOrange',
    'profileIconBgPurple',
    'profileIconBorderPurple',
    'profileIconBgGreen',
    'profileIconBorderGreen',
    'profileProgressStart',
    'profileProgressEnd',
    'profileProgressBg'
]

# 1. Constructor
constructor_insert = "\n".join([f"    required this.{t}," for t in tokens]) + "\n  });"
content = content.replace("  });", constructor_insert, 1)

# 2. Resolve factory
resolve_insert = "\n".join([f"      {t}: AppColorTokens.{t}.resolve(brightness)," for t in tokens]) + "\n    );"
content = content.replace("    );", resolve_insert, 1)

# 3. Fields
fields_insert = "\n".join([f"  /// {t}\n  final Color {t};" for t in tokens]) + "\n\n  @override"
content = content.replace("  @override", fields_insert, 1)

# 4. copyWith parameters
copy_params_insert = "\n".join([f"    Color? {t}," for t in tokens]) + "\n  }) {"
content = content.replace("  }) {", copy_params_insert, 1)

# 5. copyWith body
copy_body_insert = "\n".join([f"      {t}: {t} ?? this.{t}," for t in tokens]) + "\n    );"
content = content.replace("    );", copy_body_insert, 1)

# 6. lerp body
lerp_body_insert = "\n".join([f"      {t}:\n          Color.lerp({t}, other.{t}, t) ??\n          {t}," for t in tokens]) + "\n    );"
content = content.replace("    );", lerp_body_insert, 1)

with open(file_path, 'w') as f:
    f.write(content)

