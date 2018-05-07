using Toybox.Timer;

class DestinationViewer {

    const LIMIT = 3;
    const DISTANATION_NAME_LENGTH = 19;

    static var timer = new Timer.Timer();

    hidden var prependText;
    hidden var destinations;
    hidden var viewer;
    hidden var offset = 0;
    hidden var stopView = false;

    function initialize(title, destinations, viewer) {
        self.prependText = shortenName(title) + "\n";
        self.destinations = destinations;
        self.viewer = viewer;
    }

    function view() {
        if ( destinations != null && destinations.size() > 0) {
            if (destinations.size() < 4) {
               viewer.invoke(prependText + destinationsAsString(null, null));
            } else {
               viewSlice();
            }
        } else {
            viewer.invoke(prependText + "No Destinations\nAvailable!");
        }
    }

    function viewSlice() {
        if( stopView) {
            return;
        }
        viewer.invoke(prependText + destinationsAsString(offset, offset + LIMIT));
        offset = offset + LIMIT < destinations.size() ? offset + 1 : 0;
        timer.start(method(:viewSlice), 2000, false);
    }

    function stop() {
        stopView = true;
    }

    hidden function destinationsAsString(offset, limit) {
        var asString = "";
        limit = (limit != null) ? limit : destinations.size();
        offset = (offset != null) ? offset : 0; 
        for (var i = offset; i < limit; i++) {
            var destination = destinations[i];
            var minutes = toDigitalMinutes(destination[:estimate][0][:minutes]);
            asString += Lang.format("$1$: $2$\n", [shortenName(destination[:destination]), minutes]);
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