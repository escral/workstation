pragma Singleton
import Quickshell
import QtQuick

// Which Nerd Font glyph stands for an app, and whether it gets a colour. Only
// the apps that own a workspace (editors, AI, browsers, chat; see
// hyprland.lua) do, their brand colour lifted to read on the dark background;
// the rest stay neutral so those stand out.
Singleton {
    // [pattern on desktop id or window class, glyph, brand colour or none]
    readonly property var brands: [
        [/chrom(e|ium)/, "\u{F02AF}", "#f9c74f"],
        [/firefox/, "\u{F0239}", "#ff9466"],
        [/telegram/, "\u{E217}", "#5cc2f2"],
        [/slack/, "\u{F04B1}", "#ee6a8e"],
        [/discord|vesktop/, "\u{F066F}", "#8790f7"],
        [/whatsapp/, "\u{F05A3}", "#5be08f"],
        [/teams/, "\u{F02BB}", "#8b8fe8"],
        [/anthropic|claude/, "\u{F0AE2}", "#e59a7f"],
        [/^cursor$/, "\u{F01C0}", "#c0caf5"],
        [/vscodium|codium/, "\u{F372}", "#64b5f2"],
        [/vscode|^code(-oss)?$/, "\u{F0A1E}", "#64b5f2"],
        [/^dev\.zed|^zed/, "\u{F0169}", "#6fa0ff"],
        [/jetbrains-webstorm/, "\u{E8E4}", "#4fd3f5"],
        [/jetbrains-phpstorm/, "\u{E862}", "#c77af4"],
        [/jetbrains-pycharm/, "\u{E877}", "#5be0a6"],
        [/jetbrains-goland/, "\u{E7EF}", "#5aa6fa"],
        [/jetbrains-rider/, "\u{E88F}", "#f58c63"],
        [/jetbrains-clion/, "\u{E78E}", "#5be0a6"],
        [/jetbrains-datagrip/, "\u{E7BD}", "#9e8cf7"],
        [/jetbrains-idea/, "\u{E7B5}", "#ff6f8e"],
        [/jetbrains-(?!toolbox)/, "\u{E808}", "#c0caf5"],
        [/jetbrains/, "\u{E808}"],
        [/thunderbird/, "\u{F370}"],
        [/nvim|neovim/, "\u{F36F}"],
        [/ghostty/, "\u{F02A0}"],
        [/kitty|terminal|alacritty|foot/, "\u{F018D}"],
        [/btop|htop/, "\u{F04C5}"],
        [/nm-connection/, "\u{F06F3}"],
        [/pavucontrol/, "\u{F057E}"],
        [/blueman/, "\u{F00AF}"],
        [/spotify/, "\u{F04C7}"],
        [/steam/, "\u{F04D3}"],
        [/vlc/, "\u{F057C}"],
        [/mpv/, "\u{F36E}"],
        [/gimp/, "\u{F338}"],
        [/inkscape/, "\u{F33B}"],
        [/krita/, "\u{F33D}"],
        [/figma/, "\u{E7DA}"],
        [/postman/, "\u{E86B}"],
        [/notion/, "\u{E848}"],
        [/libreoffice.*writer/, "\u{F37C}"],
        [/libreoffice.*calc/, "\u{F378}"],
        [/libreoffice.*impress/, "\u{F37A}"],
        [/libreoffice/, "\u{F376}"],
    ]

    // Desktop categories, most specific first: a chat app is also Network.
    readonly property var kinds: [
        ["TerminalEmulator", "\u{F018D}"],
        ["WebBrowser", "\u{F059F}"],
        ["InstantMessaging", "\u{F0B79}"],
        ["Chat", "\u{F0B79}"],
        ["Email", "\u{F01EE}"],
        ["IDE", "\u{F0169}"],
        ["Development", "\u{F0169}"],
        ["Video", "\u{F0567}"],
        ["Audio", "\u{F075A}"],
        ["AudioVideo", "\u{F040C}"],
        ["Graphics", "\u{F03D8}"],
        ["Game", "\u{F0297}"],
        ["Office", "\u{F0219}"],
        ["Archiving", "\u{F003C}"],
        ["Monitor", "\u{F04C5}"],
        ["Settings", "\u{F0493}"],
        ["System", "\u{F0493}"],
        ["Network", "\u{F06F3}"],
        ["Utility", "\u{F1064}"],
    ]

    readonly property string generic: "\u{F08C6}"

    // { glyph, hue } for the first brand matching the id or class, else the
    // first matching category, else the generic app glyph. hue is empty for
    // neutral marks.
    function lookup(id, cls, categories) {
        for (const name of [id, cls].filter(n => n).map(n => n.toLowerCase()))
            for (const [re, glyph, hue] of brands)
                if (re.test(name))
                    return { glyph: glyph, hue: hue ?? "" };
        for (const [kind, glyph] of kinds)
            if ((categories ?? []).includes(kind))
                return { glyph: glyph, hue: "" };
        return { glyph: generic, hue: "" };
    }
}
