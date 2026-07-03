import subprocess

try:
    result = subprocess.run(["dart", "analyze"], capture_output=True, text=True, cwd=r"e:\University\9th semester\map\cseclubhub")
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
except Exception as e:
    print("Exception:", e)
