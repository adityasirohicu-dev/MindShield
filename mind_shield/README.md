# MIND SHIELD Flutter app

Flutter client for the MIND SHIELD personnel and welfare-officer prototype.

## Run the app

From this folder, run:

```powershell
flutter pub get
flutter run
```

For the Android emulator, start the local API first from the repository's `backend` folder. The app targets the emulator API at `http://10.0.2.2:8000/v1` by default. Demo credentials and backend setup are in the repository [README](../README.md).

## Change the UI

Start with the [UI Design Guide](DESIGN_GUIDE.md). Palette, gradients, spacing, radii, and type styles are centralized in `lib/theme/`; shared components are in `lib/widgets/`.
