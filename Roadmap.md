# Todo

**Besides all TODOs mentioned in the source code:***

* Add a user preference option to hide the menubar icon
*   * Make it hidden when not connected
*   * Make preferences accessible when not connected

* Add notification message when 100 MB (set by user, maybe on first
    launch) are transferred

# Done

* Gather data on how much data has been transferred on the interface
    used for tethering

* Design a user interface for showing the data used/transferred per session
    * Show "This session: %d MB" in menuitem
    * When clicking on it, show window "Tethering Sessions"
    * Show a view by year, month or day, with bar charts showing the
        amount of data used

* Implement a prototype Android service
    * Service must only run when hotspot is active

* Make a decision on the name
    * Stay with TetheringHelper
    * Tethering Helper, easier to type with phone because of the space
    * HotspotHelper
    * TetherLoupe

* Create simple first launch screen, maybe just use defaults. Or a
    simple first launch splash that tells the defaults.


