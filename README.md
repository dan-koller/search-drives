# Search Drives

This is a collection of scripts to search for files on a drive or in a directory. This includes searching for files by name or patterns like `*.txt` or `*.jpg`. The results are saved to a text file including the full path to the file. You can then choose to copy all results to a new directory.

_To access certain directories, you may need admin rights depending on your operating system and the directory you want to search._

## Usage

I recommend to use the Python script, as it is the most flexible and easiest to use. However, if you don't have Python installed, you can use the batch or bash script.

### Python

> Requires Python 3.11 or higher. Check your version with `python --version`.

1. Download the Python script [search.py](search.py)

2. Install the required packages and run the script from the command line

    ```bash
    python -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    python search.py
    ```

    _On macOS and Linux, you may need to use `python3` instead of `python`._

3. Follow the instructions on the screen

### Batch & Bash

1. Download the script for your operating system

    - Windows: [search-win.bat](shell-scripts/search-win.bat)

    - macOS & Linux\*: [search-bash.sh](shell-scripts/search-bash.sh)

2. Run the script from the command line

    - Windows

        ```bat
        search-win.bat
        ```

    - macOS & Linux\*

        _Requires Bash 3.2 or higher. Check your version with `bash --version`._

        ```bash
        chmod +x search-bash.sh
        ./search-bash.sh
        ```

        _\*) The script was tested on macOS, Ubuntu, and WSL on Windows 10. However, there may be differences when using default directories like `C:\Users\` on Windows, `/home/` on Linux, or `/Users/` on macOS. If you encounter any problems, please open an issue on GitHub._

3. Follow the instructions on the screen

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
