# EaglerMC – no Mac needed (GitHub builds it for you)

1. Make a free account at github.com, create a new repository (Public), e.g. "eaglermc".
2. "Add file > Upload files": drag in everything from this folder (Sources, Resources, parts, project.yml, README.md).
   The game file is split into parts/ because GitHub's website only accepts files under 25 MB.
3. "Add file > Create new file", name it  .github/workflows/build-ipa.yml  and paste the contents of build-ipa.yml
   (the hidden .github folder often does not upload by drag and drop).
4. Open the Actions tab > "Build IPA" > Run workflow. After a few minutes download the artifact "EaglerMC-ipa"
   (a zip that contains EaglerMC.ipa). If the build fails, open the failed step and send me the red error text.
5. The IPA is unsigned. Install it with Sideloadly or AltStore (needs a Windows PC or Mac, plus your Apple ID).
   Free Apple ID installs expire after 7 days.

What the app does: locks the pointer and reads raw mouse movement like Minecraft does, so turning never stops at a
screen edge; own arrow cursor in menus; O = Escape; gear panel (F8 / Alt+E).
Tuning: Mouse sensitivity in the gear panel. If vertical is inverted set mouseYIsUp = false in
Sources/GameViewController.swift.
