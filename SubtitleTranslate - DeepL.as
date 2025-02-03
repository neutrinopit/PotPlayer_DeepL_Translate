/*
    Real-time subtitle translation for PotPlayer using DeepL API
*/

// Plugin Information Functions
string GetTitle() {
    return "{$CP0=DeepL1 Translate$}";
}

string GetVersion() {
    return "0.0.0.12";
}

string GetDesc() {
    return "Real-time subtitle translation using DeepL API.";
}

string GetLoginTitle() {
    return "{$CP0=DeepL API Key Configuration$}";
}

string GetLoginDesc() {
    return "{$CP0=Please enter your DeepL API Key.$}";
}

string GetUserText() {
    return "{$CP0=DeepL API Key (Current: " + api_key + ")$}";
}

string GetPasswordText() {
    return "{$CP0=API Key:$}";
}

// Global Variables
string api_key = "";
string apiUrl = "https://api-free.deepl.com/v2/translate"; // Default API URL for DeepL Free tier
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";

// Supported Language List
array<string> LangTable =
{
    "", // Auto Detect
    "ar", // Arabic
    "bg", // Bulgarian
    "cs", // Czech
    "da", // Danish
    "de", // German
    "el", // Greek
    "en", // English
    "es", // Spanish
    "et", // Estonian
    "fi", // Finnish
    "fr", // French
    "hu", // Hungarian
    "id", // Indonesian
    "it", // Italian
    "ja", // Japanese
    "ko", // Korean
    "lt", // Lithuanian
    "lv", // Latvian
    "nb", // Norwegian (Bokmål)
    "nl", // Dutch
    "pl", // Polish
    "pt", // Portuguese
    "ro", // Romanian
    "ru", // Russian
    "sk", // Slovak
    "sl", // Slovenian
    "sv", // Swedish
    "tr", // Turkish
    "uk", // Ukrainian
    "zh"  // Chinese
};

// Get Source Language List
array<string> GetSrcLangs() {
    array<string> ret = LangTable;
    return ret;
}

// Get Destination Language List
array<string> GetDstLangs() {
    array<string> ret = LangTable;
    return ret;
}

// Login Interface for entering API Key
string ServerLogin(string User, string Pass) {
    // Trim whitespace
    User = User.Trim();
    Pass = Pass.Trim();

    // Validate API Key
    if (Pass.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter a valid API Key.$}\n");
        return "fail";
    }

    // Save to global variable
    api_key = Pass;

    // Save settings to permanent storage
    HostSaveString("deepl_api_key", api_key);

    HostPrintUTF8("{$CP0=API Key successfully configured.$}\n");
    return "200 ok";
}

// Logout Interface to clear API Key
void ServerLogout() {
    api_key = "";
    HostSaveString("deepl_api_key", "");
    HostPrintUTF8("{$CP0=Successfully logged out.$}\n");
}

// JSON String Escape Function
string JsonEscape(const string &in input) {
    string output = input;
    output.replace("\\", "\\\\");
    output.replace("\"", "\\\"");
    output.replace("\n", "\\n");
    output.replace("\r", "\\r");
    output.replace("\t", "\\t");
    return output;
}

// Global variables for storing previous subtitles
array<string> subtitleHistory;
string UNICODE_RLE = "\u202B"; // For Right-to-Left languages

// Translation Function
string Translate(string Text, string &in SrcLang, string &in DstLang) {
    // Load API key from temporary storage
    api_key = HostLoadString("deepl_api_key", "");

    if (api_key.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter it in the settings menu.$}\n");
        return "";
    }

    if (DstLang.empty() || DstLang == "Auto Detect") {
        HostPrintUTF8("{$CP0=Target language not specified. Please select a target language.$}\n");
        return "";
    }

    if (SrcLang.empty() || SrcLang == "Auto Detect") {
        SrcLang = "";
    }

    // Add the current subtitle to the history
    subtitleHistory.insertLast(Text);

    // Limit the size of subtitleHistory to prevent it from growing indefinitely
    if (subtitleHistory.length() > 1000) {
        subtitleHistory.removeAt(0);
    }

    // Construct the request URL with query parameters
    string requestUrl = apiUrl + "?auth_key=" + api_key + "&text=" + Text + "&target_lang=" + DstLang;
    if (!SrcLang.empty()) {
        requestUrl += "&source_lang=" + SrcLang;
    }

    string headers = "User-Agent: " + UserAgent;

    // Send GET request (using HostUrlGetString)
    string response = HostUrlGetString(requestUrl, UserAgent, headers, "");
    if (response.empty()) {
        HostPrintUTF8("{$CP0=Translation request failed. Please check network connection or API Key.$}\n");
        return "";
    }

    // Parse response
    JsonReader Reader;
    JsonValue Root;
    if (!Reader.parse(response, Root)) {
        HostPrintUTF8("{$CP0=Failed to parse API response.$}\n");
        return "";
    }

    JsonValue translations = Root["translations"];
    if (translations.isArray() && translations[0]["text"].isString()) {
        string translatedText = translations[0]["text"].asString();

        // Handle RTL (Right-to-Left) languages.
        if (DstLang == "ar" || DstLang == "he") {
            translatedText = UNICODE_RLE + translatedText;
        }
        SrcLang = "UTF8";
        DstLang = "UTF8";
        return translatedText.Trim(); // Trim to remove any extra whitespace
    }

    // Handle API errors
    if (Root["message"].isString()) {
        string errorMessage = Root["message"].asString();
        HostPrintUTF8("{$CP0=API Error: $}" + errorMessage + "\n");
    } else {
        HostPrintUTF8("{$CP0=Translation failed. Please check input parameters or API Key configuration.$}\n");
    }

    return "";
}

// Plugin Initialization
void OnInitialize() {
    HostPrintUTF8("{$CP0=DeepL translation plugin loaded.$}\n");
    // Load API Key from temporary storage (if saved)
    api_key = HostLoadString("deepl_api_key", "");
    if (!api_key.empty()) {
        HostPrintUTF8("{$CP0=Saved API Key loaded.$}\n");
    }
}

// Plugin Finalization
void OnFinalize() {
    HostPrintUTF8("{$CP0=DeepL translation plugin unloaded.$}\n");
}
