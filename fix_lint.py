import os
import re

lib_path = r'e:\University\9th semester\map\cseclubhub\lib'

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    orig_content = content

    # 1. withOpacity -> withValues(alpha: ...)
    content = content.replace('.withOpacity(', '.withValues(alpha: ')

    # 2. value -> initialValue in DropdownButtonFormField (create_thread_screen.dart)
    if 'create_thread_screen.dart' in path:
        content = content.replace('value: _selectedCategoryId,', 'initialValue: _selectedCategoryId,')

    # 3. activeColor -> activeThumbColor in Switches
    if 'edit_event_screen.dart' in path or 'create_post_screen.dart' in path:
        content = content.replace('activeColor:', 'activeThumbColor:')

    # 4. unnecessary underscores
    content = content.replace('(_, __) =>', '(_, _) =>')

    # 5. strict top level inference in home_screen.dart
    if 'home_screen.dart' in path:
        content = content.replace('Widget _buildPinnedPost(notice)', 'Widget _buildPinnedPost(dynamic notice)')

    # 6. Unused import: '../../../models/forum.dart' in create_thread_screen.dart
    if 'create_thread_screen.dart' in path:
        content = re.sub(r"import\s+'\.\.\/\.\.\/\.\.\/models\/forum\.dart';\n", '', content)

    # 7. Unused import: 'package:go_router/go_router.dart' in notifications_screen.dart
    if 'notifications_screen.dart' in path:
        content = re.sub(r"import\s+'package:go_router\/go_router\.dart';\n", '', content)
        
    # 8. Unnecessary import: 'dart:ui' in events_list_screen.dart
    if 'events_list_screen.dart' in path:
        content = re.sub(r"import\s+'dart:ui';\n", '', content)

    # 9. Unused import: '../../../models/user_profile.dart' in edit_profile_screen.dart
    if 'edit_profile_screen.dart' in path:
        content = re.sub(r"import\s+'\.\.\/\.\.\/\.\.\/models\/user_profile\.dart';\n", '', content)

    # 10. Unused import: 'package:go_router/go_router.dart' in profile_screen.dart
    if 'profile_screen.dart' in path:
        content = re.sub(r"import\s+'package:go_router\/go_router\.dart';\n", '', content)

    # 11. Unused import in search_screen.dart
    if 'search_screen.dart' in path:
        content = re.sub(r"import\s+'package:go_router\/go_router\.dart';\n", '', content)

    # 12. Unused field `_selectedBatch` in members_screen.dart
    if 'members_screen.dart' in path:
        content = re.sub(r"String\?\s+_selectedBatch;\n", '', content)

    if content != orig_content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Lint fix script completed.")
