import os
import re

lib_dir = "mind_shield/lib"

replacements = {
    # Typography softening
    r"'AI-BASED PREDICTIVE PERSONNEL WELFARE\\nMONITORING SYSTEM'": "'Personal Wellness & Health Analytics'",
    r"'SECURE ACCESS'": "'Welcome Back'",
    r"'Role-based authentication required\.'": "'Please sign in to continue.'",
    r"'ACCESS LEVEL'": "'Account Type'",
    r"'SERVICE ID / CREDENTIAL'": "'Email or Username'",
    r"'ONE-TIME PASSCODE \(OTP\)'": "'Passcode'",
    r"'AUTHENTICATE'": "'Sign In'",
    r"'AUTHENTICATING\.\.\.'": "'Signing In...'",
    r"'PERSONNEL'": "'Member'",
    r"'WELFARE OFFICER'": "'Officer'",
    r"'COUNSELLOR'": "'Counsellor'",
    r"'ORG ADMIN'": "'Admin'",
    r"'E2EE ENCRYPTED · CONFIDENTIAL'": "'Private & Secure'",
    r"'CREDENTIAL AND OTP REQUIRED'": "'Please enter your credentials'",
    r"'This system is for authorized personnel only.*'": "'Your privacy is important to us. All information is securely encrypted.'",
    
    # Structural changes
    r'TacticalButton': 'PrimaryButton',
    r'TacticalCard': 'GlassCard',
    r'TacticalChip': 'StatusChip',
    r'tactical_button\.dart': 'primary_button.dart',
    r'tactical_card\.dart': 'glass_card.dart',
    r'tactical_chip\.dart': 'status_chip.dart',
    r'TacticalButtonVariant': 'PrimaryButtonVariant',

    # Colors
    r'Color\(0xFF1B2A4A\)': 'Color(0xFF334155)', 
    r'Color\(0xFF267C78\)': 'Color(0xFF3B82F6)', 
}

def process_file(path):
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        for pattern, replacement in replacements.items():
            content = re.sub(pattern, replacement, content)
            
        if content != original:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {path}")
    except Exception as e:
        print(f"Error {path}: {e}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            process_file(os.path.join(root, file))

try:
    os.rename(os.path.join(lib_dir, "widgets/tactical_button.dart"), os.path.join(lib_dir, "widgets/primary_button.dart"))
    os.rename(os.path.join(lib_dir, "widgets/tactical_card.dart"), os.path.join(lib_dir, "widgets/glass_card.dart"))
    os.rename(os.path.join(lib_dir, "widgets/tactical_chip.dart"), os.path.join(lib_dir, "widgets/status_chip.dart"))
except Exception as e:
    print(f"Rename error: {e}")
