# TinyTask icon

`TinyTaskIcon.png` is the maintained transparent master: a flat, outlined blue pointer clicking a bright green button with white click rays, on a soft butter-yellow tile. The supplied artwork had its surrounding white cut away and the tile was scaled to the standard master footprint (1098px on a 1254px canvas).

`swift tools/make_icon.swift` scales the master into all macOS standard/Retina PNG sizes, preserving alpha and normalizing the Dock footprint. `iconutil -c icns AppIcon.iconset -o AppIcon.icns` assembles the shipped resource. `build.sh` repackages when either the master or packaging script changes. In-app branding reads the same bundled ICNS.
