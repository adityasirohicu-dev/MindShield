"""Drop and reseed the demo database."""

from scripts.seed import reset

if __name__ == "__main__":
    reset()
    print("Demo database reset.")
