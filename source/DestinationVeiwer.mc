using Toybox.Timer;

class DestinationViewer {

    const LIMIT = 3;
    const DISTANATION_NAME_LENGTH = 19;

    hidden var prependText;
    hidden var destinations;
    hidden var destinationsSlice;
    hidden var viewer;
    hidden var offset = 0;
    hidden var timer = new Timer.Timer();

    function initialize(stationData, viewer) {
        self.prependText = shortenName(stationData["name"]) + "\n";
        self.destinations = stationData["etd"];
        self.viewer = viewer;
    }

    function view() {
        if ( destinations != null && destinations.size() > 0) {
            if (destinations.size() < 4) {
               viewer.invoke(prependText + destinationsAsString(destinations));
            } else {
               viewSlice();
            }
        } else {
            viewer.invoke(prependText + "No Destinations\nAvailable!");
        }
    }

    function viewSlice() {
        destinationsSlice = destinations.slice(offset, offset + LIMIT);
        offset = offset + LIMIT < destinations.size() ? offset + 1 : 0;
        viewer.invoke(prependText + destinationsAsString(destinationsSlice));
        timer.start(method(:viewSlice), 2000, false);
    }

    hidden function destinationsAsString(destinations) {
        var asString = "";
        for (var i = 0; i < destinations.size(); i++) {
            var destination = destinations[i];
            var minutes = toDigitalMinutes(destination["estimate"][0]["minutes"]);
            asString += Lang.format("$1$: $2$\n", [shortenName(destination["destination"]), minutes]);
        }
        return asString;
    }

    hidden function toDigitalMinutes(minutes) {
        return minutes.equals("Leaving") ? 0 : minutes;
    }


    hidden function shortenName(name) {
        if (name.length() <= DISTANATION_NAME_LENGTH ) {
            return name;
        }

        var slashIndex = name.find("/");
        if ( slashIndex != null) {
           return name.substring(0, slashIndex);
        }

        return name.substring(0, DISTANATION_NAME_LENGTH - 3) + "...";
    }
}