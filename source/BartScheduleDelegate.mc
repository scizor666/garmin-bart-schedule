using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Math as Math;
using Toybox.Position as Position;

class BartScheduleDelegate extends Ui.BehaviorDelegate {

    const BART_API_BASE_URL = "https://api.bart.gov/api";
    const BART_API_DEFAULT_PARAMS = "key=MW9S-E7SL-26DU-VV8V&json=y";
    const BART_API_DEFAULT_OPTIONS = { :method => Comm.HTTP_REQUEST_METHOD_GET,
                                       :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON };

    const DISTANATION_NAME_LENGTH = 19;

    var notify;
    var stations;

    function initialize(handler) {
        Ui.BehaviorDelegate.initialize();
        notify = handler;
        stations = Ui.loadResource(Rez.JsonData.stations);
        updateAll();
    }

    function onMenu() {
        return false;
    }

    function onSelect() {
        updateAll();
        return true;
    }

    function updateAll() {
        notify.invoke("BART destinations\nare loading...");
        var position = Position.getInfo().position.toDegrees();
        recieveStationDestinations(closestStation(position));
    }

    function closestStation(position) {
        var closestStation = stations[0]["abbr"];
        var closestDistance = calculateDistance(position, [stations[0]["gtfs_latitude"], stations[0]["gtfs_longitude"]]);
        for (var i = 1; i < stations.size(); i++) {
            var currentDistance = calculateDistance(position, [stations[i]["gtfs_latitude"], stations[i]["gtfs_longitude"]]);
            if (currentDistance < closestDistance) {
                closestStation = stations[i]["abbr"];
                closestDistance = currentDistance;
            }
        }
        return closestStation;
    }

    function calculateDistance(from, to) {
        return Math.sqrt(Math.pow(to[0] - from[0], 2) + Math.pow(to[1] - from[1], 2));
    }

    function recieveStationDestinations(station) {
        Comm.makeWebRequest(
            Lang.format("$1$/etd.aspx?cmd=etd&orig=$2$&$3$", [BART_API_BASE_URL, station, BART_API_DEFAULT_PARAMS]),
            {},
            BART_API_DEFAULT_OPTIONS,
            method(:onReceiveStationSchedule)
        );
    }

    function onReceiveStationSchedule(responseCode, data) {
        switch (responseCode) {
            case 200: {
                updateDestinations(data["root"]["station"][0]);
                break;
            }
            case -300: {
                notify.invoke("Network\nNot Available.\nTry Again");
                break;
            }
            case -2: {
                notify.invoke("Check Bluetooth\nConnection");
                break;
            }
            case -104: {
                notify.invoke("App Connection\nRequired");
                break;
            }
            default: {
                notify.invoke("Failed to Load\nError: " + responseCode.toString());
                break;
            }
        }
    }

    function updateDestinations(stationData) {
        try {
            var destinations = stationData["etd"];
            var message = shortenName(stationData["name"]) + "\n";

            if ( destinations != null && destinations.size() > 0) {
                for (var i = 0; i < destinations.size(); i++) {
                    var destination = destinations[i];
                    var minutes = destination["estimate"][0]["minutes"];
                    message += Lang.format("$1$: $2$\n", [shortenName(destination["destination"]), minutes]);
                }
            } else {
                message += "No Destinations\nAvailable!";
            }
            notify.invoke(message);
        } catch (ex) {
            notify.invoke("Server Error.\nTry Later");
        }
    }

    function shortenName(name) {
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