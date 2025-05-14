# Peeri Setup Instructions

## Setup aria2

To ensure the aria2 daemon works correctly, follow these steps:

1. Make sure the `start_aria2.sh` script is executable:

```bash
chmod +x /path/to/Peeri/Peeri/start_aria2.sh
```

2. Add the script to your Xcode project:
   - Open the Peeri.xcodeproj in Xcode
   - Locate the `start_aria2.sh` file in the Peeri directory
   - Drag it into the Xcode project navigator (into the Peeri group)
   - When prompted, make sure "Copy items if needed" is unchecked
   - Check the "Add to targets" checkbox for the Peeri target
   - Click "Finish"

3. Add a Build Phase to ensure the script is included in the app bundle:
   - In Xcode, select the Peeri project in the navigator
   - Select the Peeri target
   - Go to the "Build Phases" tab
   - Click the "+" button at the top and select "New Run Script Phase"
   - Add the following script:

```bash
# Copy and set executable permissions for start_aria2.sh
cp "${SRCROOT}/Peeri/start_aria2.sh" "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/"
chmod +x "${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources/start_aria2.sh"
```

4. Move the Run Script phase before the "Copy Bundle Resources" phase by dragging it.

## Installing aria2 Daemon

The app will try to install aria2 automatically if it's not found, but you can also install it manually:

```bash
brew install aria2
```

## Configuration

The app will automatically create the required configuration file at `~/.aria2/aria2.conf` if it doesn't exist.

If you want to customize the aria2 settings, you can edit this file manually.