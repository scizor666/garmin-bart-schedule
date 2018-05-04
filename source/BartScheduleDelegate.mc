using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Math as Math;
using Toybox.Timer;

class BartScheduleDelegate extends Ui.BehaviorDelegate {

    const BART_API_BASE_URL = "https://api.bart.gov/api";
    const BART_API_DEFAULT_PARAMS = "key=MW9S-E7SL-26DU-VV8V&json=y";
    const BART_API_DEFAULT_OPTIONS = { :method => Comm.HTTP_REQUEST_METHOD_GET,
                                       :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON };

    var notify;
    var stations;
    var loading = false;
    var station;

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
        if (!loading) {
        	updateAll();
    	}
        return true;
    }

    function updateAll() {
        loading = true;

        if (station == null) {
        notify.invoke("Waiting for\nGPS...");
            var query = new PositionQuery();
            query.requestPosition(Position.QUALITY_USABLE, null, method(:onPositionDefined));
        } else {
            recieveStationDestinations(station);
        }
    }

    function onPositionDefined(info) {
        var position = info.position.toDegrees();
        station = closestStation(position);
        recieveStationDestinations(station);
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
        notify.invoke("BART destinations\nare loading...");
        Comm.makeWebRequest(
            Lang.format("$1$/etd.aspx?cmd=etd&orig=$2$&$3$", [BART_API_BASE_URL, station, BART_API_DEFAULT_PARAMS]),
            {},
            BART_API_DEFAULT_OPTIONS,
            method(:onReceiveStationSchedule)
        );
    }

    function onReceiveStationSchedule(responseCode, data) {
        loading = false;
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
            var viewer = new DestinationViewer(stationData, notify);
            viewer.view();
        } catch (ex) {
            notify.invoke("Server Error.\nTry Later");
        }
    }
}