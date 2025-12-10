# KDE Plasma Gemini Widget

A KDE Plasma desktop widget (Plasmoid) that allows you to interact with Google Gemini AI or a local Ollama instance directly from your desktop.

## Features

*   **Multiple AI Backends:** Choose between Google Gemini or a local Ollama instance.
*   **Direct Interaction:** Chat with AI directly from your desktop panel or desktop.
*   **Dynamic Model Selection:** Automatically fetch and select available models from your chosen backend.
*   **Markdown Support:** Rich text rendering for code blocks, bullet points, and bold text.
*   **Chat History:** Persistent chat history with session management (new chat, load previous chats).
*   **Export:** Export your chat conversations to Markdown files.
*   **Copy to Clipboard:** Right-click any message to copy its content.
*   **Configurable:** Set your API key (Gemini) or server URL (Ollama) and choose your preferred model.

## Screenshots

|                  Chat Interface                   |                 Chat History                  |                  Configuration                  |
| :-----------------------------------------------: | :-------------------------------------------: | :---------------------------------------------: |
| ![Chat Interface](screenshots/chat_interface.png) | ![Chat History](screenshots/chat_history.png) | ![Configuration](screenshots/configuration.png) |

## Installation

### Prerequisites

*   KDE Plasma 5 or 6
*   `kpackagetool5` (Plasma 5) or `kpackagetool6` (Plasma 6)
*   For Ollama: A running [Ollama](https://ollama.ai) instance

### Install

1.  Clone this repository:
    ```bash
    git clone https://github.com/mdigiacomi/kde-plasma-gemini-widget.git
    cd kde-plasma-gemini-widget
    ```

2.  Install using `kpackagetool`:
    
    **For Plasma 6:**
    ```bash
    kpackagetool6 --type Plasma/Applet --install .
    ```

    **For Plasma 5:**
    ```bash
    kpackagetool5 --type Plasma/Applet --install .
    ```

3.  **Update**: If you are updating an existing version, use `--upgrade` instead of `--install`.

### Optional: Install Icon
To use the included custom icon:
```bash
mkdir -p ~/.local/share/icons/hicolor/128x128/apps/
cp google-gemini.png ~/.local/share/icons/hicolor/128x128/apps/google-gemini.png
gtk-update-icon-cache ~/.local/share/icons/hicolor/
```

## Configuration

1.  **Add Widget**: Right-click on your desktop or panel -> "Add Widgets..." -> Search for "Gemini Desktop".
2.  **Configure**:
    *   Right-click the widget.
    *   Select "Configure Gemini Desktop...".

### For Google Gemini
1.  **Get an API Key**: Visit [Google AI Studio](https://aistudio.google.com/app/apikey) to generate a free API key.
2.  Select "Gemini" as the backend.
3.  Paste your API Key.
4.  (Optional) Click "Refresh" to fetch available models, or manually enter a model name.

### For Ollama
1.  Ensure Ollama is running locally (default: `http://localhost:11434`).
2.  Select "Ollama" as the backend.
3.  Enter your Ollama server URL if different from the default.
4.  Click "Refresh" to fetch available models, or manually enter a model name (e.g., `llama3`, `gemma3:latest`).

## License

GPL v2+

